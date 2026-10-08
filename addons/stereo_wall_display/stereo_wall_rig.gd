@tool
class_name StereoWallRig
extends CharacterBody3D
## Drop-in stereo wall rig. Move and rotate this scene to set where the viewer starts.
##
## Edit mode (default when you press Play in Godot): one normal camera, and the wall
## shown as a blue see-through rectangle. Stereo mode (default in exported builds):
## side-by-side output for the wall, using the machine config. The Room node holds
## the wall and the head; the head sits at the sweet spot, giving off-axis projection.

enum Mode { AUTO, EDIT, STEREO }
enum Controls { WALK, FLY, NONE }

## F1 help, one key per line in order. Movement lines only show when they apply.
const HELP_KEYS := ["F1   Help", "F2   Edit / Stereo", "F3   3D on / off", "F4   Swap eyes",
	"Esc   Quit"]
const HELP_MOVE := ["WASD / Left stick   Move", "Mouse / Right stick   Look",
	"Shift / L3   Fast", "R   Reset position"]
const HELP_WALK := ["Space / A   Jump"]
const HELP_FLY := ["E / RB   Up", "Q / LB   Down"]

@export var mode := Mode.AUTO  ## Auto = Edit when run from Godot, Stereo in exported builds. Override with --edit / --stereo.
@export var show_wall := true:  ## Show the wall rectangle in the editor and in Edit mode
	set(value):
		show_wall = value
		if is_node_ready():
			_update_wall_gizmo()
@export var controls := Controls.WALK:  ## Walk = FPS with gravity. Fly = move freely, no collisions. None = no built-in movement (move the rig from your own code).
	set(value):
		controls = value
		notify_property_list_changed()  # Show only the settings this control scheme uses
@export var move_speed := 5.0  ## Meters per second (Shift / L3 doubles it)
@export var jump_velocity := 4.5  ## Walk mode
@export var look_sensitivity := 0.002  ## Mouse
@export var controller_look_speed := 0.05  ## Right stick
@export var controller_deadzone := 0.15

@export_group("Wall")
## Width of the wall picture, in meters.  See the note at the top of this group.
@export var wall_width := 6.047:
	set(value): wall_width = value; _place_wall()
## Height of the wall picture, in meters.  See the note at the top of this group.
@export var wall_height := 2.042:
	set(value): wall_height = value; _place_wall()
## Floor to the middle of the wall picture, in meters.  See the note at the top of this group.
@export var wall_center_height := 1.75:
	set(value): wall_center_height = value; _place_wall()
## Sweet spot (where the viewer stands) to the wall, in meters.  See the note at the top of this group.
@export var wall_distance := 2.282:
	set(value): wall_distance = value; _place_wall()
## Wall center left (-) or right (+) of the sweet spot, in meters.  See the note at the top of this group.
@export var wall_offset_x := 0.0:
	set(value): wall_offset_x = value; _place_wall()
## The viewer's eye position in the room, in meters (y = eye height).  See the note at the top of this group.
@export var sweet_spot := Vector3(0, 1.64, 0):
	set(value): sweet_spot = value; _place_wall()
@export_group("")

const MOVEMENT_SETTINGS := ["move_speed", "jump_velocity", "look_sensitivity", "controller_look_speed", "controller_deadzone"]
## Inspector fallbacks for these machine config keys. The defaults are LAVA lab's wall.
const WALL_SETTINGS := ["wall_width", "wall_height", "wall_center_height", "wall_distance", "wall_offset_x", "sweet_spot"]

var cfg: StereoWallConfig

var _stereo_3d := true
var _swap_eyes := false
var _show_help := false
var _message := ""  # Temporary HUD text
var _start: Transform3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _stereo_nodes: Array[Node] = []  # Viewports and canvas, freed when leaving stereo
var _cameras: Array[Camera3D] = []  # [left, right]
var _displays: Array[TextureRect] = []  # [left, right]

@onready var _room: Node3D = $Room
@onready var _wall: Node3D = $Room/Wall
@onready var _wall_gizmo: Node3D = $Room/Wall/WallGizmo
@onready var _head: Node3D = $Room/Head
@onready var _edit_camera: Camera3D = $Room/Head/EditCamera
@onready var _hud: Label = $HUD/Label
@onready var _hud_right: Label = $HUD/LabelRightEye


func _ready() -> void:
	_place_wall()
	_update_wall_gizmo()
	$Room/Head/HeadGizmo.visible = Engine.is_editor_hint()
	if Engine.is_editor_hint():
		return

	_stereo_3d = cfg.stereo_enabled
	_swap_eyes = cfg.swap_eyes
	_start = transform
	_edit_camera.near = cfg.near_clip
	_edit_camera.far = cfg.far_clip
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	if "--stereo" in args:
		mode = Mode.STEREO
	elif "--edit" in args:
		mode = Mode.EDIT
	elif mode == Mode.AUTO:
		mode = Mode.EDIT if OS.has_feature("editor") else Mode.STEREO
	if controls != Controls.NONE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_mode()


# ═══════════════════════════════════════════════════════════════════════════════
#                              MODES & WINDOW
# ═══════════════════════════════════════════════════════════════════════════════

func _apply_mode() -> void:
	for node in _stereo_nodes:
		node.queue_free()
	_stereo_nodes.clear()
	_cameras.clear()
	_displays.clear()
	_edit_camera.current = mode == Mode.EDIT
	_update_wall_gizmo()
	DisplayServer.window_set_title("Stereo Wall - " + ("EDIT MODE" if mode == Mode.EDIT else "STEREO"))
	# Big enough text to read on the wall.
	for label in [_hud, _hud_right]:
		label.add_theme_font_size_override("font_size", 24 if mode == Mode.EDIT else int(cfg.resolution_height / 30.0))

	if mode == Mode.EDIT:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_size(Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")))
		return

	var eye_size := Vector2i(cfg.resolution_width, cfg.resolution_height)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_position(cfg.window_position)
	DisplayServer.window_set_size(Vector2i(eye_size.x * 2, eye_size.y))

	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	_stereo_nodes.append(canvas)
	for i in 2:
		var viewport := SubViewport.new()
		viewport.size = eye_size
		viewport.world_3d = get_viewport().world_3d
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		_stereo_nodes.append(viewport)

		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_FRUSTUM
		viewport.add_child(camera)
		_cameras.append(camera)

		var display := TextureRect.new()
		display.size = eye_size
		display.texture = viewport.get_texture()
		canvas.add_child(display)
		_displays.append(display)
	_layout_displays()


## Loads the machine config (the Wall settings fill in any keys it doesn't set) and places the wall.
func _place_wall() -> void:
	if not is_node_ready():
		return
	var defaults := {}
	for key in WALL_SETTINGS:
		defaults[key] = get(key)
	cfg = StereoWallConfig.new(defaults)
	# The room pivots around the sweet spot, so looking up/down rotates around the eyes.
	_room.position = cfg.sweet_spot
	_wall.position = Vector3(cfg.wall_offset_x, cfg.wall_center_height, -cfg.wall_distance) - cfg.sweet_spot
	_wall_gizmo.scale = Vector3(cfg.wall_width, cfg.wall_height, 1)


## Hides movement settings in the Inspector when they don't apply (values are kept).
func _validate_property(property: Dictionary) -> void:
	var name: String = property.name
	if (controls == Controls.NONE and name in MOVEMENT_SETTINGS) or (controls == Controls.FLY and name == "jump_velocity"):
		property.usage = PROPERTY_USAGE_NO_EDITOR


## The wall rectangle is a development aid: never shown in stereo output.
func _update_wall_gizmo() -> void:
	_wall_gizmo.visible = show_wall and (Engine.is_editor_hint() or mode != Mode.STEREO)


## Left eye on the left half of the window, unless swapped.
func _layout_displays() -> void:
	for i in _displays.size():
		_displays[i].position.x = cfg.resolution_width * (i if not _swap_eyes else 1 - i)

# ═══════════════════════════════════════════════════════════════════════════════
#                              INPUT
# ═══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseMotion and controls != Controls.NONE and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative * look_sensitivity)
	elif event is InputEventKey and event.pressed and not event.echo:
		_hotkey(event.physical_keycode)


## F1-F4 and Esc are fixed and always on, so apps shouldn't use them. R is a movement control.
func _hotkey(key: Key) -> void:
	match key:
		KEY_ESCAPE:
			get_tree().quit()
		KEY_R when controls != Controls.NONE:
			_reset_position()
		KEY_F1:
			_show_help = not _show_help
		KEY_F2:
			mode = Mode.STEREO if mode == Mode.EDIT else Mode.EDIT
			_apply_mode()
		KEY_F3:
			_stereo_3d = not _stereo_3d
			_flash("3D " + ("on" if _stereo_3d else "off (mono)"))
		KEY_F4:
			_swap_eyes = not _swap_eyes
			_layout_displays()
			_flash("Eyes swapped" if _swap_eyes else "Eyes normal")


func _reset_position() -> void:
	transform = _start
	velocity = Vector3.ZERO
	_room.rotation.x = 0


func _apply_look(delta: Vector2) -> void:
	rotate_y(-delta.x)
	_room.rotate_x(-delta.y)
	_room.rotation.x = clamp(_room.rotation.x, -PI / 2 + 0.1, PI / 2 - 0.1)


func _stick(x_axis: JoyAxis, y_axis: JoyAxis) -> Vector2:
	var stick := Vector2(Input.get_joy_axis(0, x_axis), Input.get_joy_axis(0, y_axis))
	return stick if stick.length() > controller_deadzone else Vector2.ZERO


func _get_movement_input() -> Vector2:
	var input := _stick(JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y)
	if Input.is_physical_key_pressed(KEY_W): input.y -= 1
	if Input.is_physical_key_pressed(KEY_S): input.y += 1
	if Input.is_physical_key_pressed(KEY_A): input.x -= 1
	if Input.is_physical_key_pressed(KEY_D): input.x += 1
	return input.limit_length(1.0)


func _pressed(key: Key, button: JoyButton) -> bool:
	return Input.is_physical_key_pressed(key) or Input.is_joy_button_pressed(0, button)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or controls == Controls.NONE:
		return
	_apply_look(_stick(JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y) * controller_look_speed * delta * 60)
	var input := _get_movement_input()
	var speed := move_speed * (2.0 if _pressed(KEY_SHIFT, JOY_BUTTON_LEFT_STICK) else 1.0)

	if controls == Controls.WALK:
		if not is_on_floor():
			velocity.y -= _gravity * delta
		elif _pressed(KEY_SPACE, JOY_BUTTON_A):
			velocity.y = jump_velocity
		var dir := transform.basis * Vector3(input.x, 0, input.y)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		move_and_slide()
	else:
		# Fly in the look direction, straight through walls
		var look := _room.global_basis
		var up := float(_pressed(KEY_E, JOY_BUTTON_RIGHT_SHOULDER)) - float(_pressed(KEY_Q, JOY_BUTTON_LEFT_SHOULDER))
		global_position += (look.x * input.x + look.z * input.y + Vector3.UP * up) * speed * delta

# ═══════════════════════════════════════════════════════════════════════════════
#                              RENDERING
# ═══════════════════════════════════════════════════════════════════════════════

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if mode == Mode.STEREO:
		_update_stereo_cameras()
	_update_hud()


func _update_stereo_cameras() -> void:
	var wall := _wall.global_transform
	var half := Vector2(cfg.wall_width, cfg.wall_height) / 2.0
	var bl := wall * Vector3(-half.x, -half.y, 0)
	var br := wall * Vector3(half.x, -half.y, 0)
	var tl := wall * Vector3(-half.x, half.y, 0)
	# Eyes sit along the wall's horizontal axis, like a viewer facing the wall.
	var sep := wall.basis.x.normalized() * (cfg.eye_separation / 2.0 if _stereo_3d else 0.0)
	_apply_offaxis_projection(_cameras[0], _head.global_position - sep, bl, br, tl)
	_apply_offaxis_projection(_cameras[1], _head.global_position + sep, bl, br, tl)


## Generalized perspective projection (Kooima): frustum from the eye through the wall corners.
func _apply_offaxis_projection(camera: Camera3D, eye: Vector3, bl: Vector3, br: Vector3, tl: Vector3) -> void:
	var vr := (br - bl).normalized()
	var vu := (tl - bl).normalized()
	var vn := vr.cross(vu).normalized()
	var va := bl - eye
	var vb := br - eye
	var vc := tl - eye

	var d := -va.dot(vn)  # Eye to wall distance
	if d <= cfg.near_clip:
		return
	var k := cfg.near_clip / d
	var left := vr.dot(va) * k
	var right := vr.dot(vb) * k
	var bottom := vu.dot(va) * k
	var top := vu.dot(vc) * k
	camera.set_frustum(top - bottom, Vector2((left + right) / 2.0, (bottom + top) / 2.0), cfg.near_clip, cfg.far_clip)
	camera.global_transform = Transform3D(Basis(vr, vu, vn), eye)

# ═══════════════════════════════════════════════════════════════════════════════
#                              HUD
# ═══════════════════════════════════════════════════════════════════════════════

## Shows a message on the HUD for a few seconds.
func _flash(text: String) -> void:
	_message = text
	await get_tree().create_timer(3.0).timeout
	if _message == text:
		_message = ""


func _update_hud() -> void:
	var lines: Array[String] = []
	if mode == Mode.EDIT:
		lines.append("EDIT MODE  -  F2 for stereo, F1 for help")
	if mode == Mode.STEREO and not cfg.loaded:
		lines.append("No machine config (%s) - using the rig's Wall settings" % cfg.path)
	if _message != "":
		lines.append(_message)
	if _show_help:
		lines.append_array(HELP_KEYS)
		if controls != Controls.NONE:
			lines.append_array(HELP_MOVE + (HELP_WALK if controls == Controls.WALK else HELP_FLY))
	_hud.text = "\n".join(lines)
	# In stereo, repeat the text on the right-eye half so both eyes see it.
	_hud_right.visible = mode == Mode.STEREO
	_hud_right.position.x = cfg.resolution_width + _hud.position.x
	_hud_right.text = _hud.text
