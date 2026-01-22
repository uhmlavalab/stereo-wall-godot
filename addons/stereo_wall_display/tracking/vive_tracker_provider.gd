# Copyright (c) 2026 Laboratory for Advanced Visualizations and Applications (LAVA)
# University of Hawaii. All rights reserved.
# Licensed under the MIT License. See LICENSE file for details.

class_name ViveTrackerProvider
extends TrackingProvider
## Vive Tracker provider using OpenXR/SteamVR.
##
## Uses a Vive Tracker assigned to a specific role in SteamVR.
## Set tracker roles in SteamVR → Settings → Controllers → Manage Trackers.
## Falls back to static head position if no tracker is found.
## Requires SteamVR running and Godot OpenXR plugin enabled.

## Available tracker roles in SteamVR
enum TrackerRole {
	ANY,         ## Use first available tracker
	LEFT_FOOT,
	RIGHT_FOOT,
	LEFT_SHOULDER,
	RIGHT_SHOULDER,
	LEFT_ELBOW,
	RIGHT_ELBOW,
	LEFT_KNEE,
	RIGHT_KNEE,
	WAIST,
	CHEST,
	CAMERA,
	KEYBOARD
}

## Which tracker role to use (set in SteamVR's Manage Trackers)
var tracker_role: TrackerRole = TrackerRole.CHEST

## OpenXR path mappings for each role
const ROLE_PATHS = {
	TrackerRole.LEFT_FOOT: "/user/vive_tracker_htcx/role/left_foot",
	TrackerRole.RIGHT_FOOT: "/user/vive_tracker_htcx/role/right_foot",
	TrackerRole.LEFT_SHOULDER: "/user/vive_tracker_htcx/role/left_shoulder",
	TrackerRole.RIGHT_SHOULDER: "/user/vive_tracker_htcx/role/right_shoulder",
	TrackerRole.LEFT_ELBOW: "/user/vive_tracker_htcx/role/left_elbow",
	TrackerRole.RIGHT_ELBOW: "/user/vive_tracker_htcx/role/right_elbow",
	TrackerRole.LEFT_KNEE: "/user/vive_tracker_htcx/role/left_knee",
	TrackerRole.RIGHT_KNEE: "/user/vive_tracker_htcx/role/right_knee",
	TrackerRole.WAIST: "/user/vive_tracker_htcx/role/waist",
	TrackerRole.CHEST: "/user/vive_tracker_htcx/role/chest",
	TrackerRole.CAMERA: "/user/vive_tracker_htcx/role/camera",
	TrackerRole.KEYBOARD: "/user/vive_tracker_htcx/role/keyboard",
}

var _xr_interface: XRInterface
var _tracker: XRPositionalTracker
var _search_attempts: int = 0
var _max_search_attempts: int = 60  # ~1 second at 60fps before giving up initial search
var _xr_origin: XROrigin3D  # XR origin to keep session alive
var _xr_camera: XRCamera3D  # XR camera for session

## Initializes OpenXR and begins searching for the configured tracker role.
func start() -> bool:
	var role_name = TrackerRole.keys()[tracker_role]
	print("[ViveTracker] Starting - looking for role: %s" % role_name)
	
	_xr_interface = XRServer.find_interface("OpenXR")
	if not _xr_interface:
		push_warning("[ViveTracker] OpenXR not found. Enable in Project Settings → XR → OpenXR → Enabled")
		push_warning("[ViveTracker] Make sure SteamVR is running before starting the project")
		push_warning("[ViveTracker] Falling back to static head position")
		return false
	
	if not _xr_interface.is_initialized():
		if not _xr_interface.initialize():
			push_warning("[ViveTracker] Failed to initialize OpenXR - is SteamVR running?")
			push_warning("[ViveTracker] Falling back to static head position")
			return false
	
	print("[ViveTracker] OpenXR initialized successfully")
	
	# Set up minimal XR scene to keep session alive and get tracker poses
	_setup_xr_session()
	
	# Debug: List all available trackers at startup
	_debug_available_trackers()
	
	# Try to find the tracker immediately
	_find_tracker()
	
	if _tracker:
		_is_tracking = true
		print("[ViveTracker] Found tracker: %s" % _tracker.name)
	else:
		print("[ViveTracker] No tracker found yet for role '%s', will keep searching..." % role_name)
		print("[ViveTracker] Assign a tracker to this role in SteamVR → Settings → Controllers → Manage Trackers")
		# Listen for new trackers being connected
		if not XRServer.tracker_added.is_connected(_on_tracker_added):
			XRServer.tracker_added.connect(_on_tracker_added)
		if not XRServer.tracker_removed.is_connected(_on_tracker_removed):
			XRServer.tracker_removed.connect(_on_tracker_removed)
	
	return true

## Sets up a minimal XR scene to keep OpenXR session alive for tracker poses.
func _setup_xr_session():
	# Get the main viewport and enable XR on it
	var main_viewport = Engine.get_main_loop().root
	if main_viewport:
		main_viewport.use_xr = true
		print("[ViveTracker] Enabled XR on main viewport")
	
	# Create XR origin if it doesn't exist - needed for tracker session
	if not _xr_origin:
		_xr_origin = XROrigin3D.new()
		_xr_origin.name = "_ViveTrackerXROrigin"
		_xr_camera = XRCamera3D.new()
		_xr_camera.name = "_ViveTrackerXRCamera"
		_xr_origin.add_child(_xr_camera)
		# Add to scene but make invisible
		Engine.get_main_loop().root.add_child(_xr_origin)
		print("[ViveTracker] Created XR origin for tracker session")

## Searches for a Vive Tracker with the configured role.
func _find_tracker():
	var trackers = XRServer.get_trackers(XRServer.TRACKER_ANY)
	
	# If looking for a specific role, find that exact path
	if tracker_role != TrackerRole.ANY:
		var target_path = ROLE_PATHS.get(tracker_role, "")
		for tracker_name in trackers:
			if str(tracker_name) == target_path:
				_tracker = XRServer.get_tracker(tracker_name)
				print("[ViveTracker] Found tracker for role: %s" % tracker_name)
				return
		return  # Specific role not found
	
	# ANY mode: find first available Vive Tracker
	for tracker_name in trackers:
		var tracker = XRServer.get_tracker(tracker_name)
		if tracker and _is_vive_tracker(tracker):
			_tracker = tracker
			print("[ViveTracker] Auto-selected tracker: %s" % tracker.name)
			return
	
	# Fallback: any tracker that's not a controller or HMD
	for tracker_name in trackers:
		var tracker = XRServer.get_tracker(tracker_name)
		if tracker:
			var name_lower = tracker.name.to_lower()
			if "controller" in name_lower or "head" in name_lower or "hmd" in name_lower:
				continue
			_tracker = tracker
			print("[ViveTracker] Using tracker: %s" % tracker.name)
			return

## Checks if a tracker appears to be a Vive Tracker based on its name.
func _is_vive_tracker(tracker: XRPositionalTracker) -> bool:
	var name_lower = tracker.name.to_lower()
	return "vive" in name_lower or "tracker" in name_lower

## Called when a new tracker is detected by the XR system.
func _on_tracker_added(tracker_name: StringName, _type: int):
	if _tracker and _is_tracking:
		return  # Already have a working tracker
	
	print("[ViveTracker] New device detected: %s" % tracker_name)
	
	# Check if this matches our target role
	if tracker_role != TrackerRole.ANY:
		var target_path = ROLE_PATHS.get(tracker_role, "")
		if str(tracker_name) == target_path:
			_tracker = XRServer.get_tracker(tracker_name)
			_is_tracking = false  # Will be set true when we get valid pose data
			print("[ViveTracker] Now using: %s" % tracker_name)
	else:
		# ANY mode: accept any Vive Tracker
		var tracker = XRServer.get_tracker(tracker_name)
		if tracker:
			var name_lower = str(tracker_name).to_lower()
			if "tracker" in name_lower and "controller" not in name_lower:
				_tracker = tracker
				_is_tracking = false
				print("[ViveTracker] Now using: %s" % tracker_name)

## Called when a tracker is removed/disconnected.
func _on_tracker_removed(tracker_name: StringName, _type: int):
	if _tracker and _tracker.name == tracker_name:
		print("[ViveTracker] Tracker disconnected: %s" % tracker_name)
		_tracker = null
		_is_tracking = false
		tracking_lost.emit()
		# Try to find another tracker (only in ANY mode)
		if tracker_role == TrackerRole.ANY:
			_find_tracker()

## Stops tracking and disconnects signals.
func stop():
	if XRServer.tracker_added.is_connected(_on_tracker_added):
		XRServer.tracker_added.disconnect(_on_tracker_added)
	if XRServer.tracker_removed.is_connected(_on_tracker_removed):
		XRServer.tracker_removed.disconnect(_on_tracker_removed)
	
	# Clean up XR session nodes
	if _xr_origin and is_instance_valid(_xr_origin):
		_xr_origin.queue_free()
		_xr_origin = null
		_xr_camera = null
	
	# Disable XR on main viewport
	var main_viewport = Engine.get_main_loop().root
	if main_viewport:
		main_viewport.use_xr = false
	
	_tracker = null
	_is_tracking = false
	_search_attempts = 0
	print("[ViveTracker] Stopped")

## Polls the tracker for the latest position. Returns last known position if tracking lost.
func poll() -> Vector3:
	# If no tracker, keep searching periodically
	if not _tracker:
		_search_attempts += 1
		if _search_attempts % 60 == 0:  # Check every ~1 second
			_find_tracker()
			_debug_available_trackers()
		return _last_position
	
	# Try different methods to get tracker position
	var got_position = false
	
	# Method 1: Try get_pose with different pose names
	for pose_name in ["default", "aim", "grip"]:
		var pose = _tracker.get_pose(pose_name)
		if pose and pose.tracking_confidence > 0:
			_last_position = pose.transform.origin
			got_position = true
			if not _is_tracking:
				_is_tracking = true
				tracking_acquired.emit()
				print("[ViveTracker] Tracking acquired via pose '%s'" % pose_name)
			break
	
	# Debug: Print pose info periodically
	_search_attempts += 1
	if _search_attempts % 120 == 0:  # Every ~2 seconds
		_debug_tracker_state()
	
	if got_position:
		tracking_updated.emit(_last_position)
	else:
		if _is_tracking:
			_is_tracking = false
			tracking_lost.emit()
			print("[ViveTracker] Tracking lost - using last known position")
	
	return _last_position

## Debug: Print available trackers
func _debug_available_trackers():
	var trackers = XRServer.get_trackers(XRServer.TRACKER_ANY)
	print("[ViveTracker] Available trackers:")
	for tracker_name in trackers:
		print("  - %s" % tracker_name)

## Debug: Print current tracker state
func _debug_tracker_state():
	if not _tracker:
		return
	print("[ViveTracker] Tracker state for: %s" % _tracker.name)
	print("  has_pose: %s" % _tracker.has_pose("default"))
	var pose = _tracker.get_pose("default")
	if pose:
		print("  pose.tracking_confidence: %s" % pose.tracking_confidence)
		print("  pose.transform.origin: %s" % pose.transform.origin)
	else:
		print("  pose: null")

## Returns true if a tracker is found and actively providing pose data.
func is_tracking() -> bool:
	return _is_tracking and _tracker != null

## Returns a human-readable tracking status.
func get_status() -> String:
	var role_name = TrackerRole.keys()[tracker_role]
	if not _xr_interface:
		return "OpenXR not available"
	elif not _tracker:
		if tracker_role == TrackerRole.ANY:
			return "Searching for any tracker..."
		else:
			return "Waiting for %s tracker..." % role_name
	elif not _is_tracking:
		return "Tracker found, waiting for pose..."
	else:
		return "Tracking: %s" % _tracker.name
