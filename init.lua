syncpath = {}

syncpath.path = {}
syncpath.mode = "linear"
syncpath.bpm = 140
syncpath.active = false
syncpath.starttime = 0
syncpath.music_handle = nil
syncpath.music_name = ""
syncpath.name = nil

syncpath.show_keyframes = true
syncpath.show_path_beams = true

syncpath.min_beam_segments = 8
-- Using a random value every time the path beams are upadated so that the old entities know if they need to be removed.
syncpath.random_path_id = nil

local lerp = function(pos1, pos2, t)
    return pos1 + (pos2 - pos1) * t
end

syncpath.path_function = function(synctime)
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
        if i == 2 and t <= 0.5 or i == #syncpath.path and t >= 0.5 or keyframe.interpolation == "linear" and t >= 0.5 or prev_keyframe.interpolation == "linear" and t <= 0.5 then
            return lerp(prev_keyframe.position, keyframe.position, t)
        else -- TODO make the if statements make more sense
            if t >= 0.5 then
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
        visual_size = vector.new(0,0,0),
        textures = {"default_dirt.png^[opacity:0"},
        pointable = false,
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
            local path_pos = syncpath.path_function(synctime)
            if path_pos then
                self.object:set_pos(path_pos)
            else
                syncpath.active = false
                minetest.chat_send_all("[syncpath] Sync finished")
            end
        end
        for _, obj in pairs(self.object:get_children()) do
            if obj:is_player() then
                local control = obj:get_player_control()
                if control.up or control.down or control.left or control.right then
                    obj:set_detach()
                    minetest.sound_stop(syncpath.music_handle)
                    if syncpath.active then
                        syncpath.active = false
                        minetest.chat_send_player(obj:get_player_name(), "[syncpath] Sync stopped because the user moved.")
                    end
                    self.object:remove()
                    return
                end
            end
        end
    end,
})

dofile(minetest.get_modpath("syncpath") .. "/commands.lua")
dofile(minetest.get_modpath("syncpath") .. "/short_commands.lua")
dofile(minetest.get_modpath("syncpath") .. "/tutorial.lua")