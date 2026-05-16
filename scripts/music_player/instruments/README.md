
This is a collection of instruments available to song_player.

Scripts in this folder actually return a list of instrument_builders, allowing one script to return multiple instruments. 

Instruments are responsible for 

1. receiving and playing instructions
2. keeping track of sounds that may need to be stopped or updated
3. Efficiently handling the stop_immediately functions (they may be called by the emergency stop system)

Notably they are _not_ responsible for running their own update loop. Instead they are ticked by SongPlayer.
