#!/usr/bin/env -S cargo +nightly -Zscript
---
[dependencies]
serde_json = "1"
rand = "0.8"
hmac = "0.12"
sha2 = "0.10"
hex = "0.4"
nix = { version = "0.29", features = ["poll"] }
---

use std::collections::{HashMap, HashSet};
use std::env;
use std::net::UdpSocket;
use std::os::fd::AsFd;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use hmac::{Hmac, Mac};
use nix::sys::select::{select, FdSet};
use nix::sys::time::TimeVal;
use rand::RngCore;
use serde_json::{json, Value};
use sha2::Sha256;

const BOOTSTRAP: &[&str] = &["148.71.89.128:24254", "159.69.54.127:24254"];
const IP_UDP_HEADER: usize = 28;

type HmacSha256 = Hmac<Sha256>;

fn now_secs() -> i64 {
    SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64
}

fn token_for(secret: &[u8], addr: &str) -> String {
    let mut mac = HmacSha256::new_from_slice(secret).unwrap();
    mac.update(addr.as_bytes());
    hex::encode(&mac.finalize().into_bytes()[..16])
}

fn send(sock: &UdpSocket, addr: &str, msgs: &[Value]) {
    if let Ok(bytes) = serde_json::to_vec(msgs) {
        let _ = sock.send_to(&bytes, addr);
    }
}

// The anti-spoof token rides inside a {"cookie": ...} object. Keep that shape
// in one place so it can never drift between sites again.
fn cookie(tok: &str) -> Value {
    json!({ "cookie": tok })
}
fn cookie_of<'a>(m: &'a Value, key: &str) -> Option<&'a str> {
    m.get(key)?.get("cookie")?.as_str()
}

fn main() {
    let name = env::args().nth(1)
        .or_else(|| env::var("NAME").ok())
        .unwrap_or_else(|| "anon".to_string());

    let mut secret_bytes = [0u8; 32];
    rand::thread_rng().fill_bytes(&mut secret_bytes);
    let secret = secret_bytes;

    let sock = UdpSocket::bind("0.0.0.0:24254").expect("bind failed");

    let mut peers: HashSet<String> = BOOTSTRAP.iter().map(|s| s.to_string()).collect();
    let mut presence: HashMap<String, (i64, String)> = HashMap::new();

    for &b in BOOTSTRAP {
        send(&sock, b, &[
            json!({"PleaseSendPeers": {}}),
            json!({"PleaseAlwaysReturnThisMessage": cookie(&token_for(&secret, b))}),
        ]);
    }

    // Fire both timers immediately on first iteration.
    let mut next_iamhere = Instant::now();
    let mut next_board   = Instant::now();
    let mut buf = [0u8; 65535];

    loop {
        let now_i = Instant::now();

        if now_i >= next_iamhere {
            next_iamhere = now_i + Duration::from_secs(5);
            let t = now_secs();
            for peer in peers.iter().cloned().collect::<Vec<_>>() {
                send(&sock, &peer, &[
                    json!({"IAmHere": {"name": name, "t": t}}),
                    json!({"PleaseAlwaysReturnThisMessage": cookie(&token_for(&secret, &peer))}),
                ]);
            }
        }

        if now_i >= next_board {
            next_board = now_i + Duration::from_secs(10);
            let now = now_secs();
            println!("\n--- Who is here ({name}) ---");
            let mut board: Vec<_> = presence.iter().collect();
            board.sort_by_key(|(n, _)| n.as_str());
            for (n, (t, addr)) in &board {
                println!("  {n}  {addr}  {}s ago", now - t);
            }
        }

        // Sleep until whichever timer fires next (at least 1 ms so we don't spin).
        let now_i = Instant::now();
        let until_iamhere = next_iamhere.checked_duration_since(now_i).unwrap_or(Duration::ZERO);
        let until_board   = next_board.checked_duration_since(now_i).unwrap_or(Duration::ZERO);
        let timeout = until_iamhere.min(until_board).max(Duration::from_millis(1));

        let mut read_fds = FdSet::new();
        read_fds.insert(sock.as_fd());
        let tv = &mut TimeVal::new(
            timeout.as_secs() as i64,
            timeout.subsec_micros() as i64,
        );
        let _ = select(None, &mut read_fds, None, None, tv);

        if !read_fds.contains(sock.as_fd()) {
            continue; // timeout — loop back to fire timers
        }

        let (n, src_addr) = match sock.recv_from(&mut buf) {
            Ok(r)  => r,
            Err(_) => continue,
        };
        let data = &buf[..n];
        let src  = src_addr.to_string();

        let msgs: Vec<Value> = match serde_json::from_slice(data) {
            Ok(v)  => v,
            Err(_) => continue,
        };

        let req_bytes = data.len() + IP_UDP_HEADER;
        let now       = now_secs();
        let my_token  = token_for(&secret, &src);

        let is_verified = msgs.iter()
            .any(|m| cookie_of(m, "AlwaysReturned") == Some(my_token.as_str()));

        let mut out: Vec<Value>             = Vec::new();
        let mut their_token: Option<String> = None;
        let mut peers_list: Vec<String>     = Vec::new();

        peers.insert(src.clone());

        for m in &msgs {
            if let Some(peers_obj) = m.get("Peers") {
                if let Some(arr) = peers_obj.get("peers").and_then(|v| v.as_array()) {
                    for p in arr {
                        if let Some(s) = p.as_str() {
                            peers.insert(s.to_string());
                        }
                    }
                }
            }
            if let Some(iah) = m.get("IAmHere") {
                if let (Some(nm), Some(t)) = (
                    iah.get("name").and_then(|v| v.as_str()),
                    iah.get("t").and_then(|v| v.as_i64()),
                ) {
                    presence.insert(nm.to_string(), (t, src.clone()));
                }
            }
            if let Some(hiw) = m.get("HereIsWho") {
                if let Some(nodes) = hiw.get("nodes").and_then(|v| v.as_array()) {
                    for node in nodes {
                        if let (Some(nm), Some(t)) = (
                            node.get("name").and_then(|v| v.as_str()),
                            node.get("t").and_then(|v| v.as_i64()),
                        ) {
                            let addr = node.get("addr")
                                .and_then(|v| v.as_str())
                                .unwrap_or(&src)
                                .to_string();
                            presence.insert(nm.to_string(), (t, addr));
                        }
                    }
                }
            }
            if m.get("WhoIsHere").is_some() {
                let cutoff = now - 60;
                let nodes: Vec<Value> = presence.iter()
                    .filter(|(_, (t, _))| *t >= cutoff)
                    .map(|(nm, (t, a))| json!({"name": nm, "t": t, "addr": a}))
                    .collect();
                out.push(json!({"HereIsWho": {"nodes": nodes}}));
            }
            if m.get("PleaseSendPeers").is_some() {
                let pl: Vec<String> = peers.iter().take(20).cloned().collect();
                peers_list = pl.clone();
                out.push(json!({"Peers": {"peers": pl}}));
            }
            if let Some(tok) = cookie_of(m, "PleaseAlwaysReturnThisMessage") {
                their_token = Some(tok.to_string());
            }
        }

        if !out.is_empty() {
            if let Some(ref tok) = their_token {
                out.push(json!({"AlwaysReturned": cookie(tok)}));
            }
            out.push(json!({"PleaseAlwaysReturnThisMessage": cookie(&my_token)}));

            if !is_verified {
                let payload = serde_json::to_vec(&out).unwrap_or_default();
                if payload.len() > (req_bytes as f64 * 2.5) as usize {
                    let mut trimmed = vec![json!({"PleaseAlwaysReturnThisMessage": cookie(&my_token)})];
                    if let Some(p) = peers_list.first() {
                        trimmed.push(json!({"Peers": {"peers": [p]}}));
                    }
                    out = trimmed;
                }
            }

            if let Ok(bytes) = serde_json::to_vec(&out) {
                let _ = sock.send_to(&bytes, src_addr);
            }
        }
    }
}
