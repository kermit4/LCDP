# LCDP from the Perspective of a libp2p Dev

This doc answers common questions from developers familiar with libp2p. LCDP is not a libp2p competitor 1:1. It's a different answer to "what should the base layer of p2p look like?"

If you know libp2p, you can read LCDP in 10 minutes. The entire wire spec is: [{"MessageType":{...}}]. Everything else is optional messages.

LCDP is not a better libp2p. It is a deliberate step down the stack to a place where the application developer retains control and visibility into the network layer, and does not depend on language support beyond a JSON library.

## Core Philosophy Differences

| | libp2p | LCDP |
| --- | --- | --- |
| Base abstraction | Connection -> Stream | Datagram -> Message |
| Default state | Stateful, negotiated | 0-state, fire-and-forget |
| Latency floor | 2-3 RTT: transport + security + mux | 0.5 RTT: one datagram |
| Reliability | Built into streams via Yamux/mplex | Build it yourself with messages if you need it |
| Versioning | /protocol/1.2.3, negotiate, break on mismatch | Add fields. Unknown keys ignored. No versions. |
| Crypto | TLS/Noise mandatory per connection | optional per message |
| Wire format | Negotiated: could be protobuf, noise packets | Always UTF-8 JSON arrays. tcpdump -A readable |
| Identity | PeerID required, derived from pubkey | ed25519h optional. Use it if you need it |
| Goal | "Be the TCP/IP of p2p" | "Be the IP of p2p" |
| **Network policy stance** | **Make it connect: punch NAT, use relays, hide failures** | **Make it visible: if direct UDP fails, fail fast so users know P2P was blocked** |

Analogy: libp2p is POSIX. LCDP is sendto(). You can build POSIX on sendto(). You can't build sendto() on POSIX without ripping things out.

libp2p gives you a composable toolkit for production p2p: peer IDs, secure channels, stream multiplexing, NAT hole punching with relays, DHT routing, pubsub. You choose pieces, you get guarantees.

LCDP gives you one wire format: UTF-8 JSON arrays of single-key objects sent over UDP.

`[{"ChatMessage":{"message":"hi"}}]`

No handshake, no version, no stream abstraction, no required encryption. Compatibility comes from "ignore what you do not understand" rather than negotiation.

## 1. Is LCDP meant to be an alternative to libp2p?

No, not directly. It is an alternative to the assumption that you always need a full stack.

libp2p: "P2P apps need connections, streams, mandatory crypto, protocol negotiation. Here's a framework."

LCDP: "P2P apps need to send messages to peers. Here's the smallest wire format. Build connections if you want." 

Use LCDP when you want more control, minimal latency, zero dependencies, works from bash with netcat, survives for decades without a version bump, lets you keep state for 10 peers or 10,000 peers without kernel socket exhaustion, **and when you want P2P connectivity to succeed or fail honestly, not be silently replaced with relayed lag**.

You could reimplement all of libp2p as LCDP message types. You can't reimplement LCDP inside libp2p without removing the Connection object, which breaks libp2p.

They solve different scarcities. libp2p optimizes for machine efficiency, protocol correctness, and "always connect". LCDP optimizes for human understanding, implementation speed in 2026, and **protocol honesty: direct UDP works or it doesn't, and the user should know which**.

### 2. Should someone switch from libp2p to LCDP?

Consider LCDP if:
1. Profiling shows >30% CPU in Yamux/TLS handshakes
2. Circuit Relay costs exceed $1k/mo due to symmetric NAT or don't want to depend on a third party for it
3. You want a accessible wire format -- tcpdump -A and see {"ChatMessage":{...}} not TLS blobs
4. You have latency sensitive applications
5. You are prototyping and want a working p2p demo in an afternoon, not a month
6. You need to talk to thousands of peers with almost no per-peer state
7. You want AI to generate clients reliably (JSON is far easier for LLMs than protobufs)
8. You want messages that survive tcpdump, grep, and ten years of bitrot
9. You are building something latency sensitive and loss tolerant, like gossiping sensor data or game state
10. **You want failures to be visible UX, not masked by relays.  You want users to stand up for their right to communicate directly with others without a gatekeeper, and to know when their network policy restricts it, not mask it with degraded performance and code complexity, before the censorship becomes the norm, rather than perpetuate the users' ignorance.**

Don't switch if:
1. You need libp2p compatibility (IPFS, Filecoin, Polkadot, etc)
2. Proven at 500k nodes from day 1 (LCDP has some evolving to do for scale)
3. WebRTC in browsers
4. Your team only knows libp2p
5. You're doing bulk file sync. libp2p solved that
6. You need authenticated encryption by default, not as an optional wrapper
7. **You require "connect no matter what" behavior and are willing to pay relay costs + accept added latency and potential gatekeeping to mask network restrictions from the user**

It's a port, not a drop-in. State models are inverted.

### 4. New project: when to pick LCDP vs libp2p?

| Choose LCDP when | Choose libp2p when |
| --- | --- |
| You value readability over bandwidth | You value bandwidth and CPU efficiency |
| You want 20 lines of Python, not 20 crates | You need production-grade backpressure and flow control |
| You want the option for 0.5 RTT loss tolerant messaging | You only will ever need reliable ordered streams and latency is not a concern |
| You want perpetual compatibility without versions | You are okay with protocol negotiation and upgrades |
| You want any language, even bash, to join | You need a mature ecosystem in Go, Rust, JS, Nim |
| **You want the app to fail fast if P2P is blocked, so users see the network policy instead of it being hidden behind relay lag** | **You need to traverse hostile NATs and are okay with relays/TURN as a fallback to maximize connectivity** |

A practical heuristic: if your first milestone is "two laptops behind home routers exchange a JSON ping without a server," start with LCDP. If your first milestone is "secure, multiplexed streams with peer routing at internet scale," start with libp2p or expand upon LCDP.

## What libp2p developers usually miss at first

- **No streams.** If you want streams, build them as messages: `{"StreamOpen":{"id":"a"}}`, `{"StreamData":{"id":"a","seq":1}}`. You choose reliability per stream.
- **Identity is optional.** `MyPublicKey` and `SignedMessage` exist, but you can send unauthenticated datagrams. That is intentional for bootstrapping and for low-risk gossip.
- **NAT without servers.** LCDP does not use STUN. It relies on both peers sending from the same port they listen on. The `PleaseAlwaysReturnThisMessage` cookie prevents amplification attacks. It works on most home NATs, fails on the hardest symmetric NATs. **That failure is intentional UX: it surfaces network policy instead of burying it under a relay. If UDP is blocked, the app can tell the user "Direct P2P is blocked on this network" rather than silently falling back to a slow, expensive relay that trains users to accept degraded P2P and strengthens a potential channel of gatekeeping and censorship.**
- **No automatic relay fallback.** Forwarding is a message type, not a default. You opt into complexity, cost, and latency. libp2p opts you in by default to maximize connectivity.

## Bottom line

Do not think "LCDP versus libp2p." Think "messages versus connections."

If you are comfortable with multistream-select, you will feel at home adding a new JSON key. If you are tired of upgrading six protocol versions to add one field, you will feel relief.

**If you are tired of apps that "just work" by silently becoming client-server when networks get unfriendly, you will feel relief when LCDP fails loudly. That failure is a feature: it preserves user visibility into whether P2P is actually allowed. Each time we hide a blocked UDP port behind TURN, we train users to accept that P2P is "just laggy sometimes" instead of "being blocked". For now, UDP direct still works on most networks. We should keep it that way by not digging our own graves with cat-and-mouse workarounds.**

Start by implementing two messages: `PleaseSendPeers` and `PleaseReturnThisMessage`. Talk to the bootstrap node at 148.71.89.128:24254 with netcat. You will have a better intuition in five minutes than any spec can give.

REDO

## Translation Table: libp2p -> LCDP

| libp2p Concept | LCDP Equivalent | Notes |
| --- | --- | --- |
| PeerID | ed25519h in MyPublicKey | Both are pubkey hashes. LCDP uses hex, libp2p uses base58 |
| PeerStore | Peers listed in Peers message | You store less metadata by default |
| Multiaddr | "1.2.3.4:24254" string | LCDP doesn't spec address format. Do what works |
| Stream | StreamOpen + StreamData messages | Build it yourself if needed. Not built-in |
| Protocol ID | Message type key: "ChatMessage" | No version string. No negotiation |
| Identify | MyPublicKey | Same idea. No handshake required |
| Ping | PleaseReturnThisMessage / ReturnedMessage | RTT measurement without connection |
| Kademlia DHT | WhereAreThey + Peers gossip | DHT is just message patterns. Build one if you want |
| Gossipsub | Subscribe + Publish messages | You invent the message types. Flood/forward as you like |
| Circuit Relay v2 | Forward message | Any node can relay. No special protocol. **No auto-fallback: user/app chooses to use it** |
| AutoNAT | Send UDP, see if reply arrives | If you get a reply, you're reachable. **If not, you surface that to the user instead of hiding it** |
| Secured Connection | EncryptedMessages + SignedMessage | Per-message, not per-connection. Optional |

You can implement all of libp2p as LCDP messages. The reverse isn't true without breaking libp2p's Connection invariant.

## Anticipated Questions

### "Why JSON? Isn't that wasteful?"

In 2005, yes. In 2026, a $50 ARM SBC can base64 + parse 1 Gbps of JSON on one core. The bottleneck is developer time, not CPU. You can tcpdump -A and read the protocol. You can implement in Bash. That's the optimization that matters now.

If you measure and find JSON is your bottleneck, define {"BinaryFrame":{"data":"..."}} or run a separate port. Don't pay the complexity tax until you must.

### "No versions means no evolution?"

Opposite. Versions freeze evolution. LCDP evolves by adding words.

Old node sees {"ChatMessage":{"message":"hi","lang":"en"}}. It ignores lang, prints hi. New node uses lang. No negotiation, no breakage. This is how human language works. We didn't upgrade English to v2.

If you need incompatible semantics, use a new message type: ChatMessageV2. Old nodes drop it. No explosion of version matrices.

### "How do you do NAT traversal without STUN/TURN?"

Same as STUN, but no spec: both sides send UDP. PleaseSendPeers gets you an address. PleaseAlwaysReturnThisMessage confirms the path is open. **If it fails, you tell the user P2P is blocked. You can optionally use Forward through a friend, but that choice and its latency cost are explicit, not hidden.** No dedicated infra required.

libp2p's AutoNAT + Circuit Relay solves the same problem by defaulting to relays when direct fails. **LCDP defaults to failing visibly. That difference is policy: do you want users to know when the network is unfriendly to P2P, or do you want to paper over it? While direct UDP still works for most users, failing visibly creates pressure to keep it that way instead of normalizing relays.**

### "Isn't this insecure without mandatory encryption?"

Peers and WhereAreThey are public anyway. Encrypting them is theatre. Use EncryptedMessages when the payload needs privacy. Use SignedMessage when you need authenticity. Don't pay crypto cost on discovery traffic.

libp2p forces TLS on every connection because it assumes file transfer. LCDP assumes you know your threat model.

### "How do I do reliable delivery?"

Same way you would over UDP: ACKs, retries, FEC. But make it a message type:

[{"ReliableSend":{"id":"uuid","seq":0,"data":"...","wants_ack":true}}]  
[{"Ack":{"id":"uuid","seq":0}}]

Now you have reliability when you want it, and 0.5 RTT when you don't. libp2p bakes reliability into every stream, so you pay for it even on Pong moves.

### "What about backpressure / congestion control?"

Not in the base spec. If you're sending faster than the network, add your own {"RateLimit":{...}} messages. Or use QUIC as a transport under LCDP. Or accept packet loss like a game.

TCP does congestion control for you, but gives you head-of-line blocking. LCDP gives you the choice.

### "Can I use this in the browser?"

Today: WebSocket or WebTransport to a gateway node. Browsers can't do raw UDP to arbitrary peers due to security model. That's a browser limit, not LCDP limit.

Future: If browsers ever expose raw UDP via WebRTC DataChannel "raw" mode or similar, LCDP works directly. Until then, [{"Forwarded":{...}}] through a gateway is the path. Same problem libp2p has.

## Summary

| Use LCDP when | Use libp2p when |
| --- | --- |
| Latency < 50ms matters | Bulk transfer > latency |
| Messages < 64KB | Files > 1MB |
| You want 0-state scale | You want streams + backpressure |
| You debug with tcpdump | You need IPFS interop today |
| 500 LOC budget | 200k LOC budget is fine |
| You hate frameworks | You want a framework |
| **You want P2P failures to be visible so policy stays visible** | **You want P2P to "always work" even if that means relay lag** |

Core difference: libp2p optimizes for "don't reimplement TCP" and "connect at all costs". LCDP optimizes for "let the dev be in control" and **"connect honestly, or don't"**.

libp2p is a cathedral. LCDP is a bazaar with one rule: JSON arrays. Pick based on which problem you're solving.

**The doors to real P2P are still open on most networks, but they're closing quietly. Every time an app hides a blocked port behind a relay, it adds latency and complexity instead of showing the user what happened. That trains users to accept a degraded, server-dependent internet and removes pressure to keep P2P viable. LCDP chooses to fail visibly because if we normalize workarounds, we'll dig our own grave in a cat-and-mouse game we can't win.**
