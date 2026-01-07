@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"StereoWallDisplay",
		"Node",
		preload("res://addons/stereo_wall/stereo_wall_display.gd"),
		preload("res://addons/stereo_wall/icon.svg")
	)

func _exit_tree():
	remove_custom_type("StereoWallDisplay")
