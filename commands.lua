
local mod_storage = minetest.get_mod_storage()

-- Reminder to save!
local unsaved_changes = false
local save_reminder_timer = 0
minetest.register_globalstep(function(dtime)
    if unsaved_changes then
        save_reminder_timer = save_reminder_timer + dtime
    end
    if save_reminder_timer > 120 then
        save_reminder_timer = 0
        minetest.chat_send_all("[syncpath] You have unsaved changes! Remember to save your work with '/save'")
    end
end)

minetest.register_chatcommand("music", {
    description = "Set or display the music for the sync",
    params = "<sound file name without extension>",
    func = function(name, param)
        if param then
            syncpath.music_name = param
            minetest.chat_send_player(name, "[syncpath] Music set to " .. param .. ".ogg")
        else
            minetest.chat_send_player(name, "[syncpath] Music is currently set to '" .. syncpath.music_name .. ".ogg'")
        end
    end
})

minetest.register_chatcommand("sync", {
    description = "Start a sync ride, attach the player to the ride, and start the music",
    params = "[<starting bar>]",
    func = function(name, param)
        if #syncpath.path == 0 then
            minetest.chat_send_player(name, "[syncpath] No path is currently loaded.")
            return
        end
        local args = string.split(param, " ")
        local pos = minetest.get_player_by_name(name):get_pos()
        local obj = minetest.add_entity(pos, "syncpath:ride")
        minetest.get_player_by_name(name):set_attach(obj)

        syncpath.active = true
        local start_time_offset = tonumber(args[1] or 0) / 60 * syncpath.bpm
        syncpath.starttime = minetest.get_us_time() / 1000000 - start_time_offset

        if syncpath.music_handle then
            minetest.sound_stop(syncpath.music_handle)
        end
        syncpath.music_handle = minetest.sound_play({name = syncpath.music_name}, {object = minetest.get_player_by_name(name), start_time = start_time_offset}, false)

        if args[1] or syncpath.bpm ~= 140 or syncpath.music_name ~= "" then
            minetest.chat_send_player(name, "[syncpath] Sync started.")
        else
            minetest.chat_send_player(name, "[syncpath] Sync started.")
        end
    end
})

---
--- Visualization
---

local path_beams = {}

local setup_path_beams = function()
    -- Pick a new big number as the (hopefully) unique id for the new path beams
    syncpath.random_path_id = math.random(10^10)
    for i, keyframe in ipairs(syncpath.path) do
        if i < #syncpath.path then
            local beam_segments = syncpath.min_beam_segments
            local total_distance = vector.distance(syncpath.path[i+1].position, keyframe.position)
            if total_distance > 30 then
                beam_segments = syncpath.min_beam_segments * total_distance / 30
            end
            for beamidx = 1, beam_segments do
                local startbar = keyframe.bar + (beamidx - 1) / beam_segments * (syncpath.path[i+1].bar - keyframe.bar)
                local endbar = keyframe.bar + (beamidx) / beam_segments * (syncpath.path[i+1].bar - keyframe.bar)
                local starttime = startbar * 4 / syncpath.bpm * 60
                local endtime = endbar * 4 / syncpath.bpm * 60
                local startpos = syncpath.path_function(starttime)
                local endpos = syncpath.path_function(endtime)
                table.insert(
                    path_beams,
                    minetest.add_entity(startpos, "syncpath:path_beam", minetest.serialize({offset = endpos - startpos, path_id = syncpath.random_path_id}))
                )
            end
        end
    end
end

local remove_path_beams = function()
    for _, obj in pairs(path_beams) do
        obj:remove()
    end
end

syncpath.refresh_path_beams = function()
    remove_path_beams()
    if syncpath.show_path_beams then
        setup_path_beams()
    end
end

minetest.register_chatcommand("path", {
    description = "Show or hide the path beam visualization",
    func = function(name)
        syncpath.show_path_beams = not syncpath.show_path_beams
        syncpath.refresh_path_beams()
    end
})

local setup_keyframe_hud_waypoints = function(player)
    local waypoint_ids = {}
    for i, keyframe in ipairs(syncpath.path) do
        local id = player:hud_add({
            hud_elem_type = "waypoint",
            name = "Bar " .. keyframe.bar,
            world_pos = keyframe.position,
            z_index = -300,
            number = keyframe.interpolation == "linear" and (0*(256^2) + 255*(256^1) + 0*(256^0)) or (0*(256^2) + 0*(256^1) + 255*(256^0))
        })
        table.insert(waypoint_ids, id)
    end
    player:get_meta():set_string("syncpath_waypoints", minetest.serialize(waypoint_ids))
end

local remove_keyframe_hud_waypoints = function(player)
    local waypoint_ids = minetest.deserialize(player:get_meta():get_string("syncpath_waypoints"))
    if waypoint_ids then
        for _, id in pairs(waypoint_ids) do
            player:hud_remove(id)
        end
    end
end

syncpath.refresh_keyframe_hud_waypoints = function(player)
    remove_keyframe_hud_waypoints(player)
    if syncpath.show_keyframes then
        setup_keyframe_hud_waypoints(player)
    end
end

minetest.register_chatcommand("keyframes", {
    description = "Show or hide the keyframe positions as waypoints on the hud",
    func = function(name)
        syncpath.show_keyframes = not syncpath.show_keyframes
        syncpath.refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
    end
})

minetest.register_chatcommand("visuals", {
    description = "Show or hide the visual path and keyframes. Essentially a combination of /keyframes and /path",
    func = function(name, param)
        -- Make sure both settings are identical, either both true or both false. Arbitrarily using path beams as the reference.
        syncpath.show_path_beams = not syncpath.show_path_beams
        syncpath.show_keyframes = syncpath.show_path_beams
        syncpath.refresh_path_beams()
        syncpath.refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
        minetest.chat_send_player(name, "[syncpath] Path visualization " .. (syncpath.show_path_beams and "enabled." or "disabled."))
    end
})

---
--- Keyframe manipulation
---

minetest.register_chatcommand("add_keyframe", {
    description = "Add a keyframe for the position of the ride on bar <bar>, given by the current bpm. Optionally specify if the keyframe should have linear or smooth interpolation.",
    params = "<bar> [linear | smooth]",
    func = function(name, params)
        local position = minetest.get_player_by_name(name):get_pos()
        local args = string.split(params, " ")
        local bar = tonumber(args[1])
        local interpolation = args[2] or "linear"
        if bar then
            local insert_pos = #syncpath.path + 1
            -- Remove any duplicates
            for i, keyframe in pairs(syncpath.path) do
                if bar == keyframe.bar then
                    minetest.chat_send_player(name, "[syncpath] Bar " .. bar .. " already has a keyframe. Replacing...")
                    table.remove(syncpath.path, i)
                    -- Need to update insert_pos right here in case we deleted the only keyframe, which would mean the loop below would never run.
                    insert_pos = i
                end
            end
            -- Find the proper position to insert this keyframe
            for i, keyframe in ipairs(syncpath.path) do
                if i == 1 then
                    if keyframe.bar > bar then
                        insert_pos = i
                        break
                    end
                elseif syncpath.path[i-1].bar < bar and keyframe.bar > bar then
                    insert_pos = i
                    break
                elseif i == #syncpath.path and keyframe.bar < bar then
                    insert_pos = #syncpath.path + 1
                end
            end
            table.insert(syncpath.path, insert_pos, {
                bar = bar,
                position = position,
                interpolation = interpolation,
            })
            minetest.chat_send_player(name, "[syncpath] Keyframe added on bar " .. bar)
            syncpath.refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
            syncpath.refresh_path_beams()
            unsaved_changes = true
        else
            minetest.chat_send_player(name, "[syncpath] Please provide a bar number to add this keyframe on")
        end
    end
})

minetest.register_chatcommand("remove_keyframe", {
    description = "Remove the keyframe on bar <bar>, given by the current bpm.",
    params = "<bar>",
    func = function(name, param)
        local bar = tonumber(param)
        if bar then
            for i, keyframe in pairs(syncpath.path) do
                if keyframe.bar == bar then
                    table.remove(syncpath.path, i)
                    minetest.chat_send_player(name, "[syncpath] Removed keyframe on bar " .. bar)
                    syncpath.refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
                    syncpath.refresh_path_beams()
                    unsaved_changes = true
                    break
                end
            end
        else
            minetest.chat_send_player(name, "[syncpath] Please provide a bar number for the keyframe to delete")
        end
    end
})

---
--- Debugging and testing
---

minetest.register_chatcommand("print_path", {
    description = "Prints the path data in chat",
    func = function(name)
        for i, keyframe in ipairs(syncpath.path) do
            minetest.chat_send_player(name, "Keyframe " .. i .. ": bar: " .. keyframe.bar .. ", position: " .. dump(keyframe.position))
        end
    end
})

minetest.register_chatcommand("view_bar", {
    description = "Teleport to the position on the path at the given bar",
    params = "<bar>",
    func = function(name, param)
        local bar = tonumber(param)
        if bar then
            local synctime = bar * 4 / syncpath.bpm * 60 
            local path_pos = syncpath.path_function(synctime)
            if path_pos then
                minetest.get_player_by_name(name):set_pos(path_pos)
            end
        end
    end
})

minetest.register_chatcommand("view_time", {
    description = "Teleport to the position on the path at the given time. The same as /view_bar, but in terms of seconds instead of bars.",
    params = "<seconds>",
    func = function(name, param)
        local synctime = tonumber(param)
        if synctime then
            local path_pos = syncpath.path_function(synctime)
            if path_pos then
                minetest.get_player_by_name(name):set_pos(path_pos)
            end
        end
    end
})

---
--- Configuration
---

minetest.register_chatcommand("bpm", {
    description = "Show or set the bpm of the syncpath",
    params = "[<bpm>]",
    func = function(name, param)
        if param and tonumber(param) then
            syncpath.bpm = tonumber(param)
            minetest.chat_send_player(name, "[syncpath] BPM set to " .. tostring(syncpath.bpm))
            unsaved_changes = true
        else
            minetest.chat_send_player(name, "[syncpath] Current BPM: " .. tostring(syncpath.bpm))
        end
    end
})

minetest.register_chatcommand("interpolation", {
    description = "Set the interpolation mode of every keyframe. Options: linear, smooth.",
    params = "(linear | smooth)",
    func = function(name, param)
        if param and (param == "linear" or param == "smooth") then
            for i, keyframe in pairs(syncpath.path) do
                keyframe.interpolation = param
            end
            syncpath.refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
            syncpath.refresh_path_beams()
            unsaved_changes = true
        else
            minetest.chat_send_player(name, "[syncpath] Invalid interpolation mode. Options are 'linear' and 'smooth'")
        end
    end
})

---
--- Saving/Loading
---

minetest.register_chatcommand("save_path", {
    description = "Save the current path under <name>. DEPRECATED, use /save instead",
    func = function(name, param)
        if param then
            mod_storage:set_string(param, minetest.serialize(syncpath.path))
            minetest.chat_send_player(name, "[syncpath] Path saved as '"..param.."'")
        else
            minetest.chat_send_player(name, "[syncpath] No path name given")
        end
    end
})

minetest.register_chatcommand("load_path", {
    description = "Load the current path under <name>. DEPRECATED, use /load instead",
    func = function(name, param)
        if param then
            syncpath.path = minetest.deserialize(mod_storage:get_string(param))
            if syncpath.path then
                for i, keyframe in pairs(syncpath.path) do
                    keyframe.position = vector.new(keyframe.position.x, keyframe.position.y, keyframe.position.z)
                    keyframe.interpolation = keyframe.interpolation or "linear"
                end
                syncpath.refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
                syncpath.refresh_path_beams()
                minetest.chat_send_player(name, "[syncpath] Loaded path '"..param.."'")
            else
                syncpath.path = {}
                minetest.chat_send_player(name, "[syncpath] Path '"..param.."' does not exist or could not be parsed")
            end
        else
            minetest.chat_send_player(name, "[syncpath] No path name given")
        end
    end
})

minetest.register_chatcommand("save", {
    description = "Save the current project under <name>. If no name is given but the project has been previously saved, it will be saved under the same name.",
    params = "[<name>]",
    func = function(name, param)
        if param and param ~= "" then
            syncpath.name = param
        else
            if not syncpath.name then
                minetest.chat_send_player(name, "[syncpath] Please provide a name for the project with '/save <name>'. After it is saved once, you can use '/save' by itself to save it to the same name.")
                return
            end
        end
        local data = {
            name = syncpath.name,
            music_name = syncpath.music_name,
            bpm = syncpath.bpm,
            path = syncpath.path,
        }
        mod_storage:set_string(syncpath.name, minetest.serialize(data))
        minetest.chat_send_player(name, "[syncpath] Project saved as '"..syncpath.name.."'")
        unsaved_changes = false
    end
})

minetest.register_chatcommand("load", {
    description = "Load the project named <name>.",
    params = "<name>",
    func = function(name, param)
        if param and param ~= "" then
            local data = minetest.deserialize(mod_storage:get_string(param))
            if data then
                syncpath.name = data.name
                syncpath.music_name = data.music_name
                syncpath.bpm = data.bpm
                syncpath.path = data.path

                for i, keyframe in pairs(syncpath.path) do
                    keyframe.position = vector.new(keyframe.position.x, keyframe.position.y, keyframe.position.z)
                    keyframe.interpolation = keyframe.interpolation or "linear"
                end
                syncpath.show_path_beams = true
                syncpath.show_keyframes = true
                syncpath.refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
                syncpath.refresh_path_beams()
                minetest.chat_send_player(name, "[syncpath] Loaded project '"..param.."'")
            else
                minetest.chat_send_player(name, "[syncpath] Project '"..param.."' does not exist or could not be parsed")
            end
        else
            minetest.chat_send_player(name, "[syncpath] No project name given")
        end
    end
})

minetest.register_chatcommand("new", {
    description = "Start a new project.",
    func = function(name)
        syncpath.name = nil
        syncpath.music_name = ""
        syncpath.bpm = 140
        syncpath.path = {}
        minetest.chat_send_player(name, "[syncpath] New project created")
    end
})
