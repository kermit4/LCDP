# 1. non-technical (optional reading)

## summary

Lowest Common Denominator Protocol (LCDP) tracking page

LCDP is a simple, interoperable, expansible, message oriented peer to peer protocol, allowing participants to keep only as much state about peers as     they prefer, implementing only the message types of interest, with minimal latency, and perpetual compatibility by extension not versioning, 

You're still left with one of the two hard problems of computer science -- naming things.

Telegram group: https://t.me/lowest_common_denominator

## inspired by 

- https://farcaster.xyz/vitalik.eth/0xd6b8e141  
- https://medium.com/@webseanhickey/the-evolution-of-a-software-engineer-db854689243
- https://m.youtube.com/shorts/98dQH9tKPEA
- https://knightcolumbia.org/content/protocols-not-platforms-a-technological-approach-to-free-speech
- https://www.rfc-editor.org/rfc/rfc9518.html

## elaborative essays (not required reading)

AI written, hypey but smoother to read than i'd have done it

- [english_for_the_wire.md](english_for_the_wire.md)
- [why-messages-not-connections.md](why-messages-not-connections.md)
- [lcdp_description_for_libp2p_users.md](lcdp_description_for_libp2p_users.md)
- [quick-start.md](quick-start.md)

## fun things to try

- Claude, look at pong.html and make a Atari 2600 Combat
- Claude, look at dashboard.html and make IPv4 scarcity based voting system.
- Claude, look at chat.html and make a proof-of-burn ed25519 key signer 

# 2. protocol  (required reading)
UTF-8 encoded JSON array of externally tagged messages.     Do not change the meaning of already used messages except by adding fields.   Tolerate unrecognized messages and fields.


# 3. as seen in the wild  (suggested reading)
## message types 
### SHOULD implement
#### anti-spoof
```JSON
{"PleaseAlwaysReturnThisMessage":["cookie","String"]
{"AlwaysReturned":               ["cookie","String"]
```
Send it back with any message to the node that provided it (but not just by itself, that's not the purpose).   Currently, this is only used so no one can fake ("spoof") their source IP to use a node to spam ("flood") someone else.   Messages recieved without the correct AlwaysReturned should only be sent responses that, on average, are no more than twice the size of such messages received.  ( https://en.wikipedia.org/wiki/IP_address_spoofing )        .  Or any other means you can know your response isn't multiplying traffic more than 2.5x to an unwilling recipient.
### MAY implement

see the https://github.com/kermit4/LCDP/wiki and add your own.

## implementations
### of the node
- In Rust https://github.com/kermit4/cjp2p-rust/ (by far the most developed and intelligent, so also not the simplest example to read)
- https://github.com/kermit4/cjp2p-ruby (most protocol features, not very intelligent, but much much easier to read than the more developed Rust version, even if you know Rust and not Ruby)
- https://github.com/kermit4/cjp2p-bash (most protocol features, but not intelligent, slow transfers, easy to read if you know BASH but not Rust)
- https://github.com/kermit4/cjp2p-haskell (very few features)
- There's rumors of a Go version but I haven't seen the code
### Web based interfaces to the node
- https://oneplusone.bzz.link/ - has a blank to input a different websocket URL if you dont have one running at localhost
- lots more at http://localhost:24255/latest/e13a614dff88de239a986bea20ca129c3dc77bb727fac18f2f092eed27cfb3fb/  


## likely to be running nodes
- UDP 148.71.89.128:24254
- UDP 159.69.54.127:24254

# 4. development hints

` echo -n '[{"PleaseSendPeers":{}}]' |nc -u localhost -p 12321 24254`

 `tcpdump -As 9999 -i any port 24254`

You could make something useful by implimenting no more than WhereAreThey and ChatMessage, or just as examples, or only PleaseSenContent, or just WhereAreThey and AudioFrame, or only PleaseReturnThisMessage, or some new type of your own. 


The protocol should sound more like people than computers.   Simple requests, share a lot, expect little, be tolerant -- you're talking to strangers using automation, not computers.  Prefer to leave decisions up to implementations.  It's a language for ordinary people using automation.  Everyone starts somewhere, keep it accessible to any programming skill level, with more advanced features optional (or not, it's up to you on your node and implementation).  Use long names for things, bandwidth is cheaper than explanations.

Pay attention to unhandled messages and consider implementing them. Make your own -- you don't have to wait for some official protocol update to add messages or fields, just don't crash if you receive some, post about it here or somewhere and check that no one else has used it.  The namespace is virtually unlimited.

# 5. future ideas

## protocol ideas:
- metadata
- a list of hashes for very large files (including metadata)
- a generic path for huge messages to turn into Content
- channels, like a stream but multiple senders, with consensus (like a blockchain or DAG)
- channels, like a stream but multiple senders, without consensus 
- economics to incentivize resource sharing
- chat message white or black listing to avoid spam, and sharing the lists
- synchronized media playback between peers (i dont know why, it just seems fun...a shared experience, at a distance, would go well with group chats, like the 1990s when video was usually in sync)
- many more ideas in https://github.com/kermit4/cjp2p-rust 
- make a IETF draft https://datatracker.ietf.org/submit/tool-instructions/
- needs real ai quickstart make game or toy
