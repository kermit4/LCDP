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
- http://localhost:24255/latest/e13a614dff88de239a986bea20ca129c3dc77bb727fac18f2f092eed27cfb3fb/  HTML+JS interfaces I've made (pong.html has a cool latency chart and is a very good reachability test and real time demo)


## likely to be running nodes
- UDP 148.71.89.128:24254
- UDP 159.69.54.127:24254

# 4. development hints

` echo -n '[{"PleaseSendPeers":{}}]' |nc -u localhost -p 12321 24254`

 `tcpdump -As 9999 -i any port 24254`

You could make something useful by implimenting no more than WhereAreThey and ChatMessage, or just as examples, or only PleaseSenContent, or just WhereAreThey and AudioFrame, or only PleaseReturnThisMessage, or some new type of your own. 


The protocol should sound more like people than computers.   Simple requests, share a lot, expect little, be tolerant -- you're talking to strangers using automation, not computers.  Prefer to leave decisions up to implementations.  It's a language for ordinary people using automation.  Everyone starts somewhere, keep it accessible to any programming skill level, with more advanced features optional (or not, it's up to you on your node and implementation).  Use long names for things, bandwidth is cheaper than explanations.

Pay attention to unhandled messages and consider implementing them. Make your own -- you don't have to wait for some official protocol update to add messages or fields, just don't crash if you receive some, post about it here or somewhere and check that no one else has used it.  The namespace is virtually unlimited.

## test files available (under both their SHA256 hash and name, though the Rust implementation expects it to be a SHA256)
### misc
- c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b ubuntu-24.04.3-live-server-amd64.iso
- c74833a55e525b1e99e1541509c566bb3e32bdb53bf27ea3347174364a57f47c ubuntu-24.04.3-wsl-amd64.wsl
- d8b778285d0006ac17839bcded0fb9bd5dc9cbc8e869adb7b9bbea31efa8070e 1M
- 39d0e0e08bda0113b570b2486127fcfaaa18c7c47d389b9ecb27b2b863750671 2M
- e0f0b3c745acbf7631d1e98153e406045bacea2f3dc2ea310c1b82ab0c23e471 4M
- 5b6656f16181bc0689b583d02b8b8272a02049af3ba07715c4a6c08beef814c2 8M
- 7caacb04f205faf47a8d55ea7c3c6b642377b850d970f7df5233f213415829d2 16M
- 24349fedc2836f75e58b199c748e6fb1808136bb8ab9f618a264c64ce735fa5b 32M
- 35fd7b1f88666d3156d32fa89b0bb0930b3a8eb86dd711d0fe277f45b465791f 64M
- e1c4691d6cc8f2638250127beaadeb1b3d041c6ba877cfb5e551bb9da2f63303 128M
- cb407d7355bb63929d7f4b282684f5a2884a0c3fb73d56642455600569a6888b 256M
- 6f5a06b0a8b83d66583a319bfa104393f5e52d2c017437a1b425e9275576500c 512M
- c7dce40a2af023d2ab7d4bc26fac78cba7f7cb7854f67f9fb5bf72b14d9931d8 1024M
- 8e008973582673665a326cc44c681c11d9d39ec61dd529f3c1aa26695f4880e7 0x10001 bytes (one byte more than 64k)

- a40e24319477590fdcad751a76dca92e542f0134f6dd93582decd1557d2676ad  1024 sha256sums of each 256k block of 256M, which are separately downloadable
- 562b168a64967fd64687664b987dd1c50c36d1532449bb4c385d683538c0bf03  2048 sha256sums of each 256k block of 512M, which are separately downloadable

### public domain movies
- bb47bad04897a638cb0127ebb40dfeb1e01fa041a836597e96aaf163b9b618fc  NightOfTheLivingDead720p1968.mp4
- fb2d386f529c2c6a25de279529166ac90bcaad91eb0a819a6efeedb98e0f0062  Night_of_the_Living_Dead_AVI.mp4
- 93b40590e45b1d7e1f7b54f69c96f29707e23100a1cc82af0313525060e2d86a  reefer_madness1938.mp4
- 3d5486b9e4dcd259689ebfd0563679990a4cf45cf83b7b7b5e99de5a46b5d46f 269M abe_lincoln_of_the_4th_ave.mp4 
- 43a39a05ce426151da3c706ab570932b550065ab4f9e521bb87615f841517cf1 101M  sintel.mp4 -- modern Blender flic.  
- 62c51ca281f7113e429625ac44c14f27c4d73c0fd03bfb47403f8cd85b3c858f 303M  house_on_haunted_hill.mp4

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
