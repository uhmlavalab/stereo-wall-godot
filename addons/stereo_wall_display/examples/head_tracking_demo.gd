extends Node3D
## Head tracking demo: an overview camera watches the rig, so you can see the
## tracked head (green sphere) move in front of the wall (blue rectangle).
## Start the head tracker first, then press F6 (Fn+F6 on a Mac) to calibrate.

@onready var rig: StereoWallRig = $Example/StereoWallRig


func _ready() -> void:
	rig.get_node("Room/Head/HeadGizmo").visible = true
	rig.tracker.enabled = true
	$OverviewCamera.look_at_from_position(Vector3(4, 3, 2.5), Vector3(0, 1.5, -1))
	$OverviewCamera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
