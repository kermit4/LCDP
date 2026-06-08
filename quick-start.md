# Quick Start

The wire is one sentence: UDP port 24254, UTF-8 JSON arrays of externally tagged objects. That is everything. No library, no handshake, no account.

In 2026, with an LLM writing the boilerplate, the hardest part of building p2p is deciding what to build. This document shows you how to get there in an afternoon by giving an AI a prompt and running what comes back.

---

## What we are building

A distributed presence board. Each node announces its name every few seconds. Every node accumulates who it has heard from. No server, no NAT configuration, no port forwarding.

NAT traversal is free: when you send UDP from the same socket you listen on, your public IP and port are already known to the peer. The peer can share them with others. No STUN, no TURN, no relay.

### New message types for this app

These are not in the wiki. We are making them up right now. That is allowed. Use a long clear name, ignore anything you do not recognize, and you are interoperable.

```json
{"IAmHere": {"name": "alice", "t": 1748789123}}
{"WhoIsHere": {}}
{"HereIsWho": {"nodes": [{"name": "alice", "t": 1748789123, "addr": "1.2.3.4:5678"}]}}
```

### Existing message types we reuse

```json
{"PleaseSendPeers": {}}
{"Peers": {"peers": ["148.71.89.128:24254", "1.2.3.4:5678"]}}
{"PleaseAlwaysReturnThisMessage": "some-random-token"}
{"AlwaysReturned": "some-random-token"}
```

`PleaseAlwaysReturnThisMessage` is the anti-spoof mechanism. Include a random token in every outgoing packet. Echo it back with `AlwaysReturned` in any packet where you are already replying. This stops someone from forging a source IP to make your node flood a victim.

---

## The prompt

Copy this into Claude (or any capable LLM) and run what comes out.

```
Build a peer-to-peer presence board using the LCDP protocol.

Wire format: UDP port 24254. Each packet is a UTF-8 JSON array of objects.
Each object has exactly one key (the message type) and a payload value.
Tolerate and ignore any message type you do not recognize.

Bootstrap nodes already running on the internet:
  148.71.89.128:24254
  159.69.54.127:24254

Use these existing message types:
  {"PleaseSendPeers":{}}
  {"Peers":{"peers":["ip:port",...]}}
  {"PleaseAlwaysReturnThisMessage":"<token>"}   -- include in every outgoing packet
  {"AlwaysReturned":"<token>"}                  -- echo back whenever you are already replying

Add these new message types:
  {"IAmHere":{"name":"alice","t":1748789123}}   -- I am present; t is Unix seconds
  {"WhoIsHere":{}}                              -- ask who else is around
  {"HereIsWho":{"nodes":[{"name":"alice","t":1748789123,"addr":"1.2.3.4:5678"}]}}

Behavior:
  - Bind UDP on port 24254
  - On startup, send PleaseSendPeers to both bootstrap nodes
  - Add any address you receive a packet from to your peer set
  - Every 5 seconds, send IAmHere to all known peers
  - When you receive IAmHere, record the name, t, and source address
  - When you receive WhoIsHere, reply with HereIsWho listing nodes heard in the last 60 seconds
  - When you receive HereIsWho, merge the node list into your records
  - When you receive Peers, add those addresses to your peer set
  - When you receive PleaseSendPeers, reply with your peer list (up to 20)
  - Include PleaseAlwaysReturnThisMessage with a random token in every outgoing packet
  - Include AlwaysReturned echoing their token in any packet where you are already replying
  - Print the presence board to stdout every 10 seconds: name, address, seconds since last heard
  - The node name comes from the first CLI argument or the NAME env var, default "anon"
  - Use a 1-second socket timeout so the send loop can fire without a dedicated thread

NAT traversal is automatic. You reply from the same socket you listen on, so your public
IP:port is visible to each peer and can be shared with others. No STUN needed.
```

## Run two at once

Run two on any two different systems:
```
python3 presence.py alice
node presence.js bob
go run presence.go carol
stack script presence.hs dave
```

The Haskell version uses [Stack](https://docs.haskellstack.org/) which downloads its own GHC and all dependencies automatically — no manual package installation needed.

You will soon see each other's names. If anyone else in the world is running this right now, you will see them too.

---

## Add your own messages

The namespace is unlimited. Invent a key, put a payload in it, and broadcast it. Nodes that do not recognize it ignore it. Nodes that do recognize it use it.

```json
{"GameLobbyOpen": {"game": "pong", "slots": 3, "addr": "1.2.3.4:5678"}}
{"WeatherReading": {"c": 22.4, "humid": 0.61, "station": "alice-rooftop"}}
{"SharedDoc": {"id": "abc123", "seq": 7, "delta": "base64 of whatever you want"}}
```

None of these need approval. None of them break anything. You can add them to the same packet as `IAmHere` and old nodes will silently ignore the new keys while still seeing your presence announcement.

That is the whole protocol. Everything else is your application.
