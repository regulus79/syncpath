# syncpath

Syncpath is a mod for animating the player position along a path to be synced to music. Use it for making music-sync videos or cinematic fly-overs!

Supports both linear interpolation and a simple spline interpolation via double-lerping between the midpoints and corner of two segments.

Camera direction intepolation is not currently implemented, and may have to wait until the minetest engine allows for smooth look direction interpolation in lua.

## Commands

### Adding/Removing Keyframes
- `add_keyframe <bar> [linear | smooth]` - Add a keyframe at your current position at the given bar.
- `addkf <bar> [linear | smooth]` - Short Version of `add_keyframe`.
- `remove_keyframe <bar>` - Remove the keyframe at the given bar.
- `rmkf <bar>` - Short Version of `remove_keyframe`.
- `interpolation (linear | smooth)` - Set the interpolation mode for all keyframes.

### Sync Settings
- `music [<sound file name without extension>]` - Set the music for the sync. Sound file must exist in the sounds/ folder in .ogg format. If no arguments are given, it will print the current sound file.
- `bpm [<bpm>]` - Set the BPM of the sync to match the music. If no arguments are given, it will print the current bpm (default is 140 bpm).

### Start Sync
- `sync [<starting bar>]` - Start the sync. If an argument is given, it will start the sync from the given bar.

### Precision Syncing
- `view_bar <bar>` - Teleport to the given bar on the path.
- `vb <bar>` - Short version of `view_bar`.
- `view_time <seconds>` - Teleport to the given time, in seconds, on the path.
- `vt <seconds>` - Short version of `view_time`.

### Project
- `save [<name>]` - Save the current project under the given name. If no arguments are given but the project has been saved previously, then it will overwrite the previous save under the same name.
- `load <name>` - Load a project.
- `new` - Create a new project.

### Visualization
- `visuals` - Toggle the visibility of both the keyframe waypoints and the path beams.
- `keyframes` - Toggle the visibility of the keyframe waypoints.
- `path` - Toggle the visibility of the path beams.

### Tutorial
- `tutorial` - Start the tutorial.

### Debugging
- `print_path` - Print the path data.

## License

Syncpath is licensed under the MIT License, a copy of which can be found in the file named "LICENSE"
The sample songs, and any other media included for which the MIT License may not be suitible, are licensed under CC0 1.0, a copy of which can be found in the file named "CC0".