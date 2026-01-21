# Copyright (c) 2026 Laboratory for Advanced Visualizations and Applications (LAVA)
# University of Hawaii. All rights reserved.
# Licensed under the MIT License. See LICENSE file for details.

class_name TrackingProvider
extends RefCounted
## Base class for head tracking providers.
##
## Subclass this to implement different tracking systems (VRPN, Vive Tracker, etc.).
## Override start(), stop(), poll(), is_tracking(), and get_status() methods.

## Emitted when a new tracking position is received.
signal tracking_updated(position: Vector3)
## Emitted when tracking is lost (e.g., tracker goes out of view).
signal tracking_lost
## Emitted when tracking is acquired after being lost.
signal tracking_acquired

var _is_tracking: bool = false
var _last_position: Vector3 = Vector3.ZERO

## Starts the tracking system. Returns true if initialization succeeded.
func start() -> bool:
	push_warning("TrackingProvider.start() not implemented")
	return false

## Stops the tracking system and releases resources.
func stop():
	_is_tracking = false

## Polls for the latest head position. Call this each frame.
func poll() -> Vector3:
	return _last_position

## Returns true if currently receiving valid tracking data.
func is_tracking() -> bool:
	return _is_tracking

## Returns a human-readable status string for debugging/display.
func get_status() -> String:
	return "Not implemented"
