CJP2P - Connectionless JSON P2P Protocol

A connectionless, simple, interoperable, expansible, p2p protocol, for building message oriented,        not connection oriented, p2p (peer-to-peer)                 applications keeping only as much state about peers as     you prefer, implementing as much or as little as you like, and without relaying messages due to           connection limits, or suffering artificial latencies, with perpetual compatibility by extension instead of breaking changes, inspired by https://farcaster.xyz/vitalik.eth/0xd6b8e141 and https://medium.com/@webseanhickey/the-evolution-of-a-software-engineer-db854689243


# as seen in the wild 


## protocol 
JSON array of messages.   Please make a PR into here if you spot any new fields or messages.

## message types 
### SHOULD implement
#### Send it back with any message to the node that provided it.   Currently, this is only used so no one can fake ("spoof") their source IP to use a node to spam ("flood") someone else.   Without it, you'll receive less, or smaller, replies from most peers.  ( https://en.wikipedia.org/wiki/IP_address_spoofing )        
```JSON
{"PleaseAlwaysReturnThisMessage":["any",{"valid":"JSON"},2,"x"]}
{"AlwaysReturned":               ["any",{"valid":"JSON"},2,"x"]}  
```
#### Peer discovery
```JSON
{"PleaseSendPeers":{}}
{"Peers":{
      "peers":[
          "148.71.89.128:43344",
          "148.71.89.128:50352"] } }

```
#### Probably just used to see how far away, or how lagged, a peer is in time.  Only return once, then forget it.
```

{"PleaseReturnThisMessage":["any",{"valid":"JSON"}]}
{"ReturnedMessage":        ["any",{"valid":"JSON"}]}  
```

### MAY implement
#### a basic use. EOF refers to the full completed length of the content.  
```JSON
{"PleaseSendContent":{
      "id":"8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4",
      "length":4096,
      "offset":0 }}
{ "Content": { 
      "id":"8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4",
      "base64": "aGk=",
      "eof": 2,           
      "offset":0 } }
{"MaybeTheyHaveSome":{
       "id":"foo",
      "peers":[ "148.71.89.128:43344", "148.71.89.128:50352"] } }
#### A simple example for now -- show the user the message, until the spam comes then filter them somehow.
{"ChatMessage":{
       "message":"hi",
       } }
#### cryptography related
{ "EncryptedMessages": {
      "base64": "base64 of encrypted array of externally tagged JSON messagess, i.e. this protocol, just encrypted",
      "noise_params": "Noise_NK_25519_ChaChaPoly_SHA2567"
    } }
{ "MyPublicKey": {
      "ed25519": "in base64"
        } }

```

## implementations
- https://github.com/kermit4/cjp2p-rust (implements everything listed above and far the most developed and intelligent)
- https://github.com/kermit4/cjp2p-ruby (most protocol features, not very intelligent, but much much easier to read than the more developed Rust version, even if you know Rust and not Ruby)
- https://github.com/kermit4/cjp2p-bash (most protocol features, but not intelligent, slow transfers, easy to read if you know BASH but not Rust)
- https://github.com/kermit4/cjp2p-haskell (very few features)

## likely to be running nodes
- UDP 148.71.89.128:24254
- UDP 159.69.54.127:24254

# development hints:
  echo -n '[{"PleaseSendPeers":{}}]' |nc -u localhost -p 12321 24254

  tcpdump -As 9999 -i any port 24254

The file sharing is more of a primitive than a main purpose, providing applications a way to reliably receive data of arbitrary size from many peers.

The protocol should sound more like people than computers.   Simple requests, share a lot, expect little, be tolerant -- you're talking to strangers using automation, not computers.  Prefer to leave decisions up to implementations.  It's a language for ordinary people using automation.  Everyone starts somewhere, keep it accessable to any programming skill level, with more advanced features optional (or not, it's up to you on your node and implementation).

pay attention to unhandled messages and try to handle them, or make your own -- you don't have to wait for some official protocol update to add messages or fields, just don't crash if you receive some.

Telegram group: https://t.me/cjp2p

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
- 3d5486b9e4dcd259689ebfd0563679990a4cf45cf83b7b7b5e99de5a46b5d46f  abe_lincoln_of_the_4th_ave.mp4
- 93b40590e45b1d7e1f7b54f69c96f29707e23100a1cc82af0313525060e2d86a  reefer_madness1938.mp4
- 3d5486b9e4dcd259689ebfd0563679990a4cf45cf83b7b7b5e99de5a46b5d46f 269M abe_lincoln_of_the_4th_ave.mp4 
- 43a39a05ce426151da3c706ab570932b550065ab4f9e521bb87615f841517cf1 101M  sintel.mp4
- 62c51ca281f7113e429625ac44c14f27c4d73c0fd03bfb47403f8cd85b3c858f 303M  house_on_haunted_hill.mp4

# future possibilities

## protocol ideas:
- content.is_metadata, to include a list of hashes for huge files or streams that we want to verify as we go. (which could themselves do the same for really huge files)
- channels, like a stream but multiple senders, with consensus (like a blockchain or DAG)
- channels, like a stream but multiple senders, without consensus 
- encryption something like MyTemporaryPublicKey{e25519:"in base64"}      EncryptedMessages{base64:"some base64 that decrypts to an array of JSON messages"}
- economics to incentivize resource sharing
- group chats (this is actually a many to many channel without consensus)
- proximity chat (by latency)
- chat message white or black listing to avoid spam, and sharing the lists
- synchronized media playback between peers (i dont know why, it just seems fun...a shared experience, at a distance, would go well with group chats, like the 1990s when video was usually in sync)
- RecommendedContent message type?   Some people like to share!  And not just spammers.  (How to reduce that noise?i multiple sources of recommendation? end user must approve..and not Sybil. an IPv4 is valid scarcity.)
