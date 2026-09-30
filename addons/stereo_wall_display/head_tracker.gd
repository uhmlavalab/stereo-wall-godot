class_name StereoHeadTracker
extends RefCounted
## Receives head position over UDP in the OpenTrack format:
## 48 bytes = 6 little-endian doubles (x, y, z, yaw, pitch, roll). Only x, y, z are used.

var enabled := false
var raw_position := Vector3.ZERO  ## Latest tracker reading in meters (before calibration)
var head_position := Vector3.ZERO  ## Smoothed head position in room space

var _cfg: StereoWallConfig
var _udp := PacketPeerUDP.new()
var _last_packet_ms := -1
var _calib_sum := Vector3.ZERO
var _calib_count := -1  # -1 = not calibrating


func _init(cfg: StereoWallConfig) -> void:
	_cfg = cfg
	head_position = cfg.sweet_spot
	if _udp.bind(cfg.udp_port) != OK:
		push_warning("StereoWall: could not listen on UDP port %d." % cfg.udp_port)


## True if a packet arrived within the last timeout_sec.
func is_live() -> bool:
	return _last_packet_ms >= 0 and Time.get_ticks_msec() - _last_packet_ms < _cfg.timeout_sec * 1000


## Call once per frame. Reads all waiting packets and updates head_position.
func poll() -> void:
	while _udp.get_available_packet_count() > 0:
		var p := _udp.get_packet()
		if p.size() >= 24:
			var raw := Vector3(p.decode_double(0), p.decode_double(8), p.decode_double(16))
			# Undo the camera's tilt so "toward the wall" doesn't also read as up/down.
			raw_position = (raw * _cfg.axis_sign * _cfg.scale).rotated(Vector3.RIGHT, deg_to_rad(_cfg.camera_pitch))
			_last_packet_ms = Time.get_ticks_msec()
			if _calib_count >= 0:
				_calib_sum += raw_position
				_calib_count += 1

	var target := _cfg.sweet_spot
	if enabled and is_live():
		target += raw_position - _cfg.tracker_origin
	head_position = head_position.lerp(target, 1.0 - _cfg.smoothing)


## Start averaging tracker readings (viewer stands at the sweet spot).
func begin_calibration() -> void:
	_calib_sum = Vector3.ZERO
	_calib_count = 0


## Stop averaging: the average reading becomes the tracker origin.
func end_calibration() -> void:
	if _calib_count > 0:
		_cfg.tracker_origin = _calib_sum / _calib_count
	_calib_count = -1
