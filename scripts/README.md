
`action_wheel.lua` is a bare-bones example for how to use this project in most avatars. All you need to do is

1. Require the `core` script. 
2. run core's `build_default_ui_action()`. This will return an [Action](https://figura-wiki.pages.dev/globals/Action-Wheel/Action)
3. Add the new action to your action wheel. 

If you don't already have an action wheel, then you can use this crazy one liner to initialize the action wheel and add the music player

```Lua
action_wheel:setPage(action_wheel:newPage():setAction(-1, require("scripts.music_player.core").build_default_ui_action()))
```
