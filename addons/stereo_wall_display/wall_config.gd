@tool
class_name StereoWallConfig
extends RefCounted
## Machine settings for the physical wall, read from STEREO_CONFIG_GODOT.cfg.
##
## Search order: $STEREO_WALL_CONFIG, then ~/STEREO_CONFIG_GODOT.cfg,
## then next to the executable. Missing file = built-in defaults below.

const FILE_NAME := "STEREO_CONFIG_GODOT.cfg"

## Which keys live in which [section] of the file.
const SECTIONS := {
	"display": ["resolution_width", "resolution_height", "window_position", "swap_eyes", "stereo_enabled"],
	"wall": ["wall_width", "wall_height", "wall_center_height", "wall_distance", "wall_offset_x"],
	"render": ["eye_separation", "near_clip", "far_clip"],
	"tracking": ["tracking_enabled", "udp_port", "smoothing", "timeout_sec", "axis_sign", "scale", "camera_pitch"],
	"calibration": ["tracker_origin", "sweet_spot"],
}

var path := ""  ## File this config was loaded from ("" = defaults)

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
var tracker_origin := Vector3.ZERO  ## Tracker reading at the sweet spot (set by calibrate)
var sweet_spot := Vector3(0, 1.64, 0)  ## Ideal eye position in the room


func _init() -> void:
	for candidate in _candidates():
		if FileAccess.file_exists(candidate):
			path = candidate
			break
	if path == "":
		return  # No file: keep the defaults
	var file := ConfigFile.new()
	file.load(path)
	for section in SECTIONS:
		for key in SECTIONS[section]:
			set(key, file.get_value(section, key, get(key)))


## Writes every setting back to the loaded file (or the first search location).
## Edits the file line by line so comments and layout are kept.
func save() -> void:
	if path == "":
		path = _candidates()[0]
	var text := FileAccess.get_file_as_string(path)
	var body := text.replace("\r\n", "\n").strip_edges(false, true)
	var lines := body.split("\n") if body != "" else PackedStringArray()
	for section in SECTIONS:
		var insert_at := -1  # Where missing keys of this section go, in order
		for key in SECTIONS[section]:
			var entry := "%s=%s" % [key, var_to_str(get(key))]
			var i := _find_line(lines, func(l: String) -> bool: return l.get_slice("=", 0).strip_edges() == key)
			if i >= 0:
				var comment := lines[i].find(";")  # Keep the comment in the same column
				lines[i] = entry if comment < 0 else entry + " ".repeat(maxi(1, comment - entry.length())) + lines[i].substr(comment)
				continue
			if insert_at < 0:
				insert_at = _find_line(lines, func(l: String) -> bool: return l.strip_edges() == "[%s]" % section) + 1
			if insert_at == 0:  # Section missing too: add it at the end
				lines.append_array(["", "[%s]" % section] if not lines.is_empty() else ["[%s]" % section])
				insert_at = lines.size()
			lines.insert(insert_at, entry)
			insert_at += 1
	var newline := "\r\n" if "\r\n" in text else "\n"
	FileAccess.open(path, FileAccess.WRITE).store_string(newline.join(lines) + newline)


func _find_line(lines: PackedStringArray, matches: Callable) -> int:
	for i in lines.size():
		if not lines[i].strip_edges().begins_with(";") and matches.call(lines[i]):
			return i
	return -1


func _candidates() -> Array[String]:
	var list: Array[String] = []
	var env := OS.get_environment("STEREO_WALL_CONFIG")
	if env != "":
		list.append(env)
	for home in [OS.get_environment("HOME"), OS.get_environment("USERPROFILE")]:
		if home != "":
			list.append(home.path_join(FILE_NAME))
	list.append(OS.get_executable_path().get_base_dir().path_join(FILE_NAME))
	return list
