# LCDP Interview Script — Uncloud Conference
**Duration: 25 minutes | Format: Interview | Speaker: you | Host: Organizer**

> Use this as your script. Host reads **bold questions**. You read normal text. Timestamps are cumulative. If you're behind, skip to the next [JUMP POINT].

---

## Pre-talk checklist (do now)
- Put these 5 images on USB as `slide1.png` through `slide5.png` (screenshots from your repo):
  1. `quick-start.md` Path 1 code block
  2. Python 20-line example from `quick-start.md`
  3. `tcpdump -A` showing `{"ChatMessage":{"message":"hi"}}`
  4. README message list (the JSON examples)
  5. https://azai.net/video.html working (or screenshot)
- If no projector: that's fine. Every slide has a "no-screen fallback" line you can say instead.
- Bring: laptop with `nc -u` and ruby node running on localhost:24254

---

## 15:00 - 17:00 Opening — Why we're here

**HOST: Okay, so you've built something called LCDP. I keep calling it the 'lowest common denominator protocol' — that sounds like an insult. What is it actually?**

You: [smile] It's exactly what it sounds like, but as a compliment. It's the dumbest wire protocol I could come up with that still works.

[pause 2s]

It's just UTF-8 JSON arrays of tagged messages sent over UDP. That's the whole spec. One sentence.

`[{"ChatMessage":{"message":"hi"}}]`

That's it. No version numbers, no handshake, no central server.

**[SLIDE 1: show the one-sentence spec]**
*No-screen fallback:* "Imagine sending a text message, but the text is JSON, and you throw it directly at another computer's IP."

**HOST: And you wrote this because...?**

You: Because every time someone asks "how do I make a p2p app without a cloud," we hand them WebRTC, which needs signaling servers, STUN, TURN, SDP... and they give up. I wanted something an AI could write in one prompt, and a human could debug with tcpdump.

[pause]

The goal isn't to be efficient. It's to be *possible* for anyone.

---

## 17:00 - 20:30 The problem with connections [JUMP POINT 1]

**HOST: You have this essay 'why messages, not connections.' Most of us only know TCP, like, websites. Why is that wrong for p2p?**

You: Connections were a hack from the 1970s to save developers from writing retransmission code. CPUs were slow, memory was kilobytes.

[pause]

Today, we all reimplement that stuff at the app layer anyway. Video calls reorder frames. Games ignore old packets. Chat apps store-and-forward.

**[SLIDE 2: show tcpdump -A output]**
*Fallback:* "Run `tcpdump -A port 24254` and you literally read `ChatMessage hi` in plain English."

You: But TCP gives you head-of-line blocking. One lost packet, and the kernel holds *everything* behind it. For real-time, that's latency you added to yourself.

With messages over UDP, you choose. Keep state for the 5 peers you're video calling. Keep just an IP for the other 9,995. Send one datagram to a stranger with no handshake — 0.5 RTT.

[pause 3s]

**HOST: So you're saying we built connections on top of messages, then we build messages on top of connections...?**

You: Exactly. It's messages all the way down. I'm just suggesting we stop pretending.

It's like QWERTY. We use it because we always have, not because it's optimal.

---

## 20:30 - 24:00 NAT without a landlord

**HOST: Okay, but my home router — NAT. I thought you *need* a server to punch through?**

You: Roughly, NAT is your router rewriting your address so many devices share one public IP. The trick is, if *both* sides send UDP at the same time, most routers open the hole.

You don't need a landlord. You need coordination.

**[SLIDE 3: Python 20 lines]**
*Fallback:* read the code slowly

```python
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind(("0.0.0.0", 24254))
# send from same socket you listen on
s.sendto(json.dumps([{"PleaseSendPeers":{}}]).encode(), peer)
```

You: That's the whole NAT traversal. Send from the same socket you listen on. No STUN server.

The `PleaseAlwaysReturnThisMessage` / `AlwaysReturned` pair is just an anti-spoof cookie, like HTTP cookies. Stops someone faking their IP to make you spam others.

[pause]

**HOST: So no central relay?**

You: None required. I run two bootstrap nodes at 148.71.89.128:24254 just to help you find first friends. If they disappear tomorrow, your node still talks to anyone whose IP you know. That's the walkaway test.

---

## 24:00 - 29:00 Three ways in — demo territory [JUMP POINT 2]

**HOST: You wrote a quick-start with 'three paths, no wrong door.' Can we actually see how simple?**

You: Path 1 — use a node as your post office. Perfect for web devs.

[demo or describe]
`echo -n '[{"PleaseSendPeers":{}}]' | nc -u 127.0.0.1 24254`

You get back `[{"Peers":{"peers":["..."]}}]`. You just spoke p2p from bash.

[pause 2s]

Path 2 — speak the wire directly. That's the Python code on screen. 20 lines. Implements peer discovery, chat, anti-spoof. Add your own `{"MyAppPing":{}}` and old nodes ignore it.

**HOST: Wait, they just ignore unknown messages?**

You: Yes. That's the compatibility rule: tolerate what you don't understand, never change meaning of existing fields, only add. No versions. Ever.

[pause]

Path 3 — browser bridge. Browsers can't do raw UDP, so you run a 30-line WebSocket-to-UDP bridge locally. The page at azai.net/video.html doesn't touch my server for video — it goes browser -> your localhost -> directly to peer.

**[SLIDE 4: screenshot of video call working]**
*Fallback:* "I have a video call running right now that's pure p2p, no TURN server."

**HOST: And AI can write this?**

You: I literally pasted the README into Claude and said 'make a chat client.' It did Path 2 in one shot. The bottleneck in 2026 isn't CPU or bandwidth — it's developer time. JSON is readable, so AI gets it right.

---

## 29:00 - 33:00 Interoperability, not apps

**HOST: You're at an uncloud conference. People here hate silos. How does this help?**

You: We keep naming protocols after apps — 'the BitTorrent protocol,' 'the SSB protocol.' That killed decentralization since 2000.

LCDP is a *baseline*. You implement `WhereAreThey` and `ChatMessage`, you have a messenger. Someone else implements only `PleaseSendContent`, they have file sharing. Both share peer lists, both use the same identity keys (ed25519).

[pause]

You don't need my permission. Make a new message type. Post it on the wiki. If someone else already used that name, pick another. It's like English — you can invent words.

**HOST: Isn't JSON wasteful? Base64?**

You: In 2005, yes. In 2026 I saturate gigabit on a $50 ARM board parsing JSON. Bandwidth is cheaper than explanations. When bottlenecks move, optimizations must move.

The real cost is people not shipping because the spec is 80 pages of binary.

---

## 33:00 - 37:00 What you can build tonight

**HOST: Give the audience something concrete. What could a non-developer do with this?**

You: Three ideas:

1. **Ping mesh.** Implement only `PleaseReturnThisMessage`. You now have latency to thousands of peers, no connections.
2. **Family chat.** `ChatMessage` + `SawMessage`. Runs on a Raspberry Pi behind NAT.
3. **Your own thing.** A game? Send `{"PongMove":{...}}`. Old nodes forward it, ignore it, doesn't matter.

[pause 3s]

The Rust node does everything. The Ruby node is 300 lines and readable. The Bash node proves you don't need a compiler.

**HOST: And if you disappear?**

You: I wrote it so I can disappear. No registry, no API key, no update server. The spec is 'send JSON arrays.' That's it. Credit appreciated, maintenance not expected.

---

## 37:00 - 39:30 Why now

**HOST: Last question — people will say 'this isn't new.' Why hasn't it happened?**

You: Because we optimized for the wrong scarcity. For decades it was CPU, then bandwidth, then disk. Now we're post-scarcity on hardware.

[pause]

The bottleneck is you. Telling Claude what to build. LCDP is optimized for *human understanding*, not machines.

Decentralization helps everyone, including me, because I want to communicate without a third party deciding what I can say. Structural censorship happens when every path goes through a landlord. This makes the default path direct.

---

## 39:30 - 40:00 Close

**HOST: Where do people start?**

You: github.com/kermit4/LCDP — read quick-start.md, pick a path. Join t.me/lowest_common_denominator. Bring a weird message type.

[pause]

And if you build something, don't ask me to maintain it. That's the point.

**HOST: Thank you.**

[applause]

---

## Timing guide for you
- 0-5 min: story + problem (slow down, this is new)
- 5-14 min: NAT + demo (if demo fails, just read the Python — it's fine)
- 14-22 min: interoperability (this is what excites the organizer, linger here)
- If at 33:00 you're behind: skip the 'three ideas' list, jump to 'Why now'
- If at 25:00 you're ahead: do live `nc -u` demo twice, let audience shout a message

## Speaker notes — pauses and tone
- Say "messages, not connections" slowly, 3 times total
- When showing code, count lines out loud: "twenty lines"
- Emphasize "walkaway test" — organizers love that phrase
- Don't apologize for JSON being inefficient. Say "bandwidth is cheaper than explanations" with confidence
- If nervous: look at host, not audience. It's an interview

## No-slides emergency mode
If USB fails:
1. Open terminal, run `ruby node.rb` in background
2. `echo -n '[{"PleaseSendPeers":{}}]' | nc -u 127.0.0.1 24254`
3. Read the Python from quick-start.md aloud
4. Describe video.html verbally
That's enough. The simplicity *is* the demo.
