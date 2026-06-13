import socket, json, time, sys, os, hmac as _hmac, hashlib, secrets

NAME = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("NAME", "anon")
BOOTSTRAP = [("148.71.89.128", 24254), ("159.69.54.127", 24254)]
IP_UDP_HEADER = 28

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", 24254))
sock.settimeout(1.0)

peers = set()
presence = {}  # name -> {"t": unix_seconds, "addr": "ip:port"}

# HMAC-derived token: no per-peer state to store.
# See README: "You could use a hash of their address and a secret."
secret = secrets.token_bytes(32)

def token_for(addr_str):
    return _hmac.new(secret, addr_str.encode(), hashlib.sha256).hexdigest()[:32]

def send(addr, msgs):
    sock.sendto(json.dumps(msgs).encode(), addr)

def split(s):
    i = s.rfind(":")
    return s[:i], int(s[i+1:])

for b in BOOTSTRAP:
    key = f"{b[0]}:{b[1]}"
    peers.add(key)
    send(b, [{"PleaseSendPeers": {}}, {"PleaseAlwaysReturnThisMessage": {"cookie": token_for(key)}}])

last_ping = last_print = 0

while True:
    now = time.time()

    if now - last_ping > 5:
        for p in list(peers):
            send(split(p), [{"IAmHere": {"name": NAME, "t": int(now)}},
                            {"PleaseAlwaysReturnThisMessage": {"cookie": token_for(p)}}])
        last_ping = now

    if now - last_print > 10:
        print(f"\n--- Who is here ({NAME}) ---")
        for n, info in sorted(presence.items()):
            print(f"  {n}  {info['addr']}  {int(now - info['t'])}s ago")
        last_print = now

    try:
        data, addr = sock.recvfrom(65535)
    except socket.timeout:
        continue

    try:
        msgs = json.loads(data.decode())
    except Exception:
        continue

    src = f"{addr[0]}:{addr[1]}"
    peers.add(src)
    req_bytes = len(data) + IP_UDP_HEADER

    # Verified if this packet echoes the HMAC token we would compute for this address.
    is_verified = any(
        isinstance(m.get("AlwaysReturned"), dict) and
        m["AlwaysReturned"].get("cookie") == token_for(src)
        for m in msgs if "AlwaysReturned" in m
    )

    out = []
    their_token = None

    for m in msgs:
        if "Peers" in m:
            for p in m["Peers"].get("peers", []):
                peers.add(p)
        if "IAmHere" in m:
            presence[m["IAmHere"]["name"]] = {"t": m["IAmHere"]["t"], "addr": src}
        if "HereIsWho" in m:
            for node in m["HereIsWho"].get("nodes", []):
                presence[node["name"]] = {"t": node["t"], "addr": node.get("addr", src)}
        if "WhoIsHere" in m:
            cutoff = now - 60
            out.append({"HereIsWho": {"nodes": [
                {"name": n, "t": info["t"], "addr": info["addr"]}
                for n, info in presence.items() if info["t"] >= cutoff
            ]}})
        if "PleaseSendPeers" in m:
            out.append({"Peers": {"peers": list(peers)[:20]}})
        if "PleaseAlwaysReturnThisMessage" in m:
            pat = m["PleaseAlwaysReturnThisMessage"]
            their_token = pat.get("cookie") if isinstance(pat, dict) else None

    if out:
        if their_token is not None:
            out.append({"AlwaysReturned": {"cookie": their_token}})
        # Include our token in every reply so an unverified peer can echo it back
        # and receive full responses starting from the very next exchange.
        out.append({"PleaseAlwaysReturnThisMessage": {"cookie": token_for(src)}})

        if not is_verified:
            payload = json.dumps(out).encode()
            if len(payload) > 2.5 * req_bytes:
                # Minimum: our token (lets them bootstrap verification) + at most 1 peer.
                # AlwaysReturned is dropped — we are not proving ourselves, just giving
                # them what they need to prove themselves next time.
                trimmed = [{"PleaseAlwaysReturnThisMessage": {"cookie": token_for(src)}}]
                for item in out:
                    if "Peers" in item:
                        trimmed.append({"Peers": {"peers": item["Peers"]["peers"][:1]}})
                        break
                out = trimmed
        sock.sendto(json.dumps(out).encode(), addr)
