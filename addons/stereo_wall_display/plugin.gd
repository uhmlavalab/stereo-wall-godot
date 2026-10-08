@tool
extends EditorPlugin
## Adds a warning note above the rig's Display Wall settings in the Inspector.

var _note := WallNote.new()


func _enter_tree() -> void:
	add_inspector_plugin(_note)


func _exit_tree() -> void:
	remove_inspector_plugin(_note)


class WallNote extends EditorInspectorPlugin:
	func _can_handle(object: Object) -> bool:
		return object is StereoWallRig

	## Placed above the first Wall setting (group headers can't hold controls or tooltips).
	func _parse_property(_object: Object, _type: Variant.Type, name: String, _hint: PropertyHint,
			_hint_text: String, _usage: int, _wide: bool) -> bool:
		if name != "wall_width":
			return false
		var label := Label.new()
		label.text = "Don't change unless you know what you're doing. Hover for details."
		label.tooltip_text = """These describe the physical display wall, in meters, measured from
where the viewer stands. The defaults are LAVA lab's display wall.

In Godot (the editor and Play), these values are used, so you can preview a display wall.

In exported builds, the computer's machine config file wins for every value it sets,
so the display wall PC always uses its own real measurements:
  Windows:    C:\\StereoWallGodot\\STEREO_CONFIG_GODOT.cfg
  Mac/Linux:  ~/StereoWallGodot/STEREO_CONFIG_GODOT.cfg
These values only fill in what that file leaves out (or everything, if there is no file).

To set up a real display wall, edit the config file on the display wall PC (see wall_kit/README.md)."""
		label.mouse_filter = Control.MOUSE_FILTER_STOP  # Labels ignore the mouse by default, which hides the tooltip
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", Color(1, 0.7, 0.2))
		add_custom_control(label)
		return false  # Still show wall_width itself
