yeah like many-to-many VPNs, plus peer discovery and flexible amount of state keeping to support millions of peers, not all-or-nothing like "connections", and no artificial in-kernel latency if a packet is lost.  (pro-tip: keep more state about the ones you expect to talk to more).    also stateless 1RTT (or even 0.5 )  for many common cases.

also, unrelated to the many-to-many theme,  I'm also going with a very simple approachable expansible protocol (JSON) and various optional messages, and no versioning, just make a new kind of message if its incompatible (not just expanded), as I don't expect JSON to chang.. it  leaves as much as possible at the discretion of each implementation.   I wrote 3 so far, (BASH,Ruby,Rust).

(specifically, an array of externally tagged JSON objects..that's the only specification, everything else is optional, even the peer discovery)

un-protocol

my first thought after reading https://farcaster.xyz/vitalik.eth/0xd6b8e141  was  "whats the dumbest wire protocol i can come up with, with the least implementation requirements" .. lowest "barrier to entry"  for developers, and no gatekeeping, inherent compatibility by design (just dont make a message thats incompatible with one of the same name that youve seen.. you can expand on it, i.e. adding fields., expansibility by collaboration not proposals and specifications.

the specs came *after* people were doing a thing ("as seen in the wild"), back in the original decentralized days before the internet turned into apps...even the most popular "decentralized" apps today are centrally controlled. thats not organic.


VERSIONING
I don't expect JSON to change.  Any changes to messages should be downwardly compatible, so you can add fields but don't change the meaning of existing ones.  Make a  new  message for that.

UDP isn't really part of the protocol, you could print it on paper airplanes and throw it around a park for anyone cares. 

what is a connection..a simulation built on messages, created mainly by introducing artificial latency, which people then go make message oriented protocols on top of


you're free to simulate connectinos on top, just like you might be used to, you just dont need to wind up speaking a message oriented protocol over simulated connections over message oriented protocols

you can put ethereum, bitcoin, whatever over it

conn.ctions are built on messages.  apps should have tte option to use either, rathec than be forced to sesh messaces over connections (that are a series of messaces themselves)

tcp  is abstracted connections.. you courd do that here if you want.  i just dont recommend forcing it.

connections are abstractions over messages, to abstracc messacel over connections that are abstracted over messages is silly

if you have a desire for absracted "connections", you could do that over this, rather than the other way around being stuck using connections when you're just trying to send messages

a baseline protocol everyone can build on, minimal requiremnets (an array of externally tagged JSON messages, thats all!), to reduce siloing and fragmentation of decentralized (p2p) applications.  maybe your app cares about getting BLOBS and encryption, or another cares about soethnig else, but identiy can be shared, peer lists can be common, much overlap, interopeability


a bridge..we've mostly agreed on IP, and mostly on UDP or TCP, and some 1:1 protocols like http and DNS, but for many to many, it gets very fragmented fast.  this is meant to be a layer between UDP and many to many applications, a common language (JSON), and also connection oriented as desired not imposed, as many p2p cases applications are sending messages not streams, so sending them over streams adds undesired complexity


when it says unreliable in this case it doesn't mean that in a negative way what
it means is that the operating system isn't going to delay or lose messages when a previous message has not been received.  I prefer that the application receive messages as soon as they arrive and not be deliberately lost simply because others were accidentally lost. a developed application will always deal with reconnections which is the same as dealing with retransmissions and timeouts and the developed application will be able to handle messages in an orderly fashion even if they are not received in order anyway so allowing the operating system to continue to do that duplicates that that work and just creates lag and extra messages lost. 


an application, when it is going to wind up handling reconnections (packet loss at a larger time scale) anyway, might as well benefit from not having the artifical latency introduced by OS level ordering, when it doesnt want it, nor have to have more state overhead than it has a use for, when its probably already also keeping track of ordering, where desired, anyway.  further, an app should have the flexbiiltiy to keep as much or little state about peers as it wants to have some state about millions, and 0RTT messaging with them, without maintaining connection overhead.

, showing how you can A) use JSON as your base protocol to maintain future compatibility and be easily approachable to new implementations, and B) how you can send messages directly without relays or connections, rather than messages relayed around a web of connections that are abstracted on top of messages, as is oddly commonplace in p2p networking, probably out of habbit from 1:1 server/clientt application design.  However this code is functional, at various things, just not the best at any 1 of them, but interoperability instead of lots of siloed p2p apps is the benefit.



messages on top of connections simulated over messages is more silly than just connections simulated over messages (should you even want connections for some reason)


in most cases, i dont want messages artificially delayed by the operating system
