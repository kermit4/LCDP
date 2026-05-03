# Why messages, not connections

This is the deep dive for people who keep asking "why not just use TCP or WebRTC data channels?" The short answer: connections are a useful illusion, but they were optimized for a world that no longer exists.

## Connections were a hack to save developers

In the 1970s, CPUs were slow and memory was measured in kilobytes. TCP gave you reliable, ordered bytes so you did not have to write retransmission yourself. That was a huge win.

Today every serious app reimplements those same mechanisms at the application layer anyway. Video calls buffer and reorder frames. Games send deltas and ignore old packets. Chat apps store and forward. You end up with reliability on top of reliability.

The result is head-of-line blocking. One lost packet makes the kernel hold back everything behind it, even if your app would have preferred to see the new data now. For real-time media that is pure latency you added to yourself.

## State is expensive when you talk to many

A TCP socket costs the kernel a few kilobytes of buffers, timers, congestion state. Fine for ten connections. Not fine for ten thousand peers in a mesh.

With messages over UDP, you choose the state. Keep a full congestion window for peers you video call. Keep only a last-seen timestamp for the other 9,990. Send a single datagram to a stranger with no handshake. That is how you get 0.5 RTT startup and the ability to remember a city-sized mesh on a laptop.

## NAT traversal without a landlord

WebRTC was supposed to be p2p, but in practice you need a signaling server to exchange SDP, and often a TURN server when direct UDP fails. Those servers are run by someone, they log, they can block, they cost money.

Plain UDP works between most NATs if both sides send at the same time. No third party sees the media. No third party can revoke your route.  The trick is coordination, not infrastructure. A single `PleaseSendPeers` exchange is enough to open the hole.

When you build on connections that are themselves built on messages (WebRTC data channel over SCTP over DTLS over UDP), you inherit all the middle layers and their policy points. Skip them.

## Many-to-many is not client-server

The web taught us one browser talks to one server. P2P is many to many. You want to gossip a peer list, forward a message for a friend, ask "who has this hash" without opening a dedicated stream to each person.

Message orientation matches that. You fire a datagram to five peers: `{"WhereAreThey":{"ed25519h":"..."}}`. Whoever knows answers. No connection setup, no teardown, no keepalive.

If you do want a connection-like abstraction, build it as a message type. `{"StreamOpen":{"id":"abc"}}`, then `{"StreamData":{"id":"abc","seq":1,"data":"..."}}`. You get to decide the reliability model, not the OS.

## Bottlenecks moved

In 2005, base64 in JSON would have been insane. Bandwidth and CPU were the limits. In 2026, I can saturate a gigabit link parsing JSON on a $50 ARM board. The limit is how fast a human can understand the protocol and ship code.

Readable messages mean you can debug with `tcpdump -A` and see `{"ChatMessage":{"message":"hi"}}`. You can implement a node in Bash. You can teach it to an LLM in one prompt. That is the optimization that matters now.

## Censorship resistance is architectural

Every layer that requires permission is a place to be censored. TCP needs no permission, but the services we build on top of it usually do: signaling servers, TURN relays, app stores, push notification gateways.

A message protocol with no version, no central registry, and no required handshake removes those points by design. You cannot block a message type you do not understand without blocking all JSON arrays, which would break everything else using the same port.

This is not about being anti-establishment. It is about making the default path not go through a third party. If you want to add a relay later, do it as an optional `Forward` message, not as a requirement.

## When you should still use connections

You're serving large files to lots of people, you aren't behind NAT, and you've measured CPU or network as a bottleneck, i.e. hosting Ubuntu ISO downloads.  The kernel is highly optimized for this, especially via sendfile().

The point is choice. Start with messages, the simplest thing that works for everyone. Simulate connections only where they help, not everywhere by default.

That is why the spec fits in one sentence, and why you can walk away from any implementation, including mine.
