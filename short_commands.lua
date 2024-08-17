
minetest.register_chatcommand("addkf", {
    description = "Short command of /add_keyframe",
    func = minetest.registered_chatcommands["add_keyframe"].func,
})

minetest.register_chatcommand("rmkf", {
    description = "Short command of /remove_keyframe",
    func = minetest.registered_chatcommands["remove_keyframe"].func,
})

minetest.register_chatcommand("vb", {
    description = "Short command of /view_bar",
    func = minetest.registered_chatcommands["view_bar"].func,
})

minetest.register_chatcommand("vt", {
    description = "Short command of /view_time",
    func = minetest.registered_chatcommands["view_time"].func,
})