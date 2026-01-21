# Copyright (c) 2026 Laboratory for Advanced Visualizations and Applications (LAVA)
# University of Hawaii. All rights reserved.
# Licensed under the MIT License. See LICENSE file for details.

class_name ViveTrackerProvider
extends TrackingProvider
## Vive Tracker provider using OpenXR/SteamVR.
##
## Automatically detects and uses the first available Vive Tracker.
## Falls back to static head position if no tracker is found.
## Requires SteamVR running and Godot OpenXR plugin enabled.

var _xr_interface: XRInterface
var _tracker: XRPositionalTracker
var _search_attempts: int = 0
var _max_search_attempts: int = 60  # ~1 second at 60fps before giving up initial search

## Initializes OpenXR and begins searching for any available tracker.
func start() -> bool:
	print("[ViveTracker] Starting - will auto-detect first available tracker")
	
	_xr_interface = XRServer.find_interface("OpenXR")
	if not _xr_interface:
		push_warning("[ViveTracker] OpenXR interface not found - falling back to static head")
		return false
	
	if not _xr_interface.is_initialized():
		if not _xr_interface.initialize():
			push_warning("[ViveTracker] Failed to initialize OpenXR - falling back to static head")
			return false
	
	# Try to find a tracker immediately
	_find_any_tracker()
	
	if _tracker:
		_is_tracking = true
		print("[ViveTracker] Found tracker: %s" % _tracker.name)
	else:
		print("[ViveTracker] No tracker found yet, will keep searching...")
		# Listen for new trackers being connected
		if not XRServer.tracker_added.is_connected(_on_tracker_added):
			XRServer.tracker_added.connect(_on_tracker_added)
		if not XRServer.tracker_removed.is_connected(_on_tracker_removed):
			XRServer.tracker_removed.connect(_on_tracker_removed)
	
	return true

## Searches for any available Vive Tracker in the XR system.
func _find_any_tracker():
	var trackers = XRServer.get_trackers(XRServer.TRACKER_ANY)
	
	for tracker_name in trackers:
		var tracker = XRServer.get_tracker(tracker_name)
		if tracker and _is_vive_tracker(tracker):
			_tracker = tracker
			print("[ViveTracker] Auto-selected tracker: %s" % tracker.name)
			return
	
	# If no Vive Tracker found, try any tracker that's not a controller or HMD
	for tracker_name in trackers:
		var tracker = XRServer.get_tracker(tracker_name)
		if tracker:
			var name_lower = tracker.name.to_lower()
			# Skip controllers and headsets
			if "controller" in name_lower or "head" in name_lower or "hmd" in name_lower:
				continue
			_tracker = tracker
			print("[ViveTracker] Using non-controller tracker: %s" % tracker.name)
			return

## Checks if a tracker appears to be a Vive Tracker based on its name.
func _is_vive_tracker(tracker: XRPositionalTracker) -> bool:
	var name_lower = tracker.name.to_lower()
	return "vive" in name_lower and "tracker" in name_lower

## Called when a new tracker is detected by the XR system.
func _on_tracker_added(tracker_name: StringName, _type: int):
	if _tracker and _is_tracking:
		return  # Already have a working tracker
	
	var tracker = XRServer.get_tracker(tracker_name)
	if not tracker:
		return
	
	print("[ViveTracker] New device detected: %s" % tracker_name)
	
	# Accept any Vive Tracker, or any non-controller device
	var name_lower = str(tracker_name).to_lower()
	if "tracker" in name_lower or ("vive" in name_lower and "controller" not in name_lower):
		_tracker = tracker
		_is_tracking = false  # Will be set true when we get valid pose data
		print("[ViveTracker] Now using: %s" % tracker_name)

## Called when a tracker is removed/disconnected.
func _on_tracker_removed(tracker_name: StringName, _type: int):
	if _tracker and _tracker.name == tracker_name:
		print("[ViveTracker] Tracker disconnected: %s" % tracker_name)
		_tracker = null
		_is_tracking = false
		tracking_lost.emit()
		# Try to find another tracker
		_find_any_tracker()

## Stops tracking and disconnects signals.
func stop():
	if XRServer.tracker_added.is_connected(_on_tracker_added):
		XRServer.tracker_added.disconnect(_on_tracker_added)
	if XRServer.tracker_removed.is_connected(_on_tracker_removed):
		XRServer.tracker_removed.disconnect(_on_tracker_removed)
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
			_find_any_tracker()
		return _last_position
	
	# Get the tracker's pose
	var pose = _tracker.get_pose("default")
	if pose and pose.tracking_confidence > 0:
		if not _is_tracking:
			_is_tracking = true
			tracking_acquired.emit()
			print("[ViveTracker] Tracking acquired")
		
		_last_position = pose.transform.origin
		tracking_updated.emit(_last_position)
	else:
		if _is_tracking:
			_is_tracking = false
			tracking_lost.emit()
			print("[ViveTracker] Tracking lost - using last known position")
	
	return _last_position

## Returns true if a tracker is found and actively providing pose data.
func is_tracking() -> bool:
	return _is_tracking and _tracker != null

## Returns a human-readable tracking status.
func get_status() -> String:
	if not _xr_interface:
		return "OpenXR not available"
	elif not _tracker:
		return "Searching for tracker..."
	elif not _is_tracking:
		return "Tracker found, waiting for pose..."
	else:
		return "Tracking: %s" % _tracker.name
