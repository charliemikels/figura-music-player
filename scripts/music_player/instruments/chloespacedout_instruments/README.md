
The Instruments in this Folder are all powered by [ChloeSpacedOut](https://github.com/ChloeSpacedOut)'s [Figura Midi Cloud](https://github.com/ChloeSpacedOut/figura-midi-player) avatar. But the Midi Cloud only works if you and your listeners set you avatar (this script) and the Midi Cloud Avatar to MAX permissions. Without these set, you and your listeners will here a fallback instrument instead of the one you selected.

This is unlike most other instruments included in this script that typically don't require any permissions editing for your listeners.

To make sure everyone hears these instruments correctly, you and your followers will need to follow Chloe's official setup instructions [here](https://github.com/ChloeSpacedOut/figura-midi-player), but here's a TLDR:

## Setup TLDR

After you equip the Music Player avatar, you **and your listeners** will need to

1. Go into Figura → Permissions.
2. Click "Show Disconnected Avatars" 
3. Look for (scroll, don't search) for the "Chloe's MIDI Player" avatar.
4. Set it to MAX permissions.
5. Set your avatar to MAX Perms as well. (This is the default for you, but you may need to ask your viewers to upgrade you.)

![An annotated screenshot pointing to where each click in the above list happens.](upgradeing_midi_player_permissions_annotated_screenshot.png)

After you've done this, you should notice that the Midi Cloud instruments activate immediately, even if you were already playing a song. 

Oh, and if you're here because of the warning that pops up sent you to this README file, you can use this command to dismiss it with this command: "/figura run TL_cloud_midi_instrument_suppress_warning()". Thank you for your attention.

### The Piano and Drumkit

The "Piano" and "Drumkit" instruments behave slightly differentially. While they themselves rely on the Midi Cloud, you and your listeners will need to set `Piano 2.0`'s permissions to MAX in order to hear these instruments. Like Chloe MIDI Player, it is also a disconnected avatar.

For help spawning a piano and other usage notes, please see [Figura Piano 2.0's Github page](https://github.com/ChloeSpacedOut/figura-piano-2.0).

One notable upside of these instruments compared to the Midi Cloud instruments is that your viewers do not need to set you, the host, to MAX permissions. Only the `Piano 2.0` and the `Chloe's MIDI Player` avatars need to be on MAX. You're free to stay on Default.

#### Getting the Piano / Drumkit

The official way to get the Piano is by using commands. But if you can't use commands, but can still get player heads, you might still be able to use the piano. 

1. Equip the Piano avatar to an account you control. (It may be possible to merge it with this Music Playing script and use just one avatar)
2. Get your player head
3. Get the UUID of the account with the piano equipped. (You can do that from within Figura by going to permissions, right click the avatar, copy UUID)
4. Add the UUID to the lists at the top of `scripts/music_player/instruments/chloespacedout_instruments/piano.lua` and `…/drumkit.lua`.
5. Reload the music player avatar.

But if you're going through all this effort, you might want to use the Cloud Midi instruments.
