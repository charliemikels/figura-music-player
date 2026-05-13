Alright gamers.

![This is where the fun begins](https://i.kym-cdn.com/photos/images/original/001/947/993/084.png)

## Overview of "default" experiance

In case any of you are trying to study this code, here's a ~~quick~~ overview of what the script does.

### Init

The intended entry-point is the `core.build_default_ui_action()` function in `core.lua`. Check out the `action_wheel.lua` script in the directory above to see how it's intended to be used.

- The user's scripts calls `core.lua`'s `build_default_ui_action()` function.
  - `core.lua` asks `libraries.lua` to build a default Library.
    - `libraries.lua` uses the [Files API](https://figura-wiki.pages.dev/globals/File) and `file_processor.lua` to explore the default `[figura_root]/data/TL_Songbook` directory for music files.
      - `file_processor.lua` gives every found path to the processors in the `file_processors` directory. They are in charge of recognizing songs and returning a SongHolder for each one they find.
    - `libraries.lua` asks `local_songs.lua` to load in any songs in the `local_songs` directory.
      - `local_songs.lua` returns a list of SongHolders just like the regular file processors
      - `local_songs.lua` starts its TICK event loop to build Songs out of the SongHolders it finds.
  - `core.lua` asks `ui.lua` to build an action wheel [Action](https://figura-wiki.pages.dev/globals/Action-Wheel/Action).
    - `ui.lua` does a bunch of magic to set itself up, but returns an Action to enter a new action wheel.
- The user's script (we assume) adds the new action to their own action wheel.

### UI → Song selector → Process song

- User clicks on a song in the UI's Song list for the first time.
  - (`file_processor.lua` (and `local_songs.lua`) added a link to a data_processor function to every SongHolder.)
  - `ui.lua` calls the selected SongHolder's Data Processor function.
    - The inner workings of this function are dependent on what script generated the SongHolder.
    - Data processor returns a future
  - `ui.lua` adds a callback function to this future
    - The callback function will
      - Check for errors during processing
      - Find or create a config for the processed song
      - ask `networking.lua` to create a networked SongPlayer (see below)
      - Update UI's state, marking the song as ready-to-play
    - The callback runs when the processor is done
- The selected song is marked with an `⏳` to say it is being processed. It will eventually turn into a `✓` to signal it's ready.
- Your FPS will see a significant drop as the script processes a song.

#### Midi SongHolder Data Processor

- Some part of the script called a Midi song's data processor function.
  - `midi_processor.lua` Spins up some initialization, then kicks off a WorldRender event.
    - The data processor is very heavy. On somewhat large songs, it cant freeze the game for a good chunk of time. By leveraging the event loop, we can make this process asynchronous.
    - We use a WorldRender event because the World events are always run, and the render events don't try to "catch up" if they take too long. (Tick events eventually stack up and the game will freeze as it tries to process ticks back to back.) This lets us let go of control every now and then, let the main game thread catch up, and then pick up on the next available frame. This is important for
  - For the benefit of the rest of the script, the data processor immediately returns a future `see futures.lua` that the world event will update.
- The caller can then assign callback functions to do some logic once the future is done.

- Meanwhile, the data processor loop (running on the WorldRender event loop)
  - Steps through some phases to read through a midi file. (see `MidiProcessorStageKey` and `midi_processor_loop_stage_functions`)
    - `init`: Finishes some last-minute checks with the Files API
    - `read`: reads in data a few bytes at a time. Splits the file into its separate chunks, and will process header chunks if it finds one.
    - `process`: looks through all track chunks and finds the next event (chronologically). It then sends the event to `midi_message_functions` for further processing
    - `done`: final cleanup. Assigns a `Track` to each unique midi channel/device/program combo. Sets the future to done.

#### Local Song SongHolder Data Processor

Unlike the other File processors, `local_songs.lua`

1. Starts it's data processor loop on Init, start data_processor actually just returns a pre-created future for that song.
2. Is designed to run on all clients. Each step is actually very minimal and runs on the TICK event. This means that all clients will (eventualy) load every local song.

`LocalSongScripts` are essentially a lua script that just stores all the `PacketDataString`s necessary to build a song using `packet_decoder.lua`. We use this system because we know all the the decoder functions are already light enough to run on the viewer, and `PacketDataString`s are pretty well compressed too. Not as good as MIDI, but competitive with ABC.

On Script Init:

- `local_songs.lua` loops through all files in the `local_songs` directory and adds them to a list.
- `local_songs.lua` builds a SongHolder for each file it found. These are returned whenever the library asks for them.
- `local_songs.lua` creates and stores a future for each song.
- `local_songs.lua` starts an Tick event loop.

The Tick event:

- `local_songs.lua` steps through a set of functions. Each function is responsible for processing all songs, and eventually advancing to the next function. see `local_song_tick_loop_functions`. If there's an error at any step, the problem song is removed from the queue and it's future will be set to done_with_error.
  - `require_the_script_songs` for each file in the list, the script tries to `require()` them. Then it will update the SongHolder's short_name.
  - `header_processing`, `config_processing`, and `data_processing` step through each packet and creates or adds them to their Song.
  - `data_processing` is in charge of setting the future to Done

Anything calling a local song's process_data function will be given the Future created at Init. This future may already be done by the time it's requested, but the callback functions should still work. They'll just be called immediately instead of eventually.

### UI → Song Selector → Play

- User clicks on a song in the UI's Song list that is ready to play.
  - `ui.lua` checks if another song is already playing. if there is one, that song is stopped, and we return to the user.
  - `ui.lua` finds the networked SongPlayer that we built for the selected song during the Process Song phase.
  - `ui.lua` calls SongPlayerController's `play()` function. See the [Networked SongPlayer](#NetworkedSongPlayer) section below.

### Networked SongPlayer

`networking.lua`, `packet_encoder.lua`, and `packet_decoder.lua` have a number of concerns:

- We need to stay well under the [Ping system](https://figura-wiki.pages.dev/tutorials/Pings)'s size, frequency limits, and total data rate. (we might be shearing resources with other scripts in this avatar.)
- Keep each packet small enough that we can process it in one step.
- Calculate how long we need to buffer packets before starting playback (allows us to start playback before all packets have arrived)
- Figura sometimes bundles multiple pings into one mega-ping
  - For the Host, this seems to mess with ping limit calculations
  - For viewers, this means multiple pings might need to share one Ping Event's instruction limit.

We take care of all this in `networking.lua` by

- Compressing data into strings that are easy to ping
- making sure all song packets go through one bottleneck: `pings.TL_FMP_receive_packet()`.

All packets pass through `pings.TL_FMP_receive_packet()`. Each packet also comes with a `transfer_id` and a `packet_type`.

- `transfer_id` is a unique identifier for each song sent through pings. This lets us know what song each packet belongs to.
- `packet_type` just tells us what kind of data we are receiving. We keep this outside of the packet itself because `local_songs.lua` uses the same packet information as `networking.lua`.

`pings.TL_FMP_receive_packet()` primarily works with the `packet_receiving_functions`. These look at the packet_type and decide what to do from there.

- `header`: Creates a new Song and SongPlayer, and store them with their transfer ID.
- `config`: Applies a new SongPlayerConfig to a SongPlayer created by `receive_header_packet()`
- `data`: Appends Instructions to the Song created by `receive_header_packet()`
- `control`: Sends commands to a SongPlayer created by `receive_header_packet()`

Everything around `pings.TL_FMP_receive_packet()` is there to make sure we are sending packets at the right rate, and processing received packets one at a time.

`networking.lua` also provides a `new_network_song_player()` function that wraps everything up into the same interface as a `SongPlayerController`, but it ensures all audible actions are synced to viewers. It is the recommended way to play songs and sync them over the network. (Do note that not all actions are synced. Notably the callback functions only run on the Host.)

### Playback loop

Once a song is processed, it can be given to `song_player.lua` → `new_player()` to create a new SongPlayer. SongPlayers are always initialized with a song, and only have one song. If you want to implement a playlist of songs, you'll need to coordinate multiple players together.

(For syncing songs between clients, use `networking.lua` → `new_network_song_player()` instead. They share roughly the same API.)

`new_player()` actually returns a SongPlayerController. This helps protect SongPlayer from accidental modifications and keeps the LSP's output a lot cleaner.

Check out the definition for SongPlayerController to see what you can do with it. But the important details are these:

- `.play()`: Kicks off the main event loop and the watcher event loop.
- `.stop()`: Shuts down the main and watcher event loops, and calls any stop callbacks
- `.set_new_config()`: Lets you give a `SongPlayerConfig` to a song.
  - `SongPlayerConfig` include information like what instruments to use for what tracks, where to position the playing audio (and if it follows an entity), etc.
  - This will overwrite any config you previously sent.
- `.register_…`/`.remove_(callback_type)_callback()`: Similar to the File Processor's callback system, this lets you piggy back of of the song's event loop to run functions. There are three callback types
  - `stop`: Is called every time the song is stopped. It will also pass why the song stopper (either a "normal" or an "emergency" stop).
  - `update`: Is called every time the song is updated.
  - `meta`: some instructions are meta instructions. They don't impact the playback audio, but it can be useful to sync certen events in the song. This callback will be given the event ID and its data when it is called.

Song players actually use multiple event loops to manage themselves.

The Main loop steps through the Song, finds instructions that need to be played, and dispatches said Instructions to the correct instrument. It then ticks every active instrument, updates in-world GUIs, calls update callbacks, and checks if the song is done. When it's done, it just calls controller.stop() to finish cleanup.

There is also a watcher loop that runs on the WorldTick event. It's job is to make sure the main event has not failed.

By default the main loop uses the Render event to get better temporal resolution. (Unless the viewer is running at 20FPS, the Render event is much faster than the Tick event.) But the Render event doesn't always run. This commonly happens when the avatar is off-screen on low and default permissions, but it can also happen with some modded full-screen GUIs like Xaero's Worldmap. So all song_players are set up with a fallback event. By default the fallback event is the Tick event, which is usually pretty reliable, and has a high instruction limit. The WorldTick watcher loop is in charge of noticing when the main event fails, and to switch to the fallback.

But there are still cases where both the main and fallback event loops stop running. (Maybe the Host has gone through a Nether portal, unloading their entity.) More than likely this will leave behind sounds that cannot be updated. So the watcher's second job is to preform an emergency stop when both the main and fallback events fail.

This process will run on the viewers, and the WorldTick limit is really tight at default and low permissions. So we need to keep the process slow.

The emergency stop runs through a few different steps.

- `begin_emergency_stop`: Tells the SongPlayer to stop playing, in the event that either event loops come back online. This is enough for the SongPlayer to think it's stopped.
- `emergency_stop_active_instruments`: One instrument per tick, disable one note in one instrument, until all instruments say they are finished.
- `emergency_stop_deprecated_instruments`: same as `emergency_stop_active_instruments`, but for any left over instruments from a previous SongPlayerConfig
- `emergency_info_display_remove_parts` and `emergency_info_display_nil_parts`: Shut down the in-world info text.
- `emergency_run_stop_functions`: One function per tick, call the stop functions, passing "emergency" as the stop reason.
- At the end of the last step, the world event removes itself and cleans its state up.

#### Instructions

This project uses a special data format for storing songs. Songs have some metadata like name, buffer time, song duration, etc. But also a list of Instructions. An instruction has all the information for one note. Its start time (relative to the start of the song), its duration, the note number, track number, and modifiers for that note. Unlike MIDI where a note can be started and then we just have to wait for the "note stop" event, instructions always keep these values together. This makes them safe to send over pings. Even if we drop packets, we won't fail to clean up sounds we started.

There is one exception to the always-together rule: to improve buffer times, modifiers may be separated from an instruction and sent later as a separate "modifier instruction." This kind of instruction only exists in the networking/packets system. Not all instruments support all modifier types (frankly there's only like 2 supported modifiers anyways), so they are treated as second class citizens.

<!--### UI → Config → Save-->
