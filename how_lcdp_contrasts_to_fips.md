# How LCDP Contrasts to fips.network (FIPS)

> **LCDP** `draft-pearson-lcdp-04` port 24254 — is wire framing.
> **FIPS** Free Internetworking Peering System — is mesh routing.

TL;DR:
- LCDP: How do two nodes exchange *anything* forever without breaking compatibility. 0-state, JSON.
- FIPS: How do N nodes find and route to each other without central authority, over any transport.

### Core Definitions

**LCDP (what you built)**
- Wire: `[{"cookie":"..."}, {"ChatMessage":{"message":"hi"}}]` — UTF-8 JSON array of single-key objects
- Rule: Unknown keys/fields MUST be ignored. No versions, no negotiation.
- Only MUST: Anti-spoof cookie `{"PleaseAlwaysReturnThisMessage":{"cookie":"..."}}`
- Everything else optional: discovery, crypto, reliability are optional message types
- Goal: Perpetual compatibility. A 2026 node can still talk to a 2040 node.
- Philosophy: Be the IP of p2p. Make failure visible.

**FIPS (fips.network)**
- Wire: Binary mesh packets, encrypted sessions
- Rule: Nostr identity REQUIRED — secp256k1/schnorr npub is the routing address
- Network model: Self-organizing mesh over arbitrary transports — LAN, Bluetooth, serial, radio, internet overlay
- Discovery: Nodes generate own identities, discover each other, route without central authority
- Goal: Be the self-healing internet. Dial keys, not IPs.

### Layer Map

| Layer | Role | Example |
|---|---|---|
| 4 | Apps | Chat, video, git |
| 3 | Data models | Nostr events, Earthstar docs |
| 2 | Transport / Routing | **FIPS**, libp2p, iroh, Veilid |
| 1 | Wire framing | **LCDP** |
| 0 | Bytes | UDP, WebSocket, Bluetooth |

FIPS lives at Layer 2. LCDP lives at Layer 1. You can run LCDP *inside* FIPS as a payload, or use FIPS to route LCDP datagrams.

### Design Philosophy

| | LCDP | FIPS |
|---|---|---|
| Abstraction | Datagram -> Message | Mesh -> Route -> Session |
| State | 0-state, fire-and-forget | Stateful mesh, routing tables |
| Identity | ed25519h optional, any string | Nostr secp256k1 mandatory |
| Transport | UDP by convention, MAY be anything | Explicitly multi-transport by design |
| NAT traversal | Fail fast, make it visible user was blocked | Make it connect via mesh, relays |
| Debuggability | `tcpdump -A` readable JSON | Binary, encrypted |
| Versioning | Add keys, ignore unknown | Protocol alpha, breaking changes expected |

### When to use which

**Use LCDP if:**
- You want an AI to write a P2P app in one prompt
- You want perpetual compat without version negotiation
- You want to debug with tcpdump / paper airplanes

**Use FIPS if:**
- You want packets to find a path over BLE / radio / LAN without internet
- You want every node addressable by npub
- You want the mesh to self-heal around failures

**Use both if:**
- FIPS routes the bytes, LCDP is the JSON you put inside. That's the cleanest stack: `FIPS transport | LCDP framing | your ChatMessage`.

