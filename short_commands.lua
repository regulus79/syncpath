
minetest.register_chatcommand("addkf", {
    description = "Short command of /add_keyframe",
    params = minetest.registered_chatcommands["add_keyframe"].params,
    func = minetest.registered_chatcommands["add_keyframe"].func,
})

minetest.register_chatcommand("rmkf", {
    description = "Short command of /remove_keyframe",
    params = minetest.registered_chatcommands["remove_keyframe"].params,
    func = minetest.registered_chatcommands["remove_keyframe"].func,
})

minetest.register_chatcommand("vb", {
    description = "Short command of /view_bar",
    params = minetest.registered_chatcommands["view_bar"].params,
    func = minetest.registered_chatcommands["view_bar"].func,
})

minetest.register_chatcommand("vt", {
    description = "Short command of /view_time",
    params = minetest.registered_chatcommands["view_time"].params,
    func = minetest.registered_chatcommands["view_time"].func,
})