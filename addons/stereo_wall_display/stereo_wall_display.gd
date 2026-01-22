# Copyright (c) 2026 Laboratory for Advanced Visualizations and Applications (LAVA)
# University of Hawaii. All rights reserved.
# Licensed under the MIT License. See LICENSE file for details.

@tool
extends Node3D
class_name StereoWallDisplay
## Stereoscopic 3D Wall Display with Off-Axis Projection
##
## A camera rig for CAVE-style displays. The wall is fixed relative to this node.
## Fly controls move the entire rig through the world.
## Tracking moves only the head within the rig, creating off-axis parallax.

## Available tracking methods for head position.
enum TrackingType { 
	NONE,         ## Static head position at fixed height
	VIVE_TRACKER, ## HTC Vive Tracker via SteamVR/OpenXR
	VRPN          ## VRPN network tracking protocol
}

# Configuration

@export_group("General Settings")
## When true, uses a single standard camera for development. When false, outputs side-by-side stereo.
@export var edit_mode: bool = true:
	set(v):
		edit_mode = v
		if is_inside_tree() and not Engine.is_editor_hint():
			_rebuild()

@export_group("Head Tracking")
## Selects the head tracking method. Additional options appear based on selection.
@export var tracking_type: TrackingType = TrackingType.NONE:
	set(v):
		tracking_type = v
		_stop_tracking()
		notify_property_list_changed()

# Dynamic tracking properties (shown/hidden based on tracking_type)
var static_head_height: float = 1.64
var vive_tracker_role: int = 10  # Default to CHEST (index 10 in TrackerRole enum)
var vrpn_server_ip: String = "127.0.0.1"
var vrpn_server_port: int = 3883
var vrpn_tracker_name: String = "Tracker0"
var vrpn_sensor_index: int = 0

@export_group("Fly Controls")
## Enables WASD/mouse/controller navigation to move the rig through the scene.
@export var enable_fly_controls: bool = true
## Movement speed in meters per second.
@export var move_speed: float = 5.0
## Mouse look sensitivity multiplier.
@export var look_sensitivity: float = 0.002
## Controller right stick look speed.
@export var controller_look_speed: float = 0.05
## Controller stick deadzone threshold.
@export var controller_deadzone: float = 0.15

@export_group("Render Settings")
## Distance between left and right eye in meters (default 63mm).
@export var eye_separation: float = 0.063
## Swaps left and right eye output for reversed stereo displays.
@export var swap_eyes: bool = false
## Horizontal resolution per eye in pixels.
@export var resolution_width: int = 4800
## Vertical resolution per eye in pixels.
@export var resolution_height: int = 1620
## Near clipping plane distance in meters.
@export var near_clip: float = 0.05
## Far clipping plane distance in meters.
@export var far_clip: float = 5000.0

@export_group("Wall Physical Settings (in Meters)") 
## Physical width of the display wall.
@export var wall_width: float = 6.047
## Physical height of the display wall.
@export var wall_height: float = 2.042
## Distance from the rig origin to the wall surface.
@export var wall_distance: float = 2.282
## Height of the wall center above the floor.
@export var wall_center_height: float = 1.75

# Internal State

var _left_viewport: SubViewport
var _right_viewport: SubViewport
var _left_camera: Camera3D
var _right_camera: Camera3D
var _left_display: TextureRect
var _right_display: TextureRect
var _canvas: CanvasLayer
var _edit_camera: Camera3D
var _gizmo_holder: Node3D
var _initialized: bool = false
var _mouse_captured: bool = false
var _head_position: Vector3 = Vector3.ZERO
var _pitch: float = 0.0
var _wall_bl: Vector3
var _wall_br: Vector3
var _wall_tl: Vector3
var _wall_tr: Vector3
var _tracking_provider: TrackingProvider

# Dynamic Property List

## Returns dynamic properties based on the selected tracking type.
func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	
	if tracking_type == TrackingType.NONE:
		props.append({
			"name": "static_head_height",
			"type": TYPE_FLOAT,
			"usage": PROPERTY_USAGE_DEFAULT,
		})
	elif tracking_type == TrackingType.VIVE_TRACKER:
		# Dropdown to select tracker role (matches ViveTrackerProvider.TrackerRole enum)
		props.append({
			"name": "vive_tracker_role",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Any,Left Foot,Right Foot,Left Shoulder,Right Shoulder,Left Elbow,Right Elbow,Left Knee,Right Knee,Waist,Chest,Camera,Keyboard"
		})
	elif tracking_type == TrackingType.VRPN:
		props.append({
			"name": "vrpn_server_ip",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
		})
		props.append({
			"name": "vrpn_server_port",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
		})
		props.append({
			"name": "vrpn_tracker_name",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
		})
		props.append({
			"name": "vrpn_sensor_index",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
		})
	
	return props

## Handles setting dynamic property values from the inspector.
func _set(property: StringName, value: Variant) -> bool:
	match property:
		"static_head_height": static_head_height = value
		"vive_tracker_role": vive_tracker_role = value
		"vrpn_server_ip": vrpn_server_ip = value
		"vrpn_server_port": vrpn_server_port = value
		"vrpn_tracker_name": vrpn_tracker_name = value
		"vrpn_sensor_index": vrpn_sensor_index = value
		_: return false
	return true

## Handles getting dynamic property values for the inspector.
func _get(property: StringName) -> Variant:
	match property:
		"static_head_height": return static_head_height
		"vive_tracker_role": return vive_tracker_role
		"vrpn_server_ip": return vrpn_server_ip
		"vrpn_server_port": return vrpn_server_port
		"vrpn_tracker_name": return vrpn_tracker_name
		"vrpn_sensor_index": return vrpn_sensor_index
	return null

# Lifecycle

## Called when the node enters the scene tree. Sets up editor gizmos or runtime cameras.
func _ready():
	_update_wall_corners()
	_head_position = Vector3(0, static_head_height, 0)
	if Engine.is_editor_hint():
		_setup_editor_gizmos()
	else:
		_initialize()

## Initializes the stereo display system at runtime.
func _initialize():
	if _initialized:
		return
	if not edit_mode:
		_setup_production_window()
	if edit_mode:
		_setup_edit_camera()
	else:
		_setup_stereo_viewports()
	_initialized = true
	if enable_fly_controls:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_mouse_captured = true
	_start_tracking()

## Destroys and recreates all runtime nodes. Called when edit_mode changes.
func _rebuild():
	for child in get_children():
		if child.name.begins_with("_"):
			child.queue_free()
	_left_viewport = null
	_right_viewport = null
	_left_camera = null
	_right_camera = null
	_edit_camera = null
	_initialized = false
	await get_tree().process_frame
	await get_tree().process_frame
	_initialize()

## Configures the window for production stereo output (borderless, positioned at 0,0).
func _setup_production_window():
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_position(Vector2i(0, 0))
	DisplayServer.window_set_size(Vector2i(resolution_width * 2, resolution_height))
	DisplayServer.window_move_to_foreground()

## Calculates the four corners of the wall in local space based on wall settings.
func _update_wall_corners():
	var half_w = wall_width / 2.0
	var half_h = wall_height / 2.0
	var wall_y = wall_center_height
	_wall_bl = Vector3(-half_w, wall_y - half_h, -wall_distance)
	_wall_br = Vector3(half_w, wall_y - half_h, -wall_distance)
	_wall_tl = Vector3(-half_w, wall_y + half_h, -wall_distance)
	_wall_tr = Vector3(half_w, wall_y + half_h, -wall_distance)

# Tracking

## Creates and starts the tracking provider based on the selected tracking type.
func _start_tracking():
	if tracking_type == TrackingType.NONE:
		return
	
	match tracking_type:
		TrackingType.VIVE_TRACKER:
			_tracking_provider = ViveTrackerProvider.new()
			_tracking_provider.tracker_role = vive_tracker_role
		TrackingType.VRPN:
			_tracking_provider = VRPNProvider.new()
			_tracking_provider.server_ip = vrpn_server_ip
			_tracking_provider.server_port = vrpn_server_port
			_tracking_provider.tracker_name = vrpn_tracker_name
			_tracking_provider.sensor_index = vrpn_sensor_index
	
	if _tracking_provider:
		if not _tracking_provider.start():
			print("[StereoWallDisplay] Tracking failed to start, using static head position")
			_tracking_provider = null

## Stops and cleans up the current tracking provider.
func _stop_tracking():
	if _tracking_provider:
		_tracking_provider.stop()
		_tracking_provider = null

## Polls the tracking provider and updates the head position. Falls back to static height if not tracking.
func _poll_tracking():
	if _tracking_provider:
		var tracked_pos = _tracking_provider.poll()
		if _tracking_provider.is_tracking():
			_head_position = tracked_pos
		# If not tracking, keep last known position (or static if never tracked)
	elif tracking_type != TrackingType.NONE:
		# Tracking was requested but provider failed - use static fallback
		_head_position = Vector3(0, static_head_height, 0)

# Tracking API (for external use)

## Sets the head position relative to the rig origin. Use for custom tracking integration.
func set_head_position(pos: Vector3):
	_head_position = pos

## Returns the current head position relative to the rig origin.
func get_head_position() -> Vector3:
	return _head_position

## Resets the head position to the static default height.
func reset_head_position():
	_head_position = Vector3(0, static_head_height, 0)

## Returns true if the tracking provider is actively receiving position data.
func is_tracking() -> bool:
	return _tracking_provider != null and _tracking_provider.is_tracking()

## Returns a human-readable status string from the tracking provider.
func get_tracking_status() -> String:
	if _tracking_provider:
		return _tracking_provider.get_status()
	return "Tracking disabled"

# Camera Setup

## Creates a single camera for edit mode development.
func _setup_edit_camera():
	_edit_camera = Camera3D.new()
	_edit_camera.name = "_EditCamera"
	_edit_camera.current = true
	_edit_camera.near = near_clip
	_edit_camera.far = far_clip
	_edit_camera.fov = 75
	_edit_camera.position = _head_position
	add_child(_edit_camera)

## Creates the stereo viewport system with left/right cameras and display textures.
func _setup_stereo_viewports():
	var main_world = get_viewport().world_3d
	_left_viewport = _create_viewport("_LeftViewport", main_world)
	_right_viewport = _create_viewport("_RightViewport", main_world)
	_left_camera = _create_stereo_camera("_LeftCamera", _left_viewport)
	_right_camera = _create_stereo_camera("_RightCamera", _right_viewport)
	_canvas = CanvasLayer.new()
	_canvas.name = "_StereoCanvas"
	_canvas.layer = 100
	add_child(_canvas, false, Node.INTERNAL_MODE_BACK)
	_left_display = _create_display("_LeftDisplay", 0 if not swap_eyes else resolution_width)
	_right_display = _create_display("_RightDisplay", resolution_width if not swap_eyes else 0)
	call_deferred("_connect_viewport_textures")

## Creates a SubViewport for rendering one eye's view.
func _create_viewport(vp_name: String, world: World3D) -> SubViewport:
	var vp = SubViewport.new()
	vp.name = vp_name
	vp.size = Vector2i(resolution_width, resolution_height)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.world_3d = world
	vp.handle_input_locally = false
	add_child(vp, false, Node.INTERNAL_MODE_BACK)
	return vp

## Creates a Camera3D configured for off-axis frustum projection.
func _create_stereo_camera(cam_name: String, parent: SubViewport) -> Camera3D:
	var cam = Camera3D.new()
	cam.name = cam_name
	cam.projection = Camera3D.PROJECTION_FRUSTUM
	cam.near = near_clip
	cam.far = far_clip
	parent.add_child(cam)
	return cam

## Creates a TextureRect to display one eye's viewport on screen.
func _create_display(disp_name: String, x_pos: int) -> TextureRect:
	var disp = TextureRect.new()
	disp.name = disp_name
	disp.stretch_mode = TextureRect.STRETCH_SCALE
	disp.position = Vector2(x_pos, 0)
	disp.size = Vector2(resolution_width, resolution_height)
	_canvas.add_child(disp)
	return disp

## Connects viewport textures to their display TextureRects (called deferred).
func _connect_viewport_textures():
	if _left_display and _left_viewport:
		_left_display.texture = _left_viewport.get_texture()
	if _right_display and _right_viewport:
		_right_display.texture = _right_viewport.get_texture()

# Input & Movement

## Handles keyboard and mouse input for fly controls.
func _input(event):
	if Engine.is_editor_hint() or not enable_fly_controls:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_R:
				position = Vector3.ZERO
				rotation = Vector3.ZERO
				_pitch = 0.0
				reset_head_position()
	if event is InputEventMouseMotion and _mouse_captured:
		rotate_y(-event.relative.x * look_sensitivity)
		var new_pitch = clamp(_pitch - event.relative.y * look_sensitivity, -PI/2 + 0.1, PI/2 - 0.1)
		_apply_pitch(new_pitch)

## Handles controller input and applies movement each physics frame.
func _physics_process(delta):
	if Engine.is_editor_hint() or not enable_fly_controls:
		return
	var look = _get_controller_look()
	if look.length() > 0:
		rotate_y(-look.x * controller_look_speed * delta * 60)
		var new_pitch = clamp(_pitch - look.y * controller_look_speed * delta * 60, -PI/2 + 0.1, PI/2 - 0.1)
		_apply_pitch(new_pitch)
	var input = _get_movement_input()
	if input.length() > 0:
		var forward = -global_transform.basis.z
		var right = global_transform.basis.x
		var vel = (forward * -input.y + right * input.x).normalized()
		global_position += vel * move_speed * delta

## Returns normalized movement input from keyboard WASD and controller left stick.
func _get_movement_input() -> Vector2:
	var input = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input.y -= 1
	if Input.is_key_pressed(KEY_S): input.y += 1
	if Input.is_key_pressed(KEY_A): input.x -= 1
	if Input.is_key_pressed(KEY_D): input.x += 1
	var stick = Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if stick.length() > controller_deadzone:
		input += stick
	return input.normalized() if input.length() > 1 else input

## Returns controller right stick input for look, with deadzone applied.
func _get_controller_look() -> Vector2:
	var stick = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	return stick if stick.length() > controller_deadzone else Vector2.ZERO

## Applies pitch rotation while keeping the head position stable in world space.
func _apply_pitch(new_pitch: float):
	var head_world_before = global_transform * _head_position
	_pitch = new_pitch
	rotation.x = _pitch
	var head_world_after = global_transform * _head_position
	global_position += head_world_before - head_world_after

# Stereo Rendering

## Main process loop. Updates gizmos in editor, polls tracking, and updates cameras at runtime.
func _process(_delta):
	if Engine.is_editor_hint():
		_update_wall_corners()
		_update_editor_gizmos()
	else:
		_poll_tracking()
		if _edit_camera:
			_edit_camera.position = _head_position
		if not edit_mode and _initialized and _left_camera and _right_camera:
			_update_stereo_cameras()

## Updates left and right stereo cameras with off-axis projection based on head position.
func _update_stereo_cameras():
	_update_wall_corners()
	var head_world = global_transform * _head_position
	var bl_world = global_transform * _wall_bl
	var br_world = global_transform * _wall_br
	var tl_world = global_transform * _wall_tl
	var head_right = global_transform.basis.x
	var sep = eye_separation / 2.0
	_apply_offaxis_projection(_left_camera, head_world - head_right * sep, bl_world, br_world, tl_world)
	_apply_offaxis_projection(_right_camera, head_world + head_right * sep, bl_world, br_world, tl_world)

## Computes and applies the off-axis frustum projection for a camera based on eye position and screen corners.
func _apply_offaxis_projection(camera: Camera3D, eye_pos: Vector3, screen_bl: Vector3, screen_br: Vector3, screen_tl: Vector3):
	var vr = (screen_br - screen_bl).normalized()
	var vu = (screen_tl - screen_bl).normalized()
	var vn = vr.cross(vu).normalized()
	var va = screen_bl - eye_pos
	var vb = screen_br - eye_pos
	var vc = screen_tl - eye_pos
	var d = -va.dot(vn)
	if d <= near_clip:
		return
	var n = near_clip
	var l = vr.dot(va) * n / d
	var r = vr.dot(vb) * n / d
	var b = vu.dot(va) * n / d
	var t = vu.dot(vc) * n / d
	camera.set_frustum(t - b, Vector2((l + r) / 2.0, (b + t) / 2.0), n, far_clip)
	camera.global_transform = Transform3D(Basis(vr, vu, vn), eye_pos)

# Editor Gizmos

## Creates the container node for editor visualization gizmos.
func _setup_editor_gizmos():
	_gizmo_holder = Node3D.new()
	_gizmo_holder.name = "_EditorGizmos"
	add_child(_gizmo_holder)

## Rebuilds editor gizmos showing the wall, head position, eyes, and view frustums.
func _update_editor_gizmos():
	if wall_width <= 0 or wall_height <= 0:
		if _gizmo_holder:
			for c in _gizmo_holder.get_children():
				c.queue_free()
		return
	if not _gizmo_holder:
		_setup_editor_gizmos()
	for c in _gizmo_holder.get_children():
		c.queue_free()
	if tracking_type == TrackingType.NONE:
		_head_position = Vector3(0, static_head_height, 0)
	
	# Wall
	var wall_center = (_wall_bl + _wall_br + _wall_tl + _wall_tr) / 4.0
	var wall_mesh = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(wall_width, wall_height)
	wall_mesh.mesh = quad
	wall_mesh.position = wall_center
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.2, 0.6, 1.0, 0.3)
	wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wall_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	wall_mesh.material_override = wall_mat
	_gizmo_holder.add_child(wall_mesh)
	
	# Head
	var head_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	head_mesh.mesh = sphere
	head_mesh.position = _head_position
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.2, 0.9, 0.3, 0.7)
	head_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	head_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	head_mesh.material_override = head_mat
	_gizmo_holder.add_child(head_mesh)
	
	# Eyes
	var eye_sphere = SphereMesh.new()
	eye_sphere.radius = 0.03
	eye_sphere.height = 0.06
	var left_eye_pos = _head_position + Vector3(-eye_separation / 2.0, 0, 0)
	var right_eye_pos = _head_position + Vector3(eye_separation / 2.0, 0, 0)
	for i in 2:
		var eye_mesh = MeshInstance3D.new()
		eye_mesh.mesh = eye_sphere
		eye_mesh.position = left_eye_pos if i == 0 else right_eye_pos
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.5, 1.0) if i == 0 else Color(1.0, 0.4, 0.3)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eye_mesh.material_override = mat
		_gizmo_holder.add_child(eye_mesh)

	# Frustum lines
	_draw_frustum_lines(left_eye_pos, Color(0.3, 0.5, 1.0, 0.5))
	_draw_frustum_lines(right_eye_pos, Color(1.0, 0.4, 0.3, 0.5))

## Draws frustum lines from an eye position to all wall corners.
func _draw_frustum_lines(eye_pos: Vector3, color: Color):
	var corners = [_wall_bl, _wall_br, _wall_tr, _wall_tl]
	for corner in corners:
		_gizmo_holder.add_child(_create_line(eye_pos, corner, color))
	for i in 4:
		_gizmo_holder.add_child(_create_line(corners[i], corners[(i + 1) % 4], color))

## Creates a line mesh between two points with the specified color.
func _create_line(from: Vector3, to: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	
	# Guard against zero-length lines which cause mesh errors
	if from.is_equal_approx(to):
		to = from + Vector3(0.001, 0, 0)
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()
	mesh_instance.mesh = immediate_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	return mesh_instance
