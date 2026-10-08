@tool
extends EditorPlugin
## Adds a warning note at the top of the rig's Wall group in the Inspector.

var _note := WallNote.new()


func _enter_tree() -> void:
	add_inspector_plugin(_note)


func _exit_tree() -> void:
	remove_inspector_plugin(_note)


class WallNote extends EditorInspectorPlugin:
	func _can_handle(object: Object) -> bool:
		return object is StereoWallRig

	func _parse_group(_object: Object, group: String) -> void:
		if group != "Wall":
			return
		var path := StereoWallConfig.folder().path_join(StereoWallConfig.FILE_NAME)
		var label := Label.new()
		label.text = "Don't change unless you know what you're doing. Hover for details.\n" + (
			"This computer has a machine config, and its values win here." if FileAccess.file_exists(path)
			else "No machine config on this computer, so these values are used.")
		label.tooltip_text = """These describe the physical wall, in meters, measured from the sweet spot
(the floor spot where the viewer stands). The defaults are LAVA lab's wall.

Each computer can have a machine config file. Any value set there overrides
these, so the wall PC always uses its own real measurements:
  Windows:    C:\\StereoWallGodot\\STEREO_CONFIG_GODOT.cfg
  Mac/Linux:  ~/StereoWallGodot/STEREO_CONFIG_GODOT.cfg
This computer: %s

These values are only used where that file is missing (or leaves a key out):
the editor preview, Edit mode, and builds run on a computer with no config.

To set up a real wall, edit the config file on the wall PC instead
(see wall_kit/README.md), and copy it to each developer's computer so the
editor shows the right wall.""" % path
		label.mouse_filter = Control.MOUSE_FILTER_STOP  # Labels ignore the mouse by default, which hides the tooltip
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", Color(1, 0.7, 0.2))
		add_custom_control(label)
