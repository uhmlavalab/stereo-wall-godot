@tool
extends Node3D
class_name StereoWallDisplay
## Stereoscopic 3D Camera Rig with Off-Axis Projection
##
## Parent this node to your player's head/camera position.
## The stereo cameras will follow this node's global transform.

# ═══════════════════════════════════════════════════════════════════════════════
#                              CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("General Settings")
@export var edit_mode: bool = true:  ## Development mode (single camera, normal resolution)
	set(v):
		edit_mode = v
		if is_inside_tree() and not Engine.is_editor_hint():
			_rebuild()

@export_group("Render Settings")
@export var eye_separation: float = 0.063  ## Inter-ocular distance (63mm average)
@export var swap_eyes: bool = false
@export var resolution_width: int = 4800 ## Resolution width per eye
@export var resolution_height: int = 1620 ## Resolution height per eye
@export var near_clip: float = 0.05
@export var far_clip: float = 5000.0

@export_group("Wall Physical Settings (in Meters)") 
@export var wall_width: float = 6.047   ## Physical wall width
@export var wall_height: float = 2.042  ## Physical wall height
@export var wall_distance: float = 2.282     ## Distance from viewer to wall

var show_editor_gizmos: bool = true

# ═══════════════════════════════════════════════════════════════════════════════
#                              INTERNAL
# ═══════════════════════════════════════════════════════════════════════════════

var _left_viewport: SubViewport
var _right_viewport: SubViewport
var _left_camera: Camera3D
var _right_camera: Camera3D
var _left_display: TextureRect
var _right_display: TextureRect
var _canvas: CanvasLayer
var _edit_camera: Camera3D
var _gizmo_holder: Node3D
var _screen_bl: Vector3
var _screen_br: Vector3
var _screen_tl: Vector3
var _initialized: bool = false

func _ready():
	if Engine.is_editor_hint():
		_setup_editor_gizmos()
	else:
		_initialize()

func _initialize():
	if _initialized: return
	
	if not edit_mode:
		_setup_production_window()
	
	if edit_mode:
		_setup_edit_camera()
	else:
		_setup_stereo_viewports()
	
	_initialized = true
	_print_config()

func _setup_production_window():
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_position(Vector2i(0, 0))
	DisplayServer.window_set_size(Vector2i(resolution_width * 2, resolution_height))
	DisplayServer.window_move_to_foreground()

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

# ═══════════════════════════════════════════════════════════════════════════════
#                              CAMERA SETUP
# ═══════════════════════════════════════════════════════════════════════════════

func _setup_edit_camera():
	_edit_camera = Camera3D.new()
	_edit_camera.name = "_EditCamera"
	_edit_camera.current = true
	_edit_camera.near = near_clip
	_edit_camera.far = far_clip
	_edit_camera.fov = 75
	add_child(_edit_camera)

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

func _create_viewport(vp_name: String, world: World3D) -> SubViewport:
	var vp = SubViewport.new()
	vp.name = vp_name
	vp.size = Vector2i(resolution_width, resolution_height)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.world_3d = world
	vp.handle_input_locally = false
	add_child(vp, false, Node.INTERNAL_MODE_BACK)
	return vp

func _create_stereo_camera(cam_name: String, parent: SubViewport) -> Camera3D:
	var cam = Camera3D.new()
	cam.name = cam_name
	cam.projection = Camera3D.PROJECTION_FRUSTUM
	cam.near = near_clip
	cam.far = far_clip
	parent.add_child(cam)
	return cam

func _create_display(disp_name: String, x_pos: int) -> TextureRect:
	var disp = TextureRect.new()
	disp.name = disp_name
	disp.stretch_mode = TextureRect.STRETCH_SCALE
	disp.position = Vector2(x_pos, 0)
	disp.size = Vector2(resolution_width, resolution_height)
	_canvas.add_child(disp)
	return disp

func _connect_viewport_textures():
	if _left_display and _left_viewport:
		_left_display.texture = _left_viewport.get_texture()
	if _right_display and _right_viewport:
		_right_display.texture = _right_viewport.get_texture()

# ═══════════════════════════════════════════════════════════════════════════════
#                              STEREO RENDERING
# ═══════════════════════════════════════════════════════════════════════════════

func _process(_delta):
	if Engine.is_editor_hint():
		_update_editor_gizmos()
	elif not edit_mode and _initialized and _left_camera and _right_camera:
		_update_stereo_cameras()

func _update_stereo_cameras():
	var head_pos = global_position
	var head_basis = global_transform.basis
	
	var half_w = wall_width / 2.0
	var half_h = wall_height / 2.0
	
	# Calculate screen corners relative to head position and orientation
	_screen_bl = head_pos + head_basis * Vector3(-half_w, -half_h, -wall_distance)
	_screen_br = head_pos + head_basis * Vector3(half_w, -half_h, -wall_distance)
	_screen_tl = head_pos + head_basis * Vector3(-half_w, half_h, -wall_distance)
	
	var head_right = head_basis.x
	var sep = eye_separation / 2.0
	_apply_offaxis_projection(_left_camera, head_pos - head_right * sep)
	_apply_offaxis_projection(_right_camera, head_pos + head_right * sep)

func _apply_offaxis_projection(camera: Camera3D, eye_pos: Vector3):
	var vr = (_screen_br - _screen_bl).normalized()
	var vu = (_screen_tl - _screen_bl).normalized()
	var vn = vr.cross(vu).normalized()
	
	var va = _screen_bl - eye_pos
	var vb = _screen_br - eye_pos
	var vc = _screen_tl - eye_pos
	
	var d = -va.dot(vn)
	if d <= near_clip: return
	
	var n = near_clip
	camera.set_frustum(
		vu.dot(vc) * n / d - vu.dot(va) * n / d,
		Vector2((vr.dot(vb) * n / d + vr.dot(va) * n / d) / 2.0, 
				(vu.dot(vc) * n / d + vu.dot(va) * n / d) / 2.0),
		n, far_clip
	)
	camera.global_transform = Transform3D(Basis(vr, vu, vn), eye_pos)

# ═══════════════════════════════════════════════════════════════════════════════
#                              EDITOR GIZMOS
# ═══════════════════════════════════════════════════════════════════════════════

func _setup_editor_gizmos():
	_gizmo_holder = Node3D.new()
	_gizmo_holder.name = "_EditorGizmos"
	add_child(_gizmo_holder)

func _update_editor_gizmos():
	if not show_editor_gizmos or wall_width <= 0 or wall_height <= 0:
		if _gizmo_holder:
			for c in _gizmo_holder.get_children(): c.queue_free()
		return
	if not _gizmo_holder:
		_setup_editor_gizmos()
	for c in _gizmo_holder.get_children(): c.queue_free()
	
	var half_w = wall_width / 2.0
	var half_h = wall_height / 2.0
	
	# Wall position relative to this node
	var wall_center = Vector3(0, 0, -wall_distance)
	
	# Wall mesh
	var wall_mesh = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(wall_width, wall_height)
	wall_mesh.mesh = quad
	wall_mesh.position = wall_center
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.2, 0.6, 1.0, 0.25)
	wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wall_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	wall_mesh.material_override = wall_mat
	_gizmo_holder.add_child(wall_mesh)
	
	# Eye markers
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	
	for i in 2:
		var eye_mesh = MeshInstance3D.new()
		eye_mesh.mesh = sphere
		eye_mesh.position = Vector3(eye_separation / 2.0 * (1 if i else -1), 0, 0)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.4, 0.3) if i else Color(0.3, 0.5, 1.0)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eye_mesh.material_override = mat
		_gizmo_holder.add_child(eye_mesh)
	
	# Forward direction indicator
	var arrow_mesh = MeshInstance3D.new()
	var arrow = CylinderMesh.new()
	arrow.top_radius = 0.02
	arrow.bottom_radius = 0.06
	arrow.height = 0.3
	arrow_mesh.mesh = arrow
	arrow_mesh.position = Vector3(0, 0, -0.3)
	arrow_mesh.rotation.x = PI / 2
	var arrow_mat = StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(0.2, 0.9, 0.3, 0.7)
	arrow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arrow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow_mesh.material_override = arrow_mat
	_gizmo_holder.add_child(arrow_mesh)

func _print_config():
	var mode = "EDIT" if edit_mode else "STEREO"
	print("\n╔══════════════════════════════════════════════════════════════╗")
	print("║          STEREO WALL DISPLAY - %s MODE                    ║" % mode)
	print("╠══════════════════════════════════════════════════════════════╣")
	print("║ Wall: %.2fm × %.2fm @ %.2fm distance" % [wall_width, wall_height, wall_distance])
	print("║ Eye separation: %.1fmm" % (eye_separation * 1000))
	if not edit_mode:
		print("║ Output: %d × %d (borderless @ 0,0)" % [resolution_width * 2, resolution_height])
	print("╚══════════════════════════════════════════════════════════════╝\n")
