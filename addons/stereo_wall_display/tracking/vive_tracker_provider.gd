# Copyright (c) 2026 Laboratory for Advanced Visualizations and Applications (LAVA)
# University of Hawaii. All rights reserved.
# Licensed under the MIT License. See LICENSE file for details.

class_name ViveTrackerProvider
extends TrackingProvider
## Vive Tracker provider using OpenXR/SteamVR.
##
## Tracks a Vive Tracker attached to the user's head for CAVE-style displays.
## Requires SteamVR running and Godot OpenXR plugin enabled.
##
## @experimental This provider requires real hardware testing.

## Serial number of the Vive Tracker (e.g., "LHR-12345678"). Leave empty for auto-detect.
var tracker_serial: String = ""
## Role assigned to the tracker in SteamVR.
var tracker_role: String = "handheld_object"
## Use OpenXR (recommended) instead of legacy OpenVR.
var use_openxr: bool = true

var _xr_interface: XRInterface
var _tracker: XRPositionalTracker

## Initializes the XR interface and begins searching for the tracker.
func start() -> bool:
	print("[ViveTracker] Starting with serial: %s, role: %s" % [tracker_serial, tracker_role])
	
	if use_openxr:
		return _start_openxr()
	else:
		return _start_openvr()

## Initializes tracking via OpenXR (recommended path).
func _start_openxr() -> bool:
	_xr_interface = XRServer.find_interface("OpenXR")
	if not _xr_interface:
		push_error("[ViveTracker] OpenXR interface not found. Enable OpenXR in Project Settings.")
		return false
	
	if not _xr_interface.is_initialized():
		if not _xr_interface.initialize():
			push_error("[ViveTracker] Failed to initialize OpenXR")
			return false
	
	_find_tracker()
	
	if _tracker:
		_is_tracking = true
		print("[ViveTracker] Found tracker: %s" % _tracker.name)
		return true
	else:
		print("[ViveTracker] Tracker not found yet, will keep searching...")
		XRServer.tracker_added.connect(_on_tracker_added)
		return true

## Initializes tracking via legacy OpenVR (not implemented).
func _start_openvr() -> bool:
	push_warning("[ViveTracker] OpenVR legacy mode not implemented, use OpenXR")
	return false

## Searches for a matching tracker in the XR system.
func _find_tracker():
	for tracker_name in XRServer.get_trackers(XRServer.TRACKER_ANY):
		var tracker = XRServer.get_tracker(tracker_name)
		if tracker:
			if tracker_serial != "" and tracker_serial in tracker.name:
				_tracker = tracker
				return
			if tracker.description == tracker_role:
				_tracker = tracker
				return
	
	if tracker_serial == "":
		for tracker_name in XRServer.get_trackers(XRServer.TRACKER_ANY):
			var tracker = XRServer.get_tracker(tracker_name)
			if tracker and "vive_tracker" in tracker.name.to_lower():
				_tracker = tracker
				return

## Called when a new tracker is detected by the XR system.
func _on_tracker_added(tracker_name: StringName, type: int):
	if _tracker:
		return
	
	var tracker = XRServer.get_tracker(tracker_name)
	if not tracker:
		return
	
	print("[ViveTracker] New tracker detected: %s" % tracker_name)
	
	if tracker_serial != "" and tracker_serial in str(tracker_name):
		_tracker = tracker
		_is_tracking = true
		tracking_acquired.emit()
		print("[ViveTracker] Matched tracker by serial: %s" % tracker_name)
	elif tracker_serial == "" and "tracker" in str(tracker_name).to_lower():
		_tracker = tracker
		_is_tracking = true
		tracking_acquired.emit()
		print("[ViveTracker] Using tracker: %s" % tracker_name)

## Stops tracking and disconnects signals.
func stop():
	if XRServer.tracker_added.is_connected(_on_tracker_added):
		XRServer.tracker_added.disconnect(_on_tracker_added)
	_tracker = null
	_is_tracking = false
	print("[ViveTracker] Stopped")

## Polls the tracker for the latest position.
func poll() -> Vector3:
	if not _tracker:
		_find_tracker()
		return _last_position
	
	var pose = _tracker.get_pose("default")
	if pose and pose.tracking_confidence > 0:
		if not _is_tracking:
			_is_tracking = true
			tracking_acquired.emit()
		
		_last_position = pose.transform.origin
		tracking_updated.emit(_last_position)
	else:
		if _is_tracking:
			_is_tracking = false
			tracking_lost.emit()
	
	return _last_position

## Returns true if the tracker is found and actively tracking.
func is_tracking() -> bool:
	return _is_tracking and _tracker != null

## Returns a human-readable tracking status.
func get_status() -> String:
	if not _xr_interface:
		return "OpenXR not available"
	elif not _tracker:
		return "Searching for tracker..."
	elif not _is_tracking:
		return "Tracker found, no pose data"
	else:
		return "Tracking"
