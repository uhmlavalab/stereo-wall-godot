@tool
class_name StereoWallConfig
extends RefCounted
## Machine settings for the physical wall, read from STEREO_CONFIG_GODOT.cfg in
## C:/StereoWallGodot/ on Windows (~/StereoWallGodot/ elsewhere). The file is
## hand-edited and never written by the rig; missing keys use the defaults passed in
## (the rig's Wall settings in the Inspector) or the values below.

const FILE_NAME := "STEREO_CONFIG_GODOT.cfg"

## Which keys live in which [section] of the file.
const SECTIONS := {
	"display": ["resolution_width", "resolution_height", "window_position", "swap_eyes", "stereo_enabled"],
	"wall": ["wall_width", "wall_height", "wall_center_height", "wall_distance", "wall_offset_x"],
	"render": ["eye_separation", "near_clip", "far_clip"],
	"calibration": ["sweet_spot"],
}

var path := folder().path_join(FILE_NAME)
var loaded := false  ## False = file missing, using defaults

# [display]
var resolution_width := 4800  ## Pixels per eye
var resolution_height := 1620
var window_position := Vector2i.ZERO
var swap_eyes := false
var stereo_enabled := true
# [wall] (meters; room origin is the floor under the sweet spot, wall faces +Z). Defaults come from the rig.
var wall_width: float
var wall_height: float
var wall_center_height: float
var wall_distance: float
var wall_offset_x: float
# [render]
var eye_separation := 0.063
var near_clip := 0.05
var far_clip := 5000.0
# [calibration]
var sweet_spot: Vector3  ## Ideal eye position in the room


func _init(defaults := {}) -> void:
	for key in defaults:
		set(key, defaults[key])
	var file := ConfigFile.new()
	loaded = file.load(path) == OK
	if loaded:  # Otherwise keep the defaults
		for section in SECTIONS:
			for key in SECTIONS[section]:
				set(key, file.get_value(section, key, get(key)))


static func folder() -> String:
	return "C:/StereoWallGodot" if OS.get_name() == "Windows" else OS.get_environment("HOME").path_join("StereoWallGodot")
