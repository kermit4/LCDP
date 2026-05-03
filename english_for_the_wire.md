# English for the Wire

This is not a product. It is a proposal for a common language between programs that want to talk peer to peer, without joining the same app, the same company, or the same ideology.

Call it LCDP if you need a short handle. It stands for nothing more than "UTF-8 JSON arrays of externally tagged objects sent between parties." Think IP, but for application messages. IP+JSON.

## The whole protocol in one sentence

Send an array. Each element is an object with one key. The key is the message type. The value is the payload.

`[{"ChatMessage":{"message":"hi"}}]`

That is the entire wire format. Everything else is optional.

## Why start this low

We got used to building connections first, then putting messages on top. That habit comes from the client-server era, like QWERTY comes from typewriters. It works, but it adds latency and state you often do not want.

Connections are a simulation built on top of messages. The operating system holds your data if one packet is lost, even when your app would rather see the next one right now. For voice, video, games, or just a chat ping, that artificial delay hurts.

If your app already handles retransmission, ordering, and timeouts at the timescale you care about, let it. Do not make the kernel do it again.

UDP gives you the raw datagram. Two peers behind NAT can usually communicate directly to each other. No STUN server to ask permission from, no TURN relay to pay for, no third party that can later decide who is allowed to talk. WebRTC is built on the same UDP, but the ecosystem has grown around centralized signaling and relay services. That reintroduces the censorship point we were trying to remove.

You can print these messages on paper airplanes if you want. UDP is convenient, not required.

## No versions, just new words

JSON is not going to change. If you need more data, add a field. If you need different meaning, make a new message type with a new name.

Old software sees an unknown key, it ignores it. New software sees an old message, it still understands it. Compatibility comes from tolerance, not from negotiation.

This is how natural language works. You do not upgrade English to v2. You invent a new word when you need it. Everyone else either learns it or skips that sentence.

The README lists messages that already exist in the wild: `PleaseSendPeers`, `Peers`, `WhereAreThey`, `ChatMessage`, `AudioFrame`, `VideoFrame`, `PleaseReturnThisMessage`, `AlwaysReturned`, `Content`, `EncryptedMessages`, `SignedMessage`, and a handful more. You do not have to implement any of them. Implement two and you have a useful tool.

## Keep as much state as you want

A node can remember millions of peers with just an IP, port, and last-seen time. It can also remember nothing and ask for peers every time. Both are valid.

Because there is no connection, there is no handshake cost. You can send a single datagram to a stranger: "here is a video frame, seq 42." If they care, they keep it. If not, they drop it. That is 0.5 RTT in the best case, 1 RTT if you want an ack.

Apps that need reliability build it on top with the messages they choose. Apps that need low latency just do not wait.

## A few concrete patterns

**Anti-spoof:** send `{"PleaseAlwaysReturnThisMessage":["cookie"]}`. The other side must echo `{"AlwaysReturned":["cookie"]}`. If they do not, you rate-limit replies to them. This stops someone from forging a source IP to make you flood a victim.

**Peer discovery:** `{"PleaseSendPeers":{}}` → `{"Peers":{"peers":["1.2.3.4:24254"]}}`. That is it.

**Chat:** `{"ChatMessage":{"message":"hello"}}`. Add a field later like `"lang":"en"` if you want. Old clients still show "hello".

**Large files:** `{"PleaseSendContent":{"id":"...","offset":0,"length":4096}}` → `{"Content":{"id":"...","base64":"...","offset":0}}`. Base64 is wasteful, but in 2026 a $50 laptop can base64 encode 1 Gbps into a JSON field on one core. Developer time is the bottleneck now, not CPU or bandwidth.

**Identity:** wrap any array in `{"SignedMessage":{"ed25519":"...","signature":"...","payload":"base64..."}}`. Now receivers know who said it, without a central CA.

You can run Bitcoin messages, Ethereum gossip, or a game of Pong over the same wire. The protocol does not care.

## Why now

In 1995 we could not afford to base64 everything and parse text for every packet. Networks were slow, CPUs were slow, memory was scarce. We invented binary protocols and stateful connections to save those resources.

Those bottlenecks moved. Today the slow part is getting a new developer to understand a spec, or waiting for a standards committee to approve a field. With AI-assisted coding, the cost of trying an idea is minutes, not months.

Optimizations only matter after you have measured the bottleneck. Right now the bottleneck is people, not packets. A readable, append-only message set lowers that barrier.

## Not owned, not promoted

This is not my network. There is no token, no company, no login server. The two bootstrap nodes listed in the README are just conveniences. Run your own, or run none and talk directly to friends.

The goal is to reduce fragmentation. Right now every p2p app invents its own discovery, its own NAT traversal, its own encryption envelope. They do not interop because they start from "build an app" instead of "agree on a few words."

If we agree on the lowest possible wire — arrays of tagged JSON — then applications can share peers, share identity keys, share established NAT paths, even if they care about completely different data.

You do not need permission to add a message. Use a long, clear name. Publish what you sent somewhere. If someone else already used that name differently, pick another. The namespace is huge.

## How to start

Pick a language you like. The Ruby and Bash implementations are under 500 lines and implement most message types. The Rust one is the most developed, but more to take in.

Implement these two and you are on the network:

1. respond to `PleaseSendPeers` with your small peer list
2. send and receive `PleaseReturnThisMessage` / `ReturnedMessage`

From there, add `ChatMessage` for text, or `AudioFrame` for voice, or invent `{"MyAppHello":{}}`. Others will ignore it until they care.

That is the point. You are not joining my project. You are speaking a language that already works over UDP, over WebSockets, over anything that moves bytes. The rest is up to your application, not up to a protocol committee.
