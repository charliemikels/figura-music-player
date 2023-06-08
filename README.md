# Tanner Limes's[^whoIsTannerLimes] Music Player for Figura

[^whoIsTannerLimes]: Yes, Tanner Limes and Charlie Mikels are the same person. Don't worry about it.

[Figura](https://github.com/Kingdom-of-The-Moon/FiguraRewriteRewrite) is a Minecraft mod that lets you completely customize your avatar with custom models and Lua scripts.

This repo is a Figura avatar lets you play music in game for you and others to hear.

⚠️ Heads up: This avatar requires [LUtils](https://github.com/lexize/lutils) in order to work. See the installation instructions below for more details.

<!-- ↓ demo video of the avatar playing the chorus to "Revenge" by Captainsparklez ↓ -->
https://github.com/charliemikels/figura-music-player/assets/20339866/f088348f-7a3b-4993-a5d2-6699f653f281

## Installation

This avatar relies on LUtils to find and load song files on the fly. This means your songlist will not count against the avatar file size limit. LUtils is a separate Fabric mod that works with any recent version of Minecraft, but it has specific builds for your version of Figura.

  - If you're on Figura r14, (the current[^uploadTime] public builds,) you'll need [Build 7: "Minor but important change."](https://github.com/lexize/lutils/actions/runs/4241722822).
  - If you're on the development versions of Figura, you'll need [Build 8: "Some changes. Fixed crashes with github builds"](https://github.com/lexize/lutils/actions/runs/4674799028).

[^uploadTime]: "Current" as of June 7th, 2023.

Download your version by clicking the Artifact in the actions page.

✏️ Note: Github has started to flag these builds as expired. Reach out to us on [the Figura Discord](https://discord.gg/figura) if you need help getting this mod installed.

Once LUtils is installed, download this repo using the `<> code` button above, and unzip it in your Figura `avatars` folder. (It should be in it's own folder)

## Adding Songs

If this is the first time using this avatar, launch Minecraft, open a world, and select this avatar. This will create a songs directory for you. By default, it will be at `<Figura>/data/lutils_root/abc_song_files`. You can get to this folder quickly by going to the `avatars` folder and navigate up a directory. You will find the `data` folder there.

Currently, this avatar only supports songs written in the [ABC music format](https://abcnotation.com/). You can find ABC files online, or you can convert Midi files to ABC if you have the tools. Once you have an ABC file, you can drag and drop the song into the data song folder the avatar created, and it will appear in the song list when you reload the avatar. They can even be organized into sub folders.

If you plan on converting your own ABC files from Midi tracks, I strongly recommend [Starbound Composer](http://www.starboundcomposer.com/), but only if you happen to have [Starbound](https://store.steampowered.com/app/211820/Starbound/) installed. Starbound Composer will ask you to point to your Starbound install folder, but you can actually trick it pretty easily by pointing it to a folder with this structure:

```
target folder
├ assets
│ └ packed.pak  ← renamed empty file
└ win32
  └ starbound.exe ← renamed empty file
```

Without the actual Starbound assets, you won't be able to preview your songs, but you will still be able to convert them from Midi to ABC, and you'll even be able to merge multiple tracks/files into a single ABC file.

If SbC won't work for you, you can try your hand at [this mega list of software for ABC files](https://abcnotation.com/software), some of them say they can convert ABC files to and from Midi files, however a lot of them just point to dead links. I haven't found one I really like yet. Your mileage may vary. <!-- However, [MidiZyx2abc](http://www.midicond.de/Freeware/index_en.html#MidiZyx2abc) might be pretty reasonable? -->

## In Game Usage

The controls for this avatar are in their own Action Wheel page. Open the Action Wheel and click the jukebox to access the song player controls. You should new see 3 buttons:

### Back

- Left click sends you back to the previous Action Wheel page

### Select Chloe Piano

ChloeSpacedOut made an awesome piano avatar that's not only playable by punching the keys, she also made it scriptable.

- Left click while looking at a piano to target the piano. Future notes will play through the piano instead of this avatar's built in instrument.
  - Be sure to aim at the player head of the piano. It's much smaller than the piano itself, near the peddles.
- Left click while not looking at a piano will deselect the current piano. Future notes will go back to the built in instrument.

<!-- Piano Image here -->

Due note that piano support is not fully stable yet. There are a few edge cases that still need to be checked.

### Song list

This is where all the important magic happens

The text window for this button displays some important info:

```
+-----------------------------------------+
| Songlist 9/30 Currently Playing: Song 6 |   ← Selected Song index
|     Song 5                              |   ↑ Currently playing song name
| ♬   Song 6                              |   ← Playing song marked by ♬
|     Song 7                              |
|   → Song 8                              |   ← Selected song marked by →
| •   Song 9                              |   ← Queued song marked by •
|     Song 10                             |   
|     Song 11                             |
| Click to queue selected song            |   ← Left click action hint
| Queued song starts in 2 seconds         |   ← Queued song's buffer time
+-----------------------------------------+
```

- Scroll to navigate the song list
- Shift+Scroll to navigate the list faster
- Left click a song to queue it.
  - "Queuing" a song will load it from disk, chop it up into instructions, and will turn the instructions into packets, ready to be sent to the listener.
- Left click a queued song to start playing it.
- Left click on a queued song while another song is playing to stop the currently playing song.
  - (This also works if the queued song is also the playing song.)

## FAQ

### Do my friends also need to install LUtils?

No. Only the host needs LUtils installed to make this avatar work. But for best results, everyone should be on the same Figura version.

### Why do some songs make me wait a very long time before they play?

This is a side effect of the ping limit. Figura lets avatars send up to 1KB of information to other players every 1 second. This is usually fine since most songs don't need to send more than 1KB of data per second anyways. However, some songs can play fast enough that they can outrun the song data if we're not careful. 
