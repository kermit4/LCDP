# Quick Start — Three ways in, no wrong door

You do not need to join a project. You need to send or receive one JSON array. Pick the path that matches how you like to build.

---

## Path 1: Use a running node as your post office (5 minutes)

Best if you write web pages, Python scripts, or anything that can speak UDP or WebSockets, and you do not want to deal with routing yourself.

1. Run a node. The Ruby version is the easiest to read:
   ```
   git clone https://github.com/kermit4/cjp2p-ruby
   cd cjp2p-ruby
   ruby node.rb
   ```
   It listens on UDP 24254 by default.

2. Talk to it. From a shell:
   ```
   echo -n '[{"PleaseSendPeers":{}}]' | nc -u 127.0.0.1 24254
   ```
   You will get back a Peers message.

You are not depending on me. If my bootstrap nodes disappear, your local node still talks to anyone you know the IP of.

---

## Path 2: Speak the wire directly (an afternoon)

Best if you want zero dependencies and you are building a native app, game, or embedded device.

Implement three things and you are interoperable:

1. Send and receive UDP packets containing UTF-8 JSON arrays of tagged values.
2. Send the token (like a HTTP cookie) from `PleaseAlwaysReturnThisMessage` whenever messaging, using `AlwaysReturned`, and send unique tokens for others to return to you. This is your anti-spoof.
3. Reply to `PleaseSendPeers` with a few IP:ports you know.  

That is it. Example in Python:

```python
import socket, json
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind(("0.0.0.0", 24254))

peers = set()
while True:
    data, addr = s.recvfrom(65535)
    try: msgs = json.loads(data.decode())
    except: continue
    out = []
    for m in msgs:
        if "PleaseSendPeers" in m:
            out.append({"Peers":{"peers":list(peers)[:20]}})
        if "ChatMessage" in m:
            print(addr, m["ChatMessage"]["message"])
        if out and "PleaseAlwaysReturnThisMessage" in m:
            out.append({"AlwaysReturned": m["PleaseAlwaysReturnThisMessage"]})
    peers.add(f"{addr[0]}:{addr[1]}")
    if out: s.sendto(json.dumps(out).encode(), addr)
```

Add `ChatMessage`, `AudioFrame`, or your own `{"MyAppPing":{}}` whenever you want. Old nodes ignore what they do not understand.

You now have NAT traversal for free, because you are sending from the same socket you listen on. No STUN server needed.

---

## Path 3: Bridge from the web to the real internet

Best if you are a web developer who hates running native code.

Browsers cannot send raw UDP, but they can talk WebSocket to a tiny bridge you run locally. That bridge is 30 lines of Node or Go. It translates:

browser WebSocket JSON array <-> UDP packet to the internet

Publish the bridge code, not a service. Each user runs their own. No central relay, no account.

This is how https://azai.net/video.html works. The page does not connect to my server for media, it connects to your localhost bridge, which routes directly to the other peer.

---

## Which path should you pick

- Want to prototype a chat in an hour? Path 1.
- Want to ship a game that does not rely on anyone? Path 2.
- Want to stay in the browser but keep p2p? Path 3.

All three speak the same arrays. A Ruby node, a Python script, and a web page can all be in the same swarm.

## The walkaway test

I wrote this so I can disappear. There is no registry, no version to update, no API key.

If you implement only `PleaseReturnThisMessage`, you can measure latency to others. If you implement only `WhereAreThey` and `ChatMessage`, you have a messenger. If you implement only `PleaseSendContent`, you have a file sharer.

You do not need my permission, my server, or my continued interest. Credit is appreciated, maintenance is not expected. Add your own messages, ignore mine if you like.

Start anywhere. The wire does not care.
