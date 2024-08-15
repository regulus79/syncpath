syncpath = {}

syncpath.path = {}
syncpath.mode = "linear"
syncpath.bpm = 140
syncpath.active = false
syncpath.starttime = 0
syncpath.music_handle = nil

syncpath.show_keyframes = true
syncpath.show_path_beams = true

local mod_storage = minetest.get_mod_storage()

local lerp = function(pos1, pos2, t)
    return pos1 + (pos2 - pos1) * t
end

local path_function = function(synctime)
    if synctime > syncpath.path[#syncpath.path].bar * 4 / syncpath.bpm * 60 then
        return
    end

    local i = 1
    local keyframe = syncpath.path[1]
    local keyframe_time = 0
    -- Find the next keyframe
    for idx, kf in ipairs(syncpath.path) do
        local kf_time = kf.bar * 4 / syncpath.bpm * 60
        if idx > 1 then
            local prev_kf_time = syncpath.path[idx - 1].bar * 4 / syncpath.bpm * 60
            if kf_time >= synctime and  prev_kf_time <= synctime then
                i = idx
                keyframe = kf
                keyframe_time = kf_time
                break
            end
        end
    end

    if i == 1 then
        return keyframe.position
    else
        local prev_keyframe = syncpath.path[i-1]
        local prev_keyframe_time = prev_keyframe.bar * 4 / syncpath.bpm * 60
        local t = (synctime - prev_keyframe_time) / (keyframe_time - prev_keyframe_time)
        if syncpath.mode == "linear" then
            return lerp(prev_keyframe.position, keyframe.position, t)
        elseif syncpath.mode == "simplespline" then
            if i == 2 and t <= 0.5  or i == #syncpath.path and t >= 0.5 then
                return lerp(prev_keyframe.position, keyframe.position, t)
            elseif t >= 0.5 then
                local next_keyframe = syncpath.path[i+1]
                -- TODO rename. these are not really handles, but more like the actual anchor points, since the path actually goes through these, not the keyframe positions.
                local handle1 = lerp(prev_keyframe.position, keyframe.position, 0.5)
                local handle2 = lerp(keyframe.position, next_keyframe.position, 0.5)
                local lerp1 = lerp(handle1, keyframe.position, t - 0.5)
                local lerp2 = lerp(keyframe.position, handle2, t - 0.5)
                return lerp(lerp1, lerp2, t - 0.5)
            elseif t <= 0.5 then
                local prev_prev_keyframe = syncpath.path[i-2]
                local handle1 = lerp(prev_prev_keyframe.position, prev_keyframe.position, 0.5)
                local handle2 = lerp(prev_keyframe.position, keyframe.position, 0.5)
                local lerp1 = lerp(handle1, prev_keyframe.position, t + 0.5)
                local lerp2 = lerp(prev_keyframe.position, handle2, t + 0.5)
                return lerp(lerp1, lerp2, t + 0.5)
            end
        end
    end
end

minetest.register_entity("syncpath:ride", {
    initial_properties = {
        visual = "cube",
        textures = {"default_dirt.png"},
        static_save = false,
    },
    on_rightclick = function(self, clicker)
        if not clicker:get_attach() then
            clicker:set_attach(self.object)
        else
            clicker:set_detach()
        end
    end,
    on_step = function(self, dtime)
        if syncpath.active then
            local synctime = minetest.get_us_time() / 1000000 - syncpath.starttime
            local path_pos = path_function(synctime)
            if path_pos then
                self.object:set_pos(path_pos)
            else
                syncpath.active = false
                minetest.chat_send_all("[syncpath] Sync finished")
            end
        end
    end,
})

minetest.register_chatcommand("spawn_ride", {
    description = "Spawn a sync ride",
    func = function(name)
        local pos = minetest.get_player_by_name(name):get_pos()
        minetest.add_entity(pos, "syncpath:ride")
    end
})


minetest.register_chatcommand("toggle_sync", {
    description = "Start or stop the sync ride movement",
    func = function(name)
        syncpath.active = not syncpath.active
        syncpath.starttime = minetest.get_us_time() / 1000000
        if syncpath.active then
            minetest.chat_send_player(name, "[syncpath] Syncpath movement started")
        else
            minetest.chat_send_player(name, "[syncpath] Syncpath movement stopped")
        end
    end
})

minetest.register_chatcommand("start_sync", {
    description = "Start a sync ride, attach the player to the ride, and start the music",
    func = function(name, param)
        local pos = minetest.get_player_by_name(name):get_pos()
        local obj = minetest.add_entity(pos, "syncpath:ride")
        minetest.get_player_by_name(name):set_attach(obj)

        syncpath.active = true
        syncpath.starttime = minetest.get_us_time() / 1000000

        if syncpath.music_handle then
            minetest.sound_stop(syncpath.music_handle)
        end
        syncpath.music_handle = minetest.sound_play({name = param}, {object = minetest.get_player_by_name(name)}, false)

        minetest.chat_send_player(name, "[syncpath] Sync started")
    end
})

minetest.register_chatcommand("stop_sync", {
    description = "Stop the sync ride and the music",
    func = function(name, param)
        syncpath.active = false
        minetest.get_player_by_name(name):set_detach(obj)
        if syncpath.music_handle then
            minetest.sound_stop(syncpath.music_handle)
        end
        minetest.chat_send_player(name, "[syncpath] Sync stopped")
    end
})

---
--- Visualization
---

-- TODO fix beams disappearing
minetest.register_entity("syncpath:path_beam", {
    initial_properties = {
        visual = "mesh",
        mesh = "cylinder.obj",
        textures = {"default_steel_block.png^[opacity:120"},
        use_texture_alpha = true,
    },
    on_activate = function(self, staticdata_serialized)
        local staticdata = minetest.deserialize(staticdata_serialized)
        if not staticdata then
            self.object:remove()
            return
        else
            if staticdata.offset then
                self.object:set_rotation(vector.dir_to_rotation(staticdata.offset))
                local props = self.object:get_properties()
                props.visual_size = vector.new(1, 1, vector.length(staticdata.offset)) * 10
                self.object:set_properties(props)
            end
        end
    end
})

local path_beams = {}

local setup_path_beams = function()
    for i, keyframe in ipairs(syncpath.path) do
        if i < #syncpath.path then
            table.insert(
                path_beams,
                minetest.add_entity(keyframe.position, "syncpath:path_beam", minetest.serialize({offset = syncpath.path[i+1].position - keyframe.position}))
            )
        end
    end
end

local remove_path_beams = function()
    for _, obj in pairs(path_beams) do
        obj:remove()
    end
end

local refresh_path_beams = function()
    remove_path_beams()
    if syncpath.show_path_beams then
        setup_path_beams()
    end
end

minetest.register_chatcommand("show_path_beams", {
    description = "Show the path beam visualizations",
    func = function(name)
        syncpath.show_path_beams = true
        refresh_path_beams()
    end
})

minetest.register_chatcommand("hide_path_beams", {
    description = "Hide the path beam visualizations",
    func = function(name)
        syncpath.show_path_beams = false
        refresh_path_beams()
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
            number = 0*(256^2) + 255*(256^1) + 0*(256^0)
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

local refresh_keyframe_hud_waypoints = function(player)
    remove_keyframe_hud_waypoints(player)
    if syncpath.show_keyframes then
        setup_keyframe_hud_waypoints(player)
    end
end

minetest.register_chatcommand("show_keyframes", {
    description = "Show the keyframe positions as waypoints on the hud",
    func = function(name)
        syncpath.show_keyframes = true
        refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
    end
})

minetest.register_chatcommand("hide_keyframes", {
    description = "Hide the keyframe positions on the hud",
    func = function(name)
        syncpath.show_keyframes = false
        refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
    end
})

---
--- Keyframe manipulation
---

minetest.register_chatcommand("add_keyframe", {
    description = "Add a keyframe for the position of the ride at time <bar>, given by the current bpm.",
    func = function(name, param)
        local position = minetest.get_player_by_name(name):get_pos()
        local bar = tonumber(param)
        if bar then
            local insert_pos = #syncpath.path + 1
            -- Remove any duplicates
            for i, keyframe in pairs(syncpath.path) do
                if bar == keyframe.bar then
                    minetest.chat_send_player(name, "[syncpath] Bar " .. bar .. " already has a keyframe (index " .. i .. "). Replacing")
                    table.remove(syncpath.path, i)
                end
            end
            -- Find the proper position to insert this keyframe
            for i, keyframe in pairs(syncpath.path) do
                if i == 1 then
                    if keyframe.bar > bar then
                        insert_pos = i
                    end
                elseif syncpath.path[i-1].bar < bar and keyframe.bar > bar then
                    insert_pos = i
                end
            end
            table.insert(syncpath.path, insert_pos, {
                bar = bar,
                position = position
            })
            minetest.chat_send_player(name, "[syncpath] Keyframe added on bar " .. bar .. " on index " .. insert_pos)
            refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
            refresh_path_beams()
        else
            minetest.chat_send_player(name, "[syncpath] Please provide a bar number to add this keyframe on")
        end
    end
})

minetest.register_chatcommand("remove_keyframe", {
    description = "Remove the keyframe at time <bar>, given by the current bpm.",
    func = function(name, param)
        local bar = tonumber(param)
        if bar then
            for i, keyframe in pairs(syncpath.path) do
                if keyframe.bar == bar then
                    table.remove(syncpath.path, i)
                    minetest.chat_send_player(name, "[syncpath] Removed keyframe at bar " .. bar)
                    refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
                    refresh_path_beams()
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
    func = function(name, param)
        local bar = tonumber(param)
        if bar then
            local synctime = bar * 4 / syncpath.bpm * 60 
            local path_pos = path_function(synctime)
            if path_pos then
                minetest.get_player_by_name(name):set_pos(path_pos)
            end
        end
    end
})

minetest.register_chatcommand("view_time", {
    description = "Teleport to the position on the path at the given time. The same as /view_bar, but in terms of seconds instead of bars.",
    func = function(name, param)
        local synctime = tonumber(param)
        if synctime then
            local path_pos = path_function(synctime)
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
    func = function(name, param)
        if param and tonumber(param) then
            syncpath.bpm = tonumber(param)
        else
            minetest.chat_send_player(name, "[syncpath] Current bpm: " .. tostring(syncpath.bpm))
        end
    end
})

minetest.register_chatcommand("interp_mode", {
    description = "Show or set the interpolation mode of the syncpath. Options: linear, simplespline",
    func = function(name, param)
        if param and (param == "linear" or param == "simplespline") then
            syncpath.mode = param
        else
            minetest.chat_send_player(name, "[syncpath] Current interpolation mode: " .. tostring(syncpath.mode))
        end
    end
})

---
--- Saving/Loading
---

minetest.register_chatcommand("save_path", {
    description = "Save the current path under <name>",
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
    description = "Save the current path under <name>",
    func = function(name, param)
        if param then
            syncpath.path = minetest.deserialize(mod_storage:get_string(param))
            if syncpath.path then
                for i, keyframe in pairs(syncpath.path) do
                    keyframe.position = vector.new(keyframe.position.x, keyframe.position.y, keyframe.position.z)
                end
                refresh_keyframe_hud_waypoints(minetest.get_player_by_name(name))
                refresh_path_beams()
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