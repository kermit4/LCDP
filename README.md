# 1. the (un)protocol

UTF-8 encoded JSON array of externally tagged messages.     Do not change the meaning of already used messages except by adding fields.   Tolerate unrecognized messages and fields.

https://datatracker.ietf.org/doc/html/draft-pearson-lcdp

# 2. non-technical (optional reading)

## summary

Lowest Common Denominator Protocol (LCDP) tracking page

LCDP is a simple, interoperable, expansible, message oriented peer to peer protocol, allowing participants to keep only as much state about peers as     they prefer, implementing only the message types of interest, with minimal latency, and perpetual compatibility by extension not versioning, Nothing to patent, copyright, gatekeep, version, or trademark.  Uncorruptable.

You're still left with one of the two hard problems of computer science -- naming things.

Telegram group: https://t.me/lowest_common_denominator

## inspired by 

- https://farcaster.xyz/vitalik.eth/0xd6b8e141  
- https://medium.com/@webseanhickey/the-evolution-of-a-software-engineer-db854689243
- https://m.youtube.com/shorts/98dQH9tKPEA
- https://knightcolumbia.org/content/protocols-not-platforms-a-technological-approach-to-free-speech
- https://www.rfc-editor.org/rfc/rfc9518.html

## elaborative essays (not required reading)

- [quick-start.md](quick-start.md)
- [english_for_the_wire.md](english_for_the_wire.md)
- [why-messages-not-connections.md](why-messages-not-connections.md)
- [agents_love_it.md](agents_love_it.md)
- [lcdp_description_for_libp2p_users.md](lcdp_description_for_libp2p_users.md)

## fun things to try

- Claude, look at pong.html and make a Atari 2600 Combat
- Claude, look at dashboard.html and make IPv4 scarcity based voting system.
- Claude, look at chat.html and make a proof-of-burn ed25519 key signer 


# 3. as seen in the wild  (suggested reading)
## message types 
### SHOULD implement
#### anti-spoof
```JSON
{"PleaseAlwaysReturnThisMessage":["cookie","String"]
{"AlwaysReturned":               ["cookie","String"]
```
Piggyback AlwaysReturned (and your own PleaseAlwaysReturnThisMessage) onto replies you are already sending for other reasons.  Never send them as a standalone reply -- that creates a ping-pong loop with no useful content.   Currently, this is only used so no one can fake ("spoof") their source IP to use a node to spam ("flood") someone else.   Messages recieved without the correct AlwaysReturned should only be sent responses that, on average, are no more than twice the size of such messages received.  ( https://en.wikipedia.org/wiki/IP_address_spoofing )        .  Or any other means you can know your response isn't multiplying traffic more than 2.5x to an unwilling recipient.    The cookie should not be predictable or reused with other peers or the point is defeated.  You could use a hash of their address and a secret to not need to save a random per peer.
### MAY implement

see the https://github.com/kermit4/LCDP/wiki and add your own.

## known implementations
### of the node
- In Rust https://github.com/kermit4/cjp2p-rust/ (by far the most developed and intelligent, so also not the simplest example to read)
- https://github.com/kermit4/cjp2p-ruby (most protocol features, not very intelligent, but much much easier to read than the more developed Rust version, even if you know Rust and not Ruby)
- https://github.com/kermit4/cjp2p-bash (most protocol features, but not intelligent, slow transfers, easy to read if you know BASH but not Rust)
- https://github.com/kermit4/cjp2p-haskell (very few features)
- There's rumors of a Go version but I haven't seen the code
### Web based interfaces to the node
- https://oneplusone.bzz.link/ - has a blank to input a different websocket URL if you dont have one running at localhost
- lots more at http://localhost:24255/latest/e13a614dff88de239a986bea20ca129c3dc77bb727fac18f2f092eed27cfb3fb/   (also at https://github.com/kermit4/LCDP_web_apps )


## likely to be running nodes
- UDP 148.71.89.128:24254
- UDP 159.69.54.127:24254

# 4. development hints

` echo -n '[{"PleaseSendPeers":{}}]' |nc -u localhost -p 12321 24254`

 `tcpdump -As 9999 -i any port 24254`

You could make something useful by implimenting no more than WhereAreThey and ChatMessage, or just as examples, or only PleaseSenContent, or just WhereAreThey and AudioFrame, or only PleaseReturnThisMessage, or some new type of your own. 


The protocol should sound more like people than computers.   Simple requests, share a lot, expect little, be tolerant -- you're talking to strangers using automation, not computers.  Prefer to leave decisions up to implementations.  It's a language for ordinary people using automation.  Everyone starts somewhere, keep it accessible to any programming skill level, with more advanced features optional (or not, it's up to you on your node and implementation).  Use long names for things, bandwidth is cheaper than explanations.

Pay attention to unhandled messages and consider implementing them. Make your own -- you don't have to wait for some official protocol update to add messages or fields, just don't crash if you receive some, post about it here or somewhere and check that no one else has used it.  The namespace is virtually unlimited.

