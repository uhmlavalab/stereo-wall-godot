extends CharacterBody3D
class_name ExamplePlayer
## Simple FPS player controller for demonstrating StereoWallDisplay
##
## This is an example - use your own player controller in your project.

@export_group("Movement")
@export var move_speed: float = 5.0
@export var enable_gravity: bool = true

@export_group("Look")
@export var mouse_sensitivity: float = 0.002
@export var controller_sensitivity: float = 0.05
@export var controller_deadzone: float = 0.15

@onready var head: Node3D = $Head

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _mouse_captured: bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_R:
				position = Vector3.ZERO
				rotation = Vector3.ZERO
				head.rotation = Vector3.ZERO
				velocity = Vector3.ZERO
	
	if event is InputEventMouseMotion and _mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI/2 + 0.1, PI/2 - 0.1)

func _physics_process(delta):
	# Controller look
	var look = _get_controller_look()
	if look.length() > 0:
		rotate_y(-look.x * controller_sensitivity * delta * 60)
		head.rotate_x(-look.y * controller_sensitivity * delta * 60)
		head.rotation.x = clamp(head.rotation.x, -PI/2 + 0.1, PI/2 - 0.1)
	
	# Movement
	var input = _get_movement_input()
	
	if enable_gravity:
		if not is_on_floor():
			velocity.y -= _gravity * delta
		
		var dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
		velocity.x = dir.x * move_speed if dir else move_toward(velocity.x, 0, move_speed)
		velocity.z = dir.z * move_speed if dir else move_toward(velocity.z, 0, move_speed)
	else:
		# Fly mode
		var forward = -head.global_transform.basis.z
		var right = head.global_transform.basis.x
		var vel = forward * -input.y + right * input.x
		velocity = vel.normalized() * move_speed if vel.length() > 0 else Vector3.ZERO
	
	move_and_slide()

func _get_movement_input() -> Vector2:
	var input = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_W): input.y -= 1
	if Input.is_key_pressed(KEY_S): input.y += 1
	if Input.is_key_pressed(KEY_A): input.x -= 1
	if Input.is_key_pressed(KEY_D): input.x += 1
	
	var stick = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)
	if stick.length() > controller_deadzone:
		input += stick
	
	return input.normalized() if input.length() > 1 else input

func _get_controller_look() -> Vector2:
	var stick = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	return stick if stick.length() > controller_deadzone else Vector2.ZERO
