import socket, json, time, random, sys, os

NAME = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("NAME", "anon")
BOOTSTRAP = [("148.71.89.128", 24254), ("159.69.54.127", 24254)]

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", 24254))
sock.settimeout(1.0)

peers = set()
presence = {}  # name -> {"t": unix_seconds, "addr": "ip:port"}
token = str(random.random())

def send(addr, msgs):
    sock.sendto(json.dumps(msgs).encode(), addr)

def split(s):
    i = s.rfind(":")
    return s[:i], int(s[i+1:])

for b in BOOTSTRAP:
    peers.add(f"{b[0]}:{b[1]}")
    send(b, [{"PleaseSendPeers": {}}, {"PleaseAlwaysReturnThisMessage": token}])

last_ping = last_print = 0

while True:
    now = time.time()

    if now - last_ping > 5:
        for p in list(peers):
            send(split(p), [{"IAmHere": {"name": NAME, "t": int(now)}},
                            {"PleaseAlwaysReturnThisMessage": token}])
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
    out = []

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
        if "PleaseAlwaysReturnThisMessage" in m and out:
            out.append({"AlwaysReturned": m["PleaseAlwaysReturnThisMessage"]})

    if out:
        sock.sendto(json.dumps(out).encode(), addr)

