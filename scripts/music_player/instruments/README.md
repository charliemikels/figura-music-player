
This is a colection of instruments available to song_player.

Scripts in this folder actualy return a list of instrument_builders, allowing one script to return multiple instruments. 

Instruments are responcible for 

1. receiveing and playing instructions
2. keeping track of sounds that may need to be stopped or updated
3. Efficiently handleing the stop_immediatly functions (they may be called by the emergency stop system)

Notably they are not responcible for runing their own update loop. Instead they are ticked by SongPlayer.
