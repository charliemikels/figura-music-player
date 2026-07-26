So. Turns out a lot of songs actualy take a long time to buffer. We need to shrink our format a little bit.

One major culprit is that every single channel modifier gets applied to every single note in the channel, until said modifier is reset. 
That. Is a LOT of wasted space. But it solved the problem that modifiers could be lost if a packet was dropped.

What if the start of every packet just had a little channel state packet?

In this plan, there would be two kinds of instruction packets: Notes, and Track/Channel packets. 

Note would be extreamly similar to the instructions we already have, but they would have essentialy no modifiers. Modifiers would instead be actual packets that apply to the channel. 

To prevent lossed data, every packet would start with a channel info packet. But we could encode it as a normal instruction packet.
