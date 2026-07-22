i belive the focus on connections is nothing more than habbit, like qwerty... who here uses qwerty?  of those, who use werty because you researched the available layouts available on the platfroms you commonly use and decided it was the optimal one for your regular use?  (hint: its probably not)

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

connections are built on messages.  apps should have tte option to use either, rathec than be forced to sesh messaces over connections (that are a series of messaces themselves)

tcp  is abstracted connections.. you courd do that here if you want.  i just dont recommend forcing it.

connections are abstractions over messages, to abstracc messacel over connections that are abstracted over messages is silly

if you have a desire for absracted "connections", you could do that over this, rather than the other way around being stuck using connections when you're just trying to send messages

a baseline protocol everyone can build on, minimal requiremnets (an array of externally tagged JSON messages, thats all!), to reduce siloing and fragmentation of decentralized (p2p) applications.  maybe your app cares about getting BLOBS and encryption, or another cares about soethnig else, but identiy can be shared, peer lists can be common, much overlap, interopeability


a bridge..we've mostly agreed on IP, and mostly on UDP or TCP, and some 1:1 protocols like http and DNS, but for many to many, it gets very fragmented fast.  this is meant to be a layer between UDP and many to many applications, a common language (JSON), and also connection oriented as desired not imposed, as many p2p cases applications are sending messages not streams, so sending them over streams adds undesired complexity


when wikipedia says unreliable in this case it doesn't mean that in a negative way what

it means is that the operating system isn't going to delay or lose messages when a previous message has not been received.  I prefer that the application receive messages as soon as they arrive and not be deliberately lost simply because others were accidentally lost. a developed application will always deal with reconnections which is the same as dealing with retransmissions and timeouts and the developed application will be able to handle messages in an orderly fashion even if they are not received in order anyway so allowing the operating system to continue to do that duplicates that that work and just creates lag and extra messages lost. 


an application, when it is going to wind up handling reconnections (packet loss at a larger time scale) anyway, might as well benefit from not having the artifical latency introduced by OS level ordering, when it doesnt want it, nor have to have more state overhead than it has a use for, when its probably already also keeping track of ordering, where desired, anyway.  further, an app should have the flexbiiltiy to keep as much or little state about peers as it wants to have some state about millions, and 0RTT messaging with them, without maintaining connection overhead.

, showing how you can A) use JSON as your base protocol to maintain future compatibility and be easily approachable to new implementations, and B) how you can send messages directly without relays or connections, rather than messages relayed around a web of connections that are abstracted on top of messages, as is oddly commonplace in p2p networking, probably out of habbit from 1:1 server/clientt application design.  However this code is functional, at various things, just not the best at any 1 of them, but interoperability instead of lots of siloed p2p apps is the benefit.



messages on top of connections simulated over messages is more silly than just connections simulated over messages (should you even want connections for some reason)


in most cases, i dont want messages artificially delayed by the operating system


immutiable sets of specs, you can add but not alter


keep cash not need permissisen to buy food..thats extraordinarily dystopian.  licensed protocols like hdmi  and  bluetooh and even use headset jack.


my motivation.. it is self serving, because decentralization helps everyone, it empowers me to communicate without a third party choosing what i can communicate, and that is important to me

English for the wire
LCDP is a shorter way to say UTF-8 encoded JSON arrays of externally tagged values intended for inter-party communication.  IP in JSON 

need biggger stay
slides on xiamoi stick MAKE SURE PORN DOESNT POP UP or a bunch of pirated stuff

structural censorship, once you see it you see it everywhere.

You could make something useful by implimenting no more than WhereAreThey and ChatMessage, or some other program  only PleaseSendContent, or another just WhereAreThey and AudioFrame, or even only PleaseReturnThisMessage (like a ping) or some new type of your own.


nice history of unix video, working within the constraits


historically cpus or networks were bottlenecks, or development time..none of that really is now, so we can have a simple protocol thats not the most cpu or network efficient, as i was able to process 1gbps of JSON on a $50 laptop with using core.




kermit:
JSON is like IP but readable data, just base64 anything.

i should give some perspective, its not that i'm the first person to think of anything exactly its that bottlenecks change over time in computing..some years its networks, some years its cpus, some years its engineers.  it would not have made sense to base64 encode large data over wordy formats that take lots of CPU processing and excess network bandwidth in many decades.  in this decade, none of that is the bottleneck.  its developer time, or now actually claude time.  clear data formats trump efficient cpu/network in 2026.      LCDP would not have made sense  2005 or 1995 or 1985 or maybe even 2015.

decades ago TCP also saved a LOT of coding effort, and CPU, and card bus I/O.  now its so easy and everyone's duplicating all that app level anyway.

so the shifting bottlenecks make now the right time to do things this way.  and those past bottlenecks wont return unless we start trying to do like holographic VR or idk what, but then you can negotiate such things over this anyway.


kermit:
(its a usual question to ask "if so good why no one before")

optimizations are only of value when one has identified the bottleneck

and btw you're the bottleneck now [people like you].  "i am not a developer" with Claude.  the bottleneck is waiting for you to tell it what to do, not the hardware.

we are post computing scarcity.  must code from the past was written when that was not true.

mention how what's  optimal at one time are not at another.  theres  a lot of momentum in those methods though.

show how easy it is to make an app custom  ..browser ui or native? is native even hard now?

give background, people often asked how to do p2p directly without forwarding

Using the same name for software and protocols is the trend that killed decentralizion since 2000.  People just see apps so they make more apps, never even thinking about interoperability.  Breaking that trend is critical and necessary to bringing back decentralizion by default.

"why now, why all these other ways before, this isn't new?"  "the bottlenecks have moved" (its not cpu, network, disk anymore.  its you, the developer, and with AI that's all of you.)


English for the wire


IP+JSON


kermit:
control over parts they already took the keys for ago but didnt kick out the driver (kernel doing TCP)  as Luc realized

a modern dev starts with letting the kernel handle stuff, but soon makes it more reliable (accross "disconnections") by doing it in the code themselves, but still has to deal with the "connection" management so winds up with more complexity than if they just took control from the start.  you wind up with two drivers of the same car, in the last 15+ years.

tcp is from 1974.  writingg all that higher level retransmission sequencing code was hard then

luc put it best "you're right, we're doing all that stuff at like 6 different layers above the  kernel now"

Chris fosdem / uncloud:
Everyone working overtime to make their layer of the stack bulletproof, adding a ton of complexity in the process, and making everything multiply-resilient and enormously overcomplicated?

tcp is just ADDING ARTIFICIAL LATENCY

tcp loses a packet, you get lag until it is re-transmitted and possibly even more lost packets if later ones made it

if you're just downloading a big file, whatever, fine, but for a huge amount of message oriened applications, thats just delay for no reason.

IP gave us free speech at a distance. LCDP gives us a language to use it.
uncapturable, base protocol cant be trademarket copyrighted liceneseds.. its just JSON

the pattern in p2p software development, if that's what you would call yours, that I see, is choose some highly developed transport to (supposedly) save time or just because its "the default" then as the app develops a higher and higher percentage of time gets spent working around the limitations of it but by then its too embedded to just DIY.  LCDP is *mostly* DIY, with some interoperability baseline.



kermit:
the biggest one, in all irony, is the assumption that the more established transport handles delivery reliably, but it usually doestn, and that ends up being written into the application anyway, while still dealing with the underlying transport.. LCDP acknowledges that pattern and skips ahead to admit the app has to deal with it.

i mean, the higher level ones usually do, some, but not 100%, so I you have to anyway, you just end up with two, one of which getting in the way



like signing a lifetime contract with a mediocre delivery service then when you're Amazon, stuck with it..  if you can manage to keep your protocol transport agnostic, you can benefit from both stages, but that's tricky
