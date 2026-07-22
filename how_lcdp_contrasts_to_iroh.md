# LCDP (draft-pearson-lcdp-04) vs iroh.computer

## TL;DR
- LCDP: Minimal datagram JSON envelope. No connection, no mandatory crypto, no versioning. Everything unknown is ignored. Security, reliability, congestion control are optional higher-layer messages.
- iroh: Full connection-oriented p2p stack. QUIC over UDP with crypto identity (EndpointId = ed25519 pubkey), hole-punching, relays, and composable protocols (blobs, gossip, docs).

## Core Design Philosophy

| | LCDP | iroh |
|---|---|---|
| Goal | Lowest common denominator interop. Debuggability and dev velocity > bandwidth/CPU. Perpetual compatibility by extension. | Fast, reliable direct connectivity between NATed/mobile devices. Dial keys, not IPs. |
| Assumption | Bandwidth and CPU are NOT bottlenecks in 2026. Engineering time is. JSON is reliably generatable by tools incl. LLMs. | IP addresses break. Direct routes are fastest, relays are expensive. Needs hole-punching. |
| Compatibility | By ignoring. MUST ignore unknown message types and unknown fields. MUST NOT change semantics of existing fields. | By QUIC versioning + ALPN. Uses noq QUIC with TLS 1.3. Upgrades negotiated. |

## Wire Format

LCDP (Sec 3):
  Datagram = UTF-8 JSON array
  Element = { "SingleKey": { ...object... } }
  Example: [{"PleaseAlwaysReturnThisMessage":{"cookie":"abc"}}, {"Peers":{"peers":["198.51.100.1:24254"]}}]

    - Transport: UDP RECOMMENDED (port 24254 convention), MAY use websockets/other datagrams
    - MTU: SHOULD <= 5888, MAY <= 1200
    - Payload always object, never raw string/number

iroh:
    - QUIC frames over UDP, binary. Encrypted, stream-multiplexed, congestion-controlled, 0-RTT.
    - Relay protocol is stateless, custom binary over QUIC/TLS
    - Discovery via pkarr signed DNS packets (TXT at dns.iroh.link) + mDNS

## Identity, Security, Anti-Spoofing

| | LCDP | iroh |
|---|---|---|
| Identity | None in base. Optional MyPublicKey {ed25519h: hex} | Mandatory. EndpointId = ed25519 public key. All connections authenticated |
| Anti-spoof | MUST implement verification. Pattern: PleaseAlwaysReturnThisMessage / AlwaysReturned with cookie. MUST NOT reply >2x request size to unverified source per RFC8085 Sec 6 | Built-in via QUIC + relay coordination. Relays verify endpoints before hole-punch |
| Encryption | Optional EncryptedMessages {base64, noise_params} that MUST encapsulate another JSON array (not TLS). Plus SignedMessage | Mandatory transport encryption. QUIC + TLS 1.3, authenticated encryption, PFS |
| Parser Safety | MUST use memory-safe JSON parser, MUST reject excessive nesting | Uses Rust, memory-safe by language |

## State and Reliability

LCDP Sec 5.1:
    - Statelessness is explicit goal. No connection state required.
    - No congestion control in base. Per RFC8085 Sec 3.1: if >1 pkt/RTT, MUST add CC. Low-rate gossip MAY skip.
    - No reliability. App defines retries.

iroh:
    - Connection-oriented. Maintains QUIC connection state, measures path, migrates.
    - Hole-punching is stateful coordination via relay, then attempts direct.
    - Reliability, ordering, flow control, congestion control provided by QUIC.
    - ~90% hole-punch success, ~95% bytes over direct per iroh FAQ.

## Peer Discovery

LCDP Sec 4.2 - Optional:
  [{"PleaseSendPeers":{}}]
  [{"Peers":{"peers":["198.51.100.1:24254"]}}]
  [{"WhereAreThey":{"ed25519h":"hex"}}]
  Address format unconstrained string.

iroh:
    - pkarr / DNS discovery + relay Rendezvous + mDNS + explicit tickets
    - Endpoint addresses = transport addresses + relay URL + EndpointId
    - iroh-gossip uses HyParView + PlumTree for pubsub overlay

## Extensibility

LCDP Sec 3.3:
    - No versioning. Add new message types anytime. Add new fields anytime. Never change existing field semantics. Never change payload from object to other type.

iroh:
    - Composable protocols via Router + ALPN: iroh-blobs (BLAKE3 content-addressed BAO), iroh-gossip, iroh-docs (eventual-consistent KV), custom protocols.
    - Wire extensibility via QUIC streams + postcard codec.

## When to use which

Use LCDP if you want:
    - Implement in an afternoon in any language with JSON.parse
    - Debug with tcpdump -A
    - Speak to heterogeneous / constrained / legacy / AI-generated clients
    - Need air-gap / clipboard / file-carried messages
    - Can tolerate JSON overhead and no built-in security

Use iroh if you want:
    - Direct phone-to-phone / browser-to-device with NAT traversal
    - Encrypted-by-default, high throughput (TB blob transfer), low latency streams
    - Production p2p with discovery, relay infra, metrics
    - Accept Rust-centric ecosystem + binary protocol complexity

## How they could compose

LCDP as a fallback ALPN inside iroh:

  iroh QUIC (ALPN /iroh-blobs, /iroh-gossip)  // fast path
    |
    +-- ALPN /lcdp/0.4 = JSON array over QUIC datagram / relay
    // slow path: still addressable by same EndpointId, useful when UDP blocked or for human inspection

This matches LCDP Sec 5 Transport Agnosticism - LCDP could run over iroh's datagram transport, while iroh provides the missing CC, encryption, and NAT traversal that LCDP delegates.
