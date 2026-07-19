# How LCDP Contrasts to Nostr

> **Lowest Common Denominator Protocol (LCDP)** -- `draft-pearson-lcdp-01`, June 2026, port 24254 -- is not a Nostr replacement. It's one layer below it.

## TL;DR

- **LCDP** is a transport framing: how do two nodes exchange *anything* forever without breaking compatibility.
- **Nostr** is an application: how do two people exchange *signed social posts* via relays.

You could run Nostr inside LCDP. You can't run LCDP inside Nostr without reimplementing Nostr.

## Core Definitions

### LCDP (what we built)

- **Wire format:** JSON array of single-key objects over UDP: `[{"cookie": "..."}, {"ping": {...}}]`
- **Rule:** Unknown keys/fields/objects are IGNORED, not rejected. No versions.
- **Only MUST:** Anti-spoofing cookie exchange.
- **Everything else optional:** Crypto, reliability, congestion control, peer discovery are optional message types.
- **Goal:** Perpetual compatibility. A 2026 node can still talk to a 2040 node -- it just skips what it doesn't understand.
- **Philosophy:** The base protocol can't take sides. It just moves JSON.

### Nostr

- **Wire format:** JSON Event over WebSocket to relays: `{"id": "...", "pubkey": "...", "created_at": ..., "kind": 1, "tags": [...], "content": "...", "sig": "..."}`
- **Rule:** `id`, `pubkey`, `created_at`, `kind`, `tags`, `content`, `sig` are REQUIRED.
- **Identity:** secp256k1 keypair is mandatory. No sig = invalid.
- **Network model:** Client -> Relay -> Client. Relays are required.
- **Goal:** Censorship-resistant global social.

## Detailed Comparison

| Property | LCDP | Nostr |
| :--- | :--- | :--- |
| **Layer** | L3.5 - Transport framing | L7 - Social application |
| **Identity** | None required. You can speak with just UDP. Add `MyPublicKey` later if you want. | Mandatory pubkey + sig on every event |
| **Servers** | None assumed. Pure P2P. Peer discovery is an optional message. | Relays are required infrastructure. Anyone can run one, but you need one. |
| **Extensibility** | No registry. New message type = new key. Old nodes skip it. Never breaks. | Registry of `kind` numbers. Needs NIPs to avoid collisions. |
| **Human debuggable** | `tcpdump -A` is enough. UTF-8 array. | Also human readable, but needs websocket + JSON parsing + sig verification |
| **What it guarantees** | That bytes move and future compatibility is preserved | That a post was signed by a key and can be fetched from relays |

## Why People Think It's a Reinvention

1. Both are minimal JSON
2. Both say "ignore what you don't understand"
3. Both are designed to let communities fork ideas without forking the network

That similarity is intentional -- it's good protocol design.

## Why It's Not a Reinvention

Ask: Can I make a node that has no crypto at all, works on a local mesh with no relay, sends a 10MB file, and is still compatible in 2040?

Nostr: No, without breaking spec.
LCDP: Yes. Because LCDP delegates security, reliability, and congestion control to optional messages or higher layers.

## How They Fit Together

LCDP is a perfect carrier for Nostr. Define an optional LCDP message type:

```json
[
  {"cookie": "a1b2c3..."},
  {"MyPublicKey": {"kty": "secp256k1", "pub": "npub1..."}},
  {"nostr_event": {
    "kind": 1,
    "content": "hello world, but over LCDP",
    "created_at": 1718300000
  }}
]
```

Nostr gets transport independence. LCDP gets a real social use case.

## Conclusion

If Nostr is "the simplest protocol that can do Twitter without Twitter," LCDP is "the simplest protocol that can do anything without breaking."

Build social on Nostr. Build Nostr -- and everything else -- on LCDP.
