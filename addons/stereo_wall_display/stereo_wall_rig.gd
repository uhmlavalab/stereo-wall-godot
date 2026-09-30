@tool
class_name StereoWallRig
extends CharacterBody3D
## Drop-in stereo wall rig. Move and rotate this scene to set where the viewer starts.
##
## Edit mode (default when you press Play in Godot): one normal camera, no tracking,
## and the wall shown as a blue see-through rectangle. Stereo mode (default in exported
## builds): side-by-side output for the wall, with head tracking from the machine config.
## The Room node holds the wall and the head; the wall stays fixed in the room
## while the head moves with head tracking, giving correct off-axis parallax.

enum Mode { AUTO, EDIT, STEREO }
enum Controls { WALK, FLY, NONE }

## Hotkeys. Rebind them in Project Settings > Input Map.
const ACTIONS := {
	"stereo_help": KEY_F1,
	"stereo_toggle_mode": KEY_F2,
	"stereo_toggle_3d": KEY_F3,
	"stereo_swap_eyes": KEY_F4,
	"stereo_toggle_tracking": KEY_F5,
	"stereo_calibrate": KEY_F6,
	"stereo_reset": KEY_R,
	"stereo_quit": KEY_ESCAPE,
}

const HELP := """F1 Help   F2 Edit/Stereo   F3 3D on/off   F4 Swap eyes
F5 Head tracking   F6 Calibrate   R Reset   Esc Quit
WASD / Left stick = Move   Mouse / Right stick = Look   Shift / L3 = Fast
Walk: Space / A = Jump      Fly: E / RB = Up   Q / LB = Down"""

@export var mode := Mode.AUTO  ## Auto = Edit when run from Godot, Stereo in exported builds. Override with --edit / --stereo.
@export var show_wall := true:  ## Show the wall rectangle in the editor and in Edit mode
	set(value):
		show_wall = value
		if is_node_ready():
			_update_wall_gizmo()
@export var controls := Controls.WALK  ## Walk = FPS with gravity. Fly = move freely, no collisions. None = no built-in movement (move the rig from your own code).
@export var move_speed := 5.0  ## Meters per second (Shift / L3 doubles it)
@export var jump_velocity := 4.5  ## Walk mode
@export var look_sensitivity := 0.002  ## Mouse
@export var controller_look_speed := 0.05  ## Right stick
@export var controller_deadzone := 0.15

var cfg: StereoWallConfig
var tracker: StereoHeadTracker

var _stereo_3d := true
var _swap_eyes := false
var _show_help := false
var _message := ""  # Temporary HUD text (calibration, errors)
var _calibrating := false
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
	cfg = StereoWallConfig.new()
	# The room pivots around the sweet spot, so looking up/down rotates around the eyes.
	_room.position = cfg.sweet_spot
	_wall.position = Vector3(cfg.wall_offset_x, cfg.wall_center_height, -cfg.wall_distance) - cfg.sweet_spot
	_wall_gizmo.scale = Vector3(cfg.wall_width, cfg.wall_height, 1)
	_update_wall_gizmo()
	$Room/Head/HeadGizmo.visible = Engine.is_editor_hint()
	if Engine.is_editor_hint():
		return

	add_default_actions()
	tracker = StereoHeadTracker.new(cfg)
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


## Adds any hotkey actions the project hasn't defined itself.
static func add_default_actions() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			var key := InputEventKey.new()
			key.physical_keycode = ACTIONS[action]
			InputMap.add_action(action)
			InputMap.action_add_event(action, key)

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
	tracker.enabled = mode == Mode.STEREO and cfg.tracking_enabled  # Edit mode: no tracking (F5 to test)
	DisplayServer.window_set_title("Stereo Wall - " + ("EDIT MODE" if mode == Mode.EDIT else "STEREO"))
	# Big enough text to read on the wall during calibration.
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
	elif event.is_action_pressed("stereo_quit"):
		get_tree().quit()
	elif event.is_action_pressed("stereo_reset"):
		_reset_position()
	elif event.is_action_pressed("stereo_help"):
		_show_help = not _show_help
	elif event.is_action_pressed("stereo_toggle_mode"):
		mode = Mode.STEREO if mode == Mode.EDIT else Mode.EDIT
		_apply_mode()
	elif event.is_action_pressed("stereo_toggle_3d"):
		_stereo_3d = not _stereo_3d
		_flash("3D " + ("on" if _stereo_3d else "off (mono)"))
	elif event.is_action_pressed("stereo_swap_eyes"):
		_swap_eyes = not _swap_eyes
		_layout_displays()
		_flash("Eyes swapped" if _swap_eyes else "Eyes normal")
	elif event.is_action_pressed("stereo_toggle_tracking"):
		tracker.enabled = not tracker.enabled
		_flash("Head tracking " + ("on" if tracker.enabled else "off"))
	elif event.is_action_pressed("stereo_calibrate"):
		_calibrate()


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
#                              HEAD TRACKING & RENDERING
# ═══════════════════════════════════════════════════════════════════════════════

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	tracker.poll()
	_head.position = tracker.head_position - cfg.sweet_spot
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
#                              CALIBRATION & HUD
# ═══════════════════════════════════════════════════════════════════════════════

## Stand at the room center: the current tracker reading becomes the sweet spot.
func _calibrate() -> void:
	if _calibrating:
		return
	if not tracker.is_live():
		_flash("Calibration needs tracking data on UDP port %d" % cfg.udp_port)
		return
	_calibrating = true
	for i in range(3, 0, -1):
		_message = "CALIBRATING: stand at the room center and look at the wall... %d" % i
		await get_tree().create_timer(1.0).timeout

	_message = "CALIBRATING: hold still..."
	tracker.begin_calibration()
	await get_tree().create_timer(1.0).timeout
	tracker.end_calibration()
	cfg.tracking_enabled = true
	cfg.save()
	tracker.enabled = true
	_calibrating = false
	_flash("Calibrated. Saved to " + cfg.path)


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
	if mode == Mode.STEREO and cfg.path == "":
		lines.append("No machine config (%s) - using defaults" % StereoWallConfig.FILE_NAME)
	if tracker.enabled and not tracker.is_live():
		lines.append("Head tracking: no data on UDP port %d" % cfg.udp_port)
	if _message != "":
		lines.append(_message)
	if _show_help:
		lines.append(HELP)
	_hud.text = "\n".join(lines)
	# In stereo, repeat the text on the right-eye half so both eyes see it.
	_hud_right.visible = mode == Mode.STEREO
	_hud_right.position.x = cfg.resolution_width + _hud.position.x
	_hud_right.text = _hud.text
