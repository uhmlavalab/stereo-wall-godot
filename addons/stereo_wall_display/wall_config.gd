@tool
class_name StereoWallConfig
extends RefCounted
## Machine settings for the physical wall, from a fixed folder:
## C:/StereoWallGodot/ on Windows, ~/StereoWallGodot/ elsewhere. It holds two files:
## STEREO_CONFIG_GODOT.cfg (hand-edited, never written by the rig; missing = defaults below)
## and STEREO_CALIBRATION_GODOT.cfg (written by F6).

const FILE_NAME := "STEREO_CONFIG_GODOT.cfg"
const CALIBRATION_FILE_NAME := "STEREO_CALIBRATION_GODOT.cfg"

## Which keys live in which [section] of the file.
const SECTIONS := {
	"display": ["resolution_width", "resolution_height", "window_position", "swap_eyes", "stereo_enabled"],
	"wall": ["wall_width", "wall_height", "wall_center_height", "wall_distance", "wall_offset_x"],
	"render": ["eye_separation", "near_clip", "far_clip"],
	"tracking": ["tracking_enabled", "udp_port", "smoothing", "timeout_sec", "axis_sign", "scale", "camera_pitch"],
	"calibration": ["sweet_spot"],
}

var path := folder().path_join(FILE_NAME)
var calibration_path := folder().path_join(CALIBRATION_FILE_NAME)
var loaded := false  ## False = file missing, using defaults

# [display]
var resolution_width := 4800  ## Pixels per eye
var resolution_height := 1620
var window_position := Vector2i.ZERO
var swap_eyes := false
var stereo_enabled := true
# [wall] (meters; room origin is the floor under the sweet spot, wall faces +Z)
var wall_width := 6.047
var wall_height := 2.042
var wall_center_height := 1.75
var wall_distance := 2.282
var wall_offset_x := 0.0
# [render]
var eye_separation := 0.063
var near_clip := 0.05
var far_clip := 5000.0
# [tracking]
var tracking_enabled := false
var udp_port := 4242
var smoothing := 0.5  ## 0 = raw, closer to 1 = smoother but laggier
var timeout_sec := 0.5
var axis_sign := Vector3.ONE  ## Flip an axis with -1
var scale := 0.01  ## Tracker units to meters (OpenTrack sends cm)
var camera_pitch := 0.0  ## Degrees the camera tilts down (negative = tilted up)
# [calibration]
var tracker_origin := Vector3.ZERO  ## Tracker reading at the sweet spot (from the calibration file)
var sweet_spot := Vector3(0, 1.64, 0)  ## Ideal eye position in the room


func _init() -> void:
	var file := ConfigFile.new()
	loaded = file.load(path) == OK
	if loaded:  # Otherwise keep the defaults
		for section in SECTIONS:
			for key in SECTIONS[section]:
				set(key, file.get_value(section, key, get(key)))
	var calibration := ConfigFile.new()
	if calibration.load(calibration_path) == OK:
		tracker_origin = calibration.get_value("calibration", "tracker_origin", tracker_origin)


## Writes tracker_origin to the calibration file, which belongs to F6 alone,
## so the hand-edited config is never touched. Returns false on failure.
func save_calibration() -> bool:
	DirAccess.make_dir_recursive_absolute(calibration_path.get_base_dir())
	var file := FileAccess.open(calibration_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string("; Written by F6 (calibrate). Delete this file to reset calibration.\n[calibration]\ntracker_origin=%s\n" % var_to_str(tracker_origin))
	return true


static func folder() -> String:
	return "C:/StereoWallGodot" if OS.get_name() == "Windows" else OS.get_environment("HOME").path_join("StereoWallGodot")
