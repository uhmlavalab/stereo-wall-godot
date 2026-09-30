@tool
extends EditorPlugin
## Adds the stereo wall hotkeys to Project Settings > Input Map so they can be rebound.

const Rig := preload("res://addons/stereo_wall_display/stereo_wall_rig.gd")


func _enable_plugin() -> void:
	for action: String in Rig.ACTIONS:
		var setting := "input/" + action
		if not ProjectSettings.has_setting(setting):
			var key := InputEventKey.new()
			key.physical_keycode = Rig.ACTIONS[action]
			ProjectSettings.set_setting(setting, {"deadzone": 0.5, "events": [key]})
	ProjectSettings.save()


func _disable_plugin() -> void:
	for action: String in Rig.ACTIONS:
		ProjectSettings.set_setting("input/" + action, null)
	ProjectSettings.save()
