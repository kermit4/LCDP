#!/usr/bin/env -S cargo +nightly -Zscript
---
[dependencies]
serde_json = "1"
rand = "0.8"
hmac = "0.12"
sha2 = "0.10"
hex = "0.4"
---

use std::collections::{HashMap, HashSet};
use std::env;
use std::net::UdpSocket;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use hmac::{Hmac, Mac};
use rand::RngCore;
use serde_json::{json, Value};
use sha2::Sha256;

const BOOTSTRAP: &[&str] = &["148.71.89.128:24254", "159.69.54.127:24254"];
const IP_UDP_HEADER: usize = 28;

type HmacSha256 = Hmac<Sha256>;

fn now_secs() -> i64 {
    SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64
}

/// HMAC-derived token: no per-peer state to store.
/// See README: "You could use a hash of their address and a secret."
fn token_for(secret: &[u8], addr: &str) -> String {
    let mut mac = HmacSha256::new_from_slice(secret).unwrap();
    mac.update(addr.as_bytes());
    hex::encode(&mac.finalize().into_bytes()[..16])
}

struct State {
    peers:    HashSet<String>,
    presence: HashMap<String, (i64, String)>, // name -> (t, addr)
}

fn send(sock: &UdpSocket, addr: &str, msgs: &[Value]) {
    if let Ok(bytes) = serde_json::to_vec(msgs) {
        let _ = sock.send_to(&bytes, addr);
    }
}

fn main() {
    let name = env::args().nth(1)
        .or_else(|| env::var("NAME").ok())
        .unwrap_or_else(|| "anon".to_string());

    let mut secret_bytes = [0u8; 32];
    rand::thread_rng().fill_bytes(&mut secret_bytes);
    let secret = Arc::new(secret_bytes);

    let sock = UdpSocket::bind("0.0.0.0:24254").expect("bind failed");

    let state = Arc::new(Mutex::new(State {
        peers:    BOOTSTRAP.iter().map(|s| s.to_string()).collect(),
        presence: HashMap::new(),
    }));

    for &b in BOOTSTRAP {
        send(&sock, b, &[
            json!({"PleaseSendPeers": {}}),
            json!({"PleaseAlwaysReturnThisMessage": token_for(&*secret, b)}),
        ]);
    }

    // IAmHere broadcast thread
    {
        let sock2   = sock.try_clone().expect("clone");
        let state2  = Arc::clone(&state);
        let secret2 = Arc::clone(&secret);
        let name2   = name.clone();
        thread::spawn(move || loop {
            thread::sleep(Duration::from_secs(5));
            let t = now_secs();
            let peers: Vec<String> = state2.lock().unwrap().peers.iter().cloned().collect();
            for peer in peers {
                send(&sock2, &peer, &[
                    json!({"IAmHere": {"name": name2, "t": t}}),
                    json!({"PleaseAlwaysReturnThisMessage": token_for(&*secret2, &peer)}),
                ]);
            }
        });
    }

    // Presence board print thread
    {
        let state3 = Arc::clone(&state);
        let name3  = name.clone();
        thread::spawn(move || loop {
            thread::sleep(Duration::from_secs(10));
            let now = now_secs();
            let st = state3.lock().unwrap();
            println!("\n--- Who is here ({name3}) ---");
            let mut board: Vec<_> = st.presence.iter().collect();
            board.sort_by_key(|(n, _)| n.as_str());
            for (n, (t, addr)) in &board {
                println!("  {n}  {addr}  {}s ago", now - t);
            }
        });
    }

    // Receive loop
    let mut buf = [0u8; 65535];
    loop {
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
        let my_token  = token_for(&*secret, &src);

        // Verified if this packet echoes the HMAC token we would compute for this address.
        let is_verified = msgs.iter().any(|m| {
            m.get("AlwaysReturned").and_then(|v| v.as_str()) == Some(&my_token)
        });

        let mut out: Vec<Value>          = Vec::new();
        let mut their_token: Option<String> = None;
        let mut peers_list: Vec<String>     = Vec::new();

        {
            let mut st = state.lock().unwrap();
            st.peers.insert(src.clone());

            for m in &msgs {
                if let Some(peers_obj) = m.get("Peers") {
                    if let Some(arr) = peers_obj.get("peers").and_then(|v| v.as_array()) {
                        for p in arr {
                            if let Some(s) = p.as_str() {
                                st.peers.insert(s.to_string());
                            }
                        }
                    }
                }
                if let Some(iah) = m.get("IAmHere") {
                    if let (Some(nm), Some(t)) = (
                        iah.get("name").and_then(|v| v.as_str()),
                        iah.get("t").and_then(|v| v.as_i64()),
                    ) {
                        st.presence.insert(nm.to_string(), (t, src.clone()));
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
                                st.presence.insert(nm.to_string(), (t, addr));
                            }
                        }
                    }
                }
                if m.get("WhoIsHere").is_some() {
                    let cutoff = now - 60;
                    let nodes: Vec<Value> = st.presence.iter()
                        .filter(|(_, (t, _))| *t >= cutoff)
                        .map(|(nm, (t, a))| json!({"name": nm, "t": t, "addr": a}))
                        .collect();
                    out.push(json!({"HereIsWho": {"nodes": nodes}}));
                }
                if m.get("PleaseSendPeers").is_some() {
                    let pl: Vec<String> = st.peers.iter().take(20).cloned().collect();
                    peers_list = pl.clone();
                    out.push(json!({"Peers": {"peers": pl}}));
                }
                if let Some(tok) = m.get("PleaseAlwaysReturnThisMessage").and_then(|v| v.as_str()) {
                    their_token = Some(tok.to_string());
                }
            }
        }

        if !out.is_empty() {
            if let Some(ref tok) = their_token {
                out.push(json!({"AlwaysReturned": tok}));
            }
            // Include our token in every reply so an unverified peer can echo it back
            // and receive full responses starting from the very next exchange.
            out.push(json!({"PleaseAlwaysReturnThisMessage": my_token}));

            if !is_verified {
                let payload = serde_json::to_vec(&out).unwrap_or_default();
                if payload.len() > (req_bytes as f64 * 2.5) as usize {
                    // Minimum: our token (lets them bootstrap verification) + at most 1 peer.
                    // AlwaysReturned is dropped — unverified peers need our token to bootstrap,
                    // not proof that we are real.
                    let mut trimmed = vec![json!({"PleaseAlwaysReturnThisMessage": my_token})];
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
