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

minetest.register_on_joinplayer(function(player)
    minetest.chat_send_player(player:get_player_name(), "[syncpath] If this is your first time using syncpath, it is recommended to check out the tutorial by typing '/tutorial'")
end)

local tutorial_active = false
local state = 0

local tutorial_message = function(name, message, delay)
    minetest.after(delay or 0, function()
        minetest.chat_send_player(name, minetest.colorize("#55ff55", message))
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
        tutorial_message(name, "[tutorial] Not too bad! Now add 3 more keyframes to make the path longer.", 3)
    elseif state == 4 then
        --tutorial_message(name, "[tutorial] If you want a keyframe to be smooth instead of a jagged corner, use '/add_keyframe <bar number> smooth'.", 13)
    elseif state == 6 then
        tutorial_message(name, "[tutorial] This path is looking great! Let's get some music going!", 1)
        tutorial_message(name, "[tutorial] To add music, use '/music <name of sound file>'. The mod comes with a few default tracks, so let's use one of them.", 3)
        tutorial_message(name, "[tutorial] Type '/music real15' to use real15.ogg. If you want to use your own music, put the sound file in the 'sounds' folder in the mod and then restart the game. Sound files must be converted to .ogg format before minetest can recognize them.", 6)
    elseif state == 7 then
        tutorial_message(name, "[tutorial] Oh also, we need to set the BPM of the music. 'real15.ogg' is 120 bpm, so type '/bpm 120'", 1)
    elseif state == 8 then
        tutorial_message(name, "[tutorial] Awesome, now type '/sync' to view your creation!", 1)
    elseif state == 9 then
        tutorial_message(name, "[tutorial] Now hide the path visuals by doing '/visuals'", 9)
    elseif state == 10 then
        tutorial_message(name, "[tutorial] And reshow them with '/visuals' again!", 1)
    elseif state == 11 then
        tutorial_message(name, "[tutorial] Just for practice, change the position of the last keyframe a bit. Fly to the position you want it to be, and run '/add_keyframe' again with the same bar number. (So if your last keyframe is bar 4, type '/add_keyframe 4' again)", 1)
    elseif state == 12 then
        tutorial_message(name, "[tutorial] And just for practice, remove that last keyframe with '/remove_keyframe <bar>' (short version: '/rmkf <bar>')", 1)
    elseif state == 13 then
        tutorial_message(name, "[tutorial] Nice. You know what, let's make the second keyframe be smooth. Replace the keyframe like last time, but with 'smooth' at the end of the command: '/add_keyframe 1 smooth'", 1)
    elseif state == 14 then
        tutorial_message(name, "[tutorial] That looks cool! Hmm, actually let's try making the whole path smooth. You can change the interpolation mode for all keyframes by doing '/interpolation smooth'", 1)
    elseif state == 15 then
        tutorial_message(name, "[tutorial] Very smooth! Now let's revert it by doing '/interpolation linear' to go back to jagged lines.", 1)
    elseif state == 16 then
        tutorial_message(name, "[tutorial] Back to normal! Ok, one last thing. You can use '/view_bar <bar>' to teleport to the part of the track at a certain bar. (short version: '/vb <bar>')", 1)
        tutorial_message(name, "[tutorial] So if you want to precisely place blocks every quarter bar to sync to your music, then you can do '/vb 0', place a block, '/vb 0.25', place a block '/vb 0.5', place a block, etc...", 8)
        tutorial_message(name, "[tutorial] Also, if you are working on syncing a long song, for '/sync' you can add the starting bar as an argument, so '/sync 32' would seek to bar 32.", 16)
        tutorial_message(name, "[tutorial] There are a few more commands we didn't cover, but you can see a full list using '/help'", 16)
        tutorial_message(name, "[tutorial] Oh also, don't forget to save your work! Do '/save my_awesome_track', and then when you rejoin do '/load my_awesome_track' to load your project.", 20)
        tutorial_message(name, "[tutorial] (ALSO you can do '/new' to create a blank project)", 25)
        tutorial_message(name, "[tutorial] Ok I think that's it for now. So uh, have fun syncing! (is that a word? idk haha)", 30)
        tutorial_message(name, "[tutorial] WAIT I FORGOT! If the game crashes for some reason, I would appreciate it if you submitted an issue on github. Helps me out. I think. Or maybe it doesn't. Idk. Thanks anyway lol", 37)
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
        elseif state == 3 or state == 4 or state == 5 then
            if cmd == "add_keyframe" or cmd == "addkf" then next_tutorial_state(name) end
        elseif state == 6 then
            if cmd == "music" then next_tutorial_state(name) end
        elseif state == 7 then
            if cmd == "bpm" then next_tutorial_state(name) end
        elseif state == 8 then
            if cmd == "sync" then next_tutorial_state(name) end
        elseif state == 9 or state == 10 then
            if cmd == "visuals" then next_tutorial_state(name) end
        elseif state == 11 then
            if cmd == "add_keyframe" or cmd == "addkf" then next_tutorial_state(name) end
        elseif state == 12 then
            if cmd == "remove_keyframe" or cmd == "rmkf" then next_tutorial_state(name) end
        elseif state == 13 then
            if (cmd == "add_keyframe" or cmd == "addkf") and string.find(params, "smooth") then next_tutorial_state(name) end
        elseif state == 14 then
            if cmd == "interpolation" then next_tutorial_state(name) end
        elseif state == 15 then
            if cmd == "interpolation" then next_tutorial_state(name) end
        end
    end
end)