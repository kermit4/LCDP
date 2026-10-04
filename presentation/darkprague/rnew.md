https://speak.darkprague.com/dp26/talk/GVWRU9/

- "We should have made a protocol spec not just an app.  " -- Max Hillebrand 

pull/push things to/from README/ .md files?

Starting programming on a C64 and Linux since 1996, I've always had a focus on the network side, security and protocols, and particularly appreciate the value of P2P protocols as censorship resistance is democracy is liberty, without it whoever controls the narrative controls the votes.


**HOST: Isn't JSON wasteful? Base64?**
You: In 2005, yes. In 2026 I saturate gigabit on a $50 ARM board parsing JSON. Bandwidth is cheaper than explanations. When bottlenecks move, optimizations must move.

**HOST: Last question — people will say 'this isn't new.' Why hasn't it happened?**
You: Because we optimized for the wrong scarcity. For decades it was CPU, then bandwidth, then disk. Now we're post-scarcity on hardware.
Todays' bottleneck is you.  Telling Claude what to build.  LCDP is optimized for *human understanding*, not hardware bottlenecks of the past.
Decentralization helps everyone, including me, because I want to communicate without a third party deciding what I can say. Structural censorship happens when every path goes through a landlord. This makes the default path direct.

- Say "messages, not connections" slowly, 3 times total

qr code to whole presentation and my contact info

ehtereum did that with smart contrats, polkadot and JAM do that, http did it best.  


i have a dream of various levels of optional interopability between decentralized apps, a common language, and plain text so human and AI readable directly.

funny slides?  somehow

cover rfc and past decentralization if I use re-decentralization term.   the path to re-decentralization is not making yet another protocol.   ...    so I made another protocol.
We are happy to tell you that we accept your proposal "Lowest Common Denominator Protocol"
to DARK PRAGUE 2026. Please click this link to confirm your attendance:
Please contact us if you have any questions! We will reach out again before the conference to tell you the details about your slot in the schedule and technical details concerning the room and presentation tech.

need slide showing layers, how this is much closer to IP than other things

=== already submitted
Proposal title: Lowest Common Denominator Protocol

Abstract: A general purpose peer to peer protocol for 2026, AI friendly, dual-NAT capable. Federated is not anti-fragile to political pressures. Not all NAT is uncooperative, but it's getting worse. Lets work together to keep P2P alive.

https://github.com/kermit4/LCDP


=== end already submitted



be sure to have pauses and jokes


start with the usual progression..opening connections so we dont have to deal with blah blah right now and just want to get to the fun parts

but then as it evolves we wind up having to anyway and now we have lost cotrol, more overhead, limited connections, built on an scalable model, then proceed with workarounds like relaying messages, forgetting that we only got here to avoid exaclty the problems we're dealing with in a more developed application, but now its harder to change the design, so its complexity and latency and overhead for nothing gained in the long run

well if i want to look cool, i need a description thatwattracts people to my talk
xlr analogy

be funny

stick to the concept, dont get into the app at all

they will want to contrast to libp2p

i can talk aboet anyntig, so p2p and routers and cenship creep of no p2p..fight for it.  see ai notes.

mention the ipv6 rfc and issue

remembec you cant delete it

put more notes on the dark pragee page of what i will talk abaut, current description will attrack libp2p people wmichh i dont want  

talk about stopping war, first step is to be able to communinate without silos

talk about enabling people to make apps easily and interoperably, cite the DAW


yeah its important to not confuse message type we've made with the protocol itself which does not dictate any specific messages.

I have a new analogy, do you know those XLR cables in pro-audio?  did you know that spec doesn't mention anything about electricity?  no voltage, no amps, no resistance specs.  not even cabling. its entirely just a connector spec.  just a plug.   

and with it, people have done not just audio, but power, lightinging, all kinds of unexpected things over it.


dark prague themed a bit, privacy, local first, self hosted.

And I just learned today that a common ISP in town gives you a router that is behind NAT, which itself does NAT for your LAN, so double NAT.    IP will be like money soon, fully permissioned for each message.

cite the ipv6 RFC

why not encryption by default..because encryption protocols change, are complex, this is more of a transport, but inside whatever encryptedMessage, stick to the same structure so you just unwrap it and continue in the same style.. and some messages are meant to be public anyway


**HOST: You wrote a quick-start with 'three paths, no wrong door.' Can we actually see how simple?**


You: Path 1 — use a node as your post office. Perfect for web devs.


You get back `[{"Peers":{"peers":["..."]}}]`. You just spoke p2p from bash.

[pause 2s]

Path 2 — speak the wire directly. That's the Python code on screen. 20 lines. Implements peer discovery, chat, anti-spoof. Add your own `{"MyAppPing":{}}` and old nodes ignore it.

**HOST: Wait, they just ignore unknown messages?**

You: Yes. That's the compatibility rule: tolerate what you don't understand, never change meaning of existing fields, only add. No versions. Ever.

[pause]


images:
pdf ===  print the README really? get slides in the readme.  can just use big fonts for text.
    qr code to github at beginning and end of readme


IP, HTTP, and smart contracts are successful because they don't define the subject,  "We love generic layers - IP didn't say what packets mean, Ethereum said 'bring your own contract', JAM says 'bring your own service, here's a RISC-V'. LCDP is same impulse: bring your own message."


slides showing room inserted below approachse not competing with, with generics on top not to propose inserting them into existing things, though they could..but looking ahead, yet not incompatible, show visually some connectiviity to the, like identity, idk what else?
Don't standardize the signal. Standardize the socket.*
more of an envelope than a protocol.  no versions
> "IP didn't say what packets mean. Smart contracts didn't say what code you run. JAM doesn't say what service you run - it's a RISC-V VM, bring your own. That's the pattern. LCDP is that for messages: `[{...}]`. Parking spot doesn't care if it's a Tesla or bike, as long as it fits. But parking lots are useful because they exist."

this is a suggestion to use JSON over message orientted protocls. give spec. thank you, start walking away.

- headphone jack, mention square used this because its an open spec, we need a general purpose open spec for the internet, paper envelope, smart contracts, JAM, CPUs
there are too many competing standards, so i came up with one universal standard that covers everyone's use cases.  .. https://xkcd.com/927/
- JAM hat tip: in the generic examples slide. "IP, smart contracts, JAM - all said 'bring your own logic, we provide the socket'. Same impulse." Gavin hears his work respected, not attacked. Audience sees pattern.

cite specific parts of the cool rfc, the internet used to be decentralized. we made protocols not apps.  like a web browser, and email, are succesful decentralized protocols.  though both are still server/client protocols.

1gbps of json on 10 year old cpu.    rca cables have been used to..xlr has been used to..    update desription with who shourd lines?

slide must be xlr rca what else?  coaxial?

just making the foundation a little higher than 50 year old protocols


"Anyone who ... raise their hand" or "can I get a show of hands..." (Raise yours)

"....right? (Pause)" Or "who's had that..."    Like a mini show of hands without hands, do a lifting motion with one or two hands.

A joke...when they're paying attention though.  Pause, make a noise, something first to get it, then the joke.

very small pauses like 500ms and talking a tiny bit slower may have helped absorption



