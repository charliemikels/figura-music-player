
Local songs are a special custom song format that are essentialy just a stream of packet strings exported as Lua files.

This allows us to read in local files extreamly efficiently by simply calling require() on them, and letting the lua interpreter just handle everything.

Our custom packet strings actualy use a lot of raw binary data which need to be encoded as c-style escape sequences, but the interpreter just reads it in for us. More importantly, c-style escapes are more compressible at upload time than something like a base64 string. (Although on disk they are heavier.)

Check out local_song_builder.lua to generate a local song.
