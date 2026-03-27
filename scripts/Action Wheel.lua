local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

-- More or less: the current checklist
-- - [x] Ping Networking
-- - [x] UI
--   - [x] Store song configs with config API
-- - [ ] Use commands to save a processed song so that it can be uploaded with the avatar
-- - [ ] Port the ABC player to a new processor
-- - [x] Minecraft Note Block instruments
-- - [ ] Figura Piano instrument
-- - [ ] Load instruments from other avatars
-- - [ ] test if I can force the viewer to load an offline avatar by making them render a player head
--   - See also: Chloe Piano 2.0 → https://github.com/ChloeSpacedOut/figura-midi-player/blob/3c2888209ac75b1c0ec57c7ea4ca0b49aee291bb/ChloesMidiPlayerClientExample/midiPlayerClient.lua#L85-L90
-- - [ ] Register callback functions through song controller for song end / meta event received / etc.
-- - [ ] Figura Drum Kit instrument
--       https://discord.com/channels/1129805506354085959/1340798228165300224/1340798228165300224
--       /give @p minecraft:player_head[minecraft:profile={id:[I;1039887675,1961051688,-1756947787,-2031944347],name:"Drum"}]

local ui_api = require("scripts/music_player/ui")
local default_library = require("scripts/music_player/libraries"):build_default_library()
local enter_music_player_action_wheel_ui = ui_api.new_action_wheel_ui(default_library)
root_action_wheel_page:setAction(-1, enter_music_player_action_wheel_ui )

return root_action_wheel_page
