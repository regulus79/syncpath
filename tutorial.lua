--[[
If this is your first time using syncpath, it is recommended to check out the tutorial by typing '/tutorial'

Welcome to the tutorial! Let's make some awesome music-synced maps!
To start off, type '/add_keyframe 0' to add a keyframe for bar 0 (the very start) of the music.

Nice, now fly to a different position and type '/add_keyframe 1' to add another keyframe at bar 1.
Also, pro tip: you can also use '/addkf 1' to do the same thing; it's just a little quicker to type.

Great! now test out your path with '/sync'

Not too bad! Now make your path longer by adding a couple more keyframes again with '/add_keyframe <bar number>' or '/addkf <bar number>'
If you want part of the path to be smooth instead of jagged lines, use '/add_keyframe <bar number> smooth'.
If you placed a keyframe where you didn't want it to go, you can use '/remove_keyframe <bar number>' to remove it. Or for short, "/rmkf <bar number>"

This path is looking great! Let's get some music going!
To add music, type '/music <name of sound file>'. The mod comes with a few default tracks, so let's use those.
Type '/music real15' to use real15.ogg. If you want to use your own music, put the sound file in the 'sounds' folder in the mod and then restart. Sounds must be converted to .ogg format before minetest can recognize them.

Oh also, we need to set the BPM of the music. 'real15' is 120 bpm, so type '/bpm 120'
Awesome, now type '/sync' to view your creation!

]]

local tutorial_active = false
local state = 0

local tutorial_message = function(name, message, delay)
    minetest.after(delay or 0, function()
        minetest.chat_send_player(name, minetest.colorize("#aaffaa", message))
    end)
end

minetest.register_chatcommand("tutorial", {
    description = "Start the syncpath tutorial",
    func = function(name)
        tutorial_active = true
        state = 0
        tutorial_message(name, "[tutorial] Welcome to the tutorial!  Let's make some awesome music-synced maps!", 0)
        tutorial_message(name, "[tutorial] To start off, type '/add_keyframe 0' to add a keyframe for bar 0 (the very start) of the music.", 3)
    end
})

local next_tutorial_state = function(name)
    state = state + 1
    if state == 1 then
        tutorial_message(name, "[tutorial] Nice, now fly to a different position and type '/add_keyframe 1' to add another keyframe at bar 1.", 1)
        tutorial_message(name, "[tutorial] Also, pro tip: you can also use '/addkf 1' to do the same thing; it's just a little quicker to type.", 5)
    elseif state == 2 then
        tutorial_message(name, "[tutorial] Great! now test out your path with '/sync'", 1)
    elseif state == 3 then
        tutorial_message(name, "[tutorial] Not too bad! Now make your path longer by adding a couple more keyframes again with '/add_keyframe <bar number>' or '/addkf <bar number>'", 3)
    elseif state == 4 then
        tutorial_message(name, "[tutorial] If you placed a keyframe where you didn't want it to go, you can use '/remove_keyframe <bar number>' to remove it. Or for short, '/rmkf <bar number>'", 3)
        tutorial_message(name, "[tutorial] If you want a keyframe to be smooth instead of a jagged corner, use '/add_keyframe <bar number> smooth'.", 13)
    elseif state == 5 then
        tutorial_message(name, "[tutorial] This path is looking great! Let's get some music going!", 1)
        tutorial_message(name, "[tutorial] To add music, type '/music <name of sound file>'. The mod comes with a few default tracks, so let's use those.", 3)
        tutorial_message(name, "[tutorial] Type '/music real15' to use real15.ogg. If you want to use your own music, put the sound file in the 'sounds' folder in the mod and then restart. Sounds must be converted to .ogg format before minetest can recognize them.", 6)
    elseif state == 6 then
        tutorial_message(name, "[tutorial] Oh also, we need to set the BPM of the music. 'real15' is 120 bpm, so type '/bpm 120'", 1)
    elseif state == 7 then
        tutorial_message(name, "[tutorial] Awesome, now type '/sync' to view your creation!", 1)
    elseif state == 8 then
        tutorial_message(name, "[tutorial] If you want to hide the path visuals, type '/visuals'", 4)
        tutorial_message(name, "[tutorial] You've reached the end of the tutorial!", 10)
        tutorial_active = false
    end

end

minetest.register_on_chatcommand(function(name, cmd, params)
    if tutorial_active then
        if state == 0 then
            if cmd == "add_keyframe" or cmd == "addkf" then next_tutorial_state(name) end
        elseif state == 1 then
            if cmd == "add_keyframe" or cmd == "addkf" then next_tutorial_state(name) end
        elseif state == 2 then
            if cmd == "sync" then next_tutorial_state(name) end
        elseif state == 3 or state == 4 then
            if cmd == "add_keyframe" or cmd == "addkf" then next_tutorial_state(name) end
        elseif state == 5 then
            if cmd == "music" then next_tutorial_state(name) end
        elseif state == 6 then
            if cmd == "bpm" then next_tutorial_state(name) end
        elseif state == 7 then
            if cmd == "sync" then next_tutorial_state(name) end
        end
    end
end)