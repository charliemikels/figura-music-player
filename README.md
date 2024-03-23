# Tanner Limes' Music Player for Figura

[Figura](https://github.com/FiguraMC/Figura) is a Minecraft mod that lets you completely customize your avatar with custom models and Lua scripts.

This repo is a Figura avatar that lets you play ABC music in Minecraft for you and others to hear. It's inspired by [Starbound](https://store.steampowered.com/app/211820/Starbound/)'s instrument items.

<!-- ↓ demo video of the avatar playing the chorus to "Revenge" by Captainsparklez ↓ -->
https://github.com/charliemikels/figura-music-player/assets/20339866/f088348f-7a3b-4993-a5d2-6699f653f281

## Installation

This version of this script was built for Figura 0.1.4 and makes use of the new files api. Check the Github releases for versions compatable with older versions of Figura. 

Use the green `code` button to download this repo as a zip file. Then navigate to your Figura avatars folder, make a sub-folder there for this avatar, and then extract the zip into that folder. 

The file structure should look like this:

```
[[ Figura root ]]
├ avatars
│ └ Music Player   ← This folder can have any name
│   ├ avatar.json
│   ├ scripts
│   │ ├ abc_player
│   │ │ ├ abc_player.lua
│   │ │ ├ anchor.bbmodel
│   │ │ └ triangle_sin.ogg
│   │ └ Action Wheel.lua
│   └ …
│
└ data
  ├ TL_Songbook
  │ ├ optional_sub_dir
  │ │ └ organized_song.abc
  │ ├ song2.abc
  │ └ song*.abc
  └ …
```

<details>
<summary>If you don't know where the root Figura folder is, you can get to it through Minecraft</summary>
<ol>
	<li>Open Minecraft.</li>
	<li>Open the Figura menu.</li>
	<li>Click the folder icon in the upper left.<br>This should open your file browser.</li>
	<li>Navigate up one folder.<br>You should see your <code>avatar</code> folder here.</li>
	<li>Open or create the <code>data</code> folder.</li>
	<li>Your destination is on the left.</li>
</ol>
</details>

## Adding Songs

After you've added the avatar, launch minecraft and load the avatar at least once. The avatar will atempt to create a songbook folder for you in Figura's `data` directory. 

The default songbook location is in `[figura_root]/data/TL_Songbook`, but you can change the path by editing `songbook_root_file_path` at the top of the `abc_player.lua` file.

After finding the songbook folder, place your .abc files into this folder. You can also use sub-folders to help organize your files. 

### ABC Files

Currently, this avatar **only supports songs written in the [ABC music format](https://abcnotation.com/)**. You can find ABC files online, (they're used frequently in the _Starbound_ and _Lord of the Rings Online_ communities.) or you can convert more common Midi files to ABC if you have the tools. 

If you plan on converting your own ABC files from Midi tracks, I recommend [Starbound Composer](http://www.starboundcomposer.com/), if you happen to have [Starbound](https://store.steampowered.com/app/211820/Starbound/) installed. But you don't need to have Starbound installed to use SBC. Starbound Composer will ask you to point to your Starbound install folder, but you can actually trick it pretty easily by pointing it to a folder with this structure:

```
target folder
├ assets
│ └ packed.pak     ← renamed empty file
└ win32
  └ starbound.exe  ← renamed empty file
```

Without the actual Starbound assets, you won't be able to preview your songs, but you will still be able to convert them from Midi to ABC, and you'll even be able to merge multiple tracks/files into a single ABC file. 

1. Select all tracks.
  - Ignore track 10, it's allways percussion.
2. Click the blue merge button.
3. Delete the old tracks. 
4. Save the new merged track to abc. 

If SBC won't work for you, you can try your hand at [this mega list of software for ABC files](https://abcnotation.com/software), some of them say they can convert ABC files to and from Midi files, however a lot of them just point to dead links. I haven't found one I really like yet. Your mileage may vary. <!-- However, [MidiZyx2abc](http://www.midicond.de/Freeware/index_en.html#MidiZyx2abc) might be pretty reasonable? -->

Note that this script is **not fully compatable** with the .abc spec. It's close, but there are some abc features that will confuse it. This script was primaraly created with Starbound Composer in mind, and has pretty good compatability with this specific editor. 

## In Game Usage

The controls for this avatar are in their own Action Wheel page. Open the Action Wheel and click the jukebox to access the song player controls. You should new see 3 buttons:

### Back

- Left click sends you back to the previous Action Wheel page

### Select Chloe Piano

ChloeSpacedOut made [this awesome piano avatar](https://github.com/ChloeSpacedOut/figura-piano). You can punch the keys to play notes, but you can also play songs through the piano with this script.

- Left click while looking at a piano to target the piano. Future notes will play through the piano instead of this avatar's built in instrument.
  - Be sure to aim at the player head of the piano. It's much smaller than the piano itself, near the peddles.
- Left click while not looking at a piano will deselect the current piano. Future notes will go back to the built in instrument.

![Piano](https://github.com/charliemikels/figura-music-player/assets/20339866/6faf6149-af74-4816-b3d1-93efe11bdb24)

Due note that piano support is not fully stable yet. There are a few edge cases that still need to be checked. If you encounter a crash, reload your avatar and the piano.

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

### How can I get the piano?

You can give yourself one of Chloe's pianos using this command: `/give @s player_head{SkullOwner:{Id:[I;-1808656131,1539063829,-1082155612,-209998759]}}`. But make sure you increase it's permission level in your Figura settings. (You will need to show disconnected avatars to find it.)

Check out the [Piano's github page](https://github.com/ChloeSpacedOut/figura-piano) for the actual avatar files. 

### Who's Charlie? I thought you were Tanner? (and vice versa)

Tanner_Limes is my Minecraft username. Hi Discord people!

### Why do some songs make me wait a very long time before they play?

There are two main cases where this can happen. Very large songs take a long time to parce into instructions. This usualy makes minecraft freeze and has a chance to make your client "time out" in singleplayer. Very fast songs can out-pace the ping-limit, so they need time to buffer first. 