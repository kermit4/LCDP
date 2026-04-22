Lowest Common Denominator Protocol tracking page

LCDP is a simple, interoperable, expansible, message oriented peer to peer protocol, allowing participants to keep only as much state about peers as     they prefer, implementing only the message types of interest, with minimal latency, and perpetual compatibility by extension not versioning, inspired by https://farcaster.xyz/vitalik.eth/0xd6b8e141 and https://medium.com/@webseanhickey/the-evolution-of-a-software-engineer-db854689243

# as seen in the wild 

## protocol 
JSON (UTF-8 encoding) array of messages.   Please make a PR into here if you spot any new fields or messages in use.  Do not change the meaning of already used messages except by adding fields.   Tolerate unrecognized messages and fields.

## message types 
### SHOULD implement
#### Send it back with any message to the node that provided it.   Currently, this is only used so no one can fake ("spoof") their source IP to use a node to spam ("flood") someone else.   Messages recieved without the correct AlwaysReturned should only be sent responses that, on average, are no more than twice the size of such messages received.  ( https://en.wikipedia.org/wiki/IP_address_spoofing )        
```JSON
{"PleaseAlwaysReturnThisMessage":["cookie","String"]
{"AlwaysReturned":               ["cookie","String"]
```
#### Peer discovery
```JSON
{"PleaseSendPeers":{}}
{"Peers":{
      "peers":[
          "148.71.89.128:43344",
          "148.71.89.128:50352"] } }
{"WhereAreThey":{"ed25519h": "hex of ed25519 sought, if found returns a MyPublicKey wrapped in a Forwarded, so you know where it came from"}}
```
#### ping -- participants might use this to prioritize which peers to keep track of and which to keep in touch with more. Send it back and forget it, as it is probably a timestamp.
```
{"PleaseReturnThisMessage":["cookie","String"]
{"ReturnedMessage":        ["cookie","String"]
```

### MAY implement
#### for larger than message sized data
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
```
#### other
```JSON
{"ChatMessage":{ "message":"hi", "length":12345} }
{"SawMessage":{ "hash": "sha256 hash of last received chat message that has been viewed (not just received, actual window focus)" 
{"YouSouldSeeThis":{ "id":"sha256", "length":12345 } }
{"IJustSawThis":{ "id":"sha256" } }
{"PleaseListContent":{}}
{"ContentList":{ "results": [ [ "hash", "size":123 ]  ] }
{"AudioFrame":{ "sampleRate": 48000, "channels": 1, "format": "'f32' or 'opus' have been seen so far", "data": "some base64" }
{"VideoFrame":{ "codec":"vp8", "keyframe": false, "seq": 123, "w": 640, "h": "480", "data": "base64.." }}
```
#### Pong (real time game)
```JSON
{"PongMove":{"ball_x":400,"ball_y":250,"move_number":1,"vx":4.7022678911042926,"vy":-1.6996107437556365}}
{"PongPaddle":{"paddle_y":320.6106870229008}}
{"PongPing":{"seq":123,"t":2345678}}
{"PongPingPong":{"seq":123,"t":2345678}}

```
#### cryptography related
```JSON
{ "EncryptedMessages": {
      "base64": "base64 of encrypted array of externally tagged JSON messagess, i.e. this protocol, encrypted",
      "noise_params": "Noise_IK_25519_AESGCM_SHA256"
    } }
{ "MyPublicKey": {
      "ed25519h": "hex (no 0x in front)",
      "ed25519_eth_signed": "optionally, a eth wallet signed message of: my ed25519 public key is 12345678abcdef"
        } }
{"GetPubByEth":{ "eth_addr": "hex of eth address you want to find the ed25519 for, if found it will return a MyPublicKey wrapped in a Forwarded so you know where it really came from"}}
{"Forwarded":{"src":"1,2.3.4:45678","from_ed25519":"only if verified","maybe_ed25519":"if not verified for this message, but from a source that claims to be this key" ,"messages":"a string that is this protocol"}}

```
### no longer in use that I'm aware of (but you should not re-use them in any incompatible way)

 SignedPub GetPub OnePlusOneMemberships TransferStatus TheseArePeers SearchResult Search PromotedContent ListResult List LastViewed HereIsContent EmptyMessage ContentPeers ContentPeerSuggestions
 
## implementations
### of the node
- https://github.com/kermit4/cjp2p-rust (implements everything listed above, and more, and by far the most developed and intelligent, so also not the simplest example to read)
- https://github.com/kermit4/cjp2p-ruby (most protocol features, not very intelligent, but much much easier to read than the more developed Rust version, even if you know Rust and not Ruby)
- https://github.com/kermit4/cjp2p-bash (most protocol features, but not intelligent, slow transfers, easy to read if you know BASH but not Rust)
- https://github.com/kermit4/cjp2p-haskell (very few features)
- There's rumors of a Go version but I haven't seen the code
### Web based interfaces to the node
 https://oneplusone.bzz.link/ - has a blank to input a different websocket URL if you dont have one running at localhost
 https://azai.net/pong.html pong with a very useful latency chart
 https://azai.net/video.html  video calls


## likely to be running nodes
- UDP 148.71.89.128:24254
- UDP 159.69.54.127:24254

# development hints:
  echo -n '[{"PleaseSendPeers":{}}]' |nc -u localhost -p 12321 24254

  tcpdump -As 9999 -i any port 24254

  You could make something useful by implimenting no more than WhereAreThey and ChatMessage, or just as examples, or only PleaseSenContent, or just WhereAreThey and AudioFrame, or only PleaseReturnThisMessage, or some new type of your own. 

The file sharing is more of a primitive than a main purpose, providing applications a way to reliably receive data of arbitrary size from many peers.

The protocol should sound more like people than computers.   Simple requests, share a lot, expect little, be tolerant -- you're talking to strangers using automation, not computers.  Prefer to leave decisions up to implementations.  It's a language for ordinary people using automation.  Everyone starts somewhere, keep it accessable to any programming skill level, with more advanced features optional (or not, it's up to you on your node and implementation).

pay attention to unhandled messages and try to handle them, or make your own -- you don't have to wait for some official protocol update to add messages or fields, just don't crash if you receive some.

Telegram group: https://t.me/lowest_common_denominator

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

# future possibilities

## protocol ideas:
- content.is_metadata, to include a list of hashes for huge files or streams that we want to verify as we go. (which could themselves do the same for really huge files)
- channels, like a stream but multiple senders, with consensus (like a blockchain or DAG)
- channels, like a stream but multiple senders, without consensus 
- economics to incentivize resource sharing
- group chats (this is actually a many to many channel without consensus)
- chat message white or black listing to avoid spam, and sharing the lists
- synchronized media playback between peers (i dont know why, it just seems fun...a shared experience, at a distance, would go well with group chats, like the 1990s when video was usually in sync)
- RecommendedContent message type?   Some people like to share!  And not just spammers.  (How to reduce that noise?i multiple sources of recommendation? end user must approve..and not Sybil. an IPv4 is valid scarcity.)
