# Copyright (c) 2026 Laboratory for Advanced Visualizations and Applications (LAVA)
# University of Hawaii. All rights reserved.
# Licensed under the MIT License. See LICENSE file for details.

@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"StereoWallDisplay",
		"Node",
		preload("res://addons/stereo_wall_display/stereo_wall_display.gd"),
		preload("res://addons/stereo_wall_display/icon.svg")
	)

func _exit_tree():
	remove_custom_type("StereoWallDisplay")
