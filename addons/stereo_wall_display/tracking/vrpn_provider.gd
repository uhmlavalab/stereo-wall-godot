# Copyright (c) 2026 Laboratory for Advanced Visualizations and Applications (LAVA)
# University of Hawaii. All rights reserved.
# Licensed under the MIT License. See LICENSE file for details.

class_name VRPNProvider
extends TrackingProvider
## VRPN (Virtual Reality Peripheral Network) tracking provider.
##
## Connects to a VRPN server and receives tracker position updates.
## VRPN is commonly used in research/academic VR setups with systems like
## OptiTrack, Vicon, or other motion capture systems.
##
## @experimental This provider is a stub and requires full protocol implementation.

## IP address of the VRPN server.
var server_ip: String = "127.0.0.1"
## Port number of the VRPN server (default 3883).
var server_port: int = 3883
## Name of the tracker device on the VRPN server.
var tracker_name: String = "Tracker0"
## Sensor index on the tracker (for multi-sensor trackers).
var sensor_index: int = 0

var _udp: PacketPeerUDP
var _connected: bool = false

## Connects to the VRPN server. Returns true if connection initiated.
func start() -> bool:
	print("[VRPN] Connecting to %s:%d, tracker: %s@%d" % [server_ip, server_port, tracker_name, sensor_index])
	
	# TODO: Implement VRPN client protocol
	# VRPN uses a custom binary protocol over TCP/UDP
	
	_udp = PacketPeerUDP.new()
	var err = _udp.connect_to_host(server_ip, server_port)
	if err != OK:
		push_error("[VRPN] Failed to connect: %s" % error_string(err))
		return false
	
	_connected = true
	_is_tracking = false
	print("[VRPN] Connection initiated (stub - not fully implemented)")
	return true

## Disconnects from the VRPN server and cleans up.
func stop():
	if _udp:
		_udp.close()
		_udp = null
	_connected = false
	_is_tracking = false
	print("[VRPN] Disconnected")

## Polls for new tracker data and returns the latest position.
func poll() -> Vector3:
	if not _connected or not _udp:
		return _last_position
	
	# TODO: Implement VRPN packet parsing
	# Check for incoming packets
	while _udp.get_available_packet_count() > 0:
		var packet = _udp.get_packet()
		_parse_vrpn_packet(packet)
	
	return _last_position

## Parses a VRPN packet and extracts position data.
func _parse_vrpn_packet(packet: PackedByteArray):
	# TODO: Parse VRPN binary protocol
	# VRPN message format (simplified):
	# - Message type (4 bytes)
	# - Sender ID (4 bytes)
	# - Timestamp (8 bytes)
	# - Payload (variable)
	#
	# For tracker position:
	# - Sensor number (4 bytes)
	# - Position x, y, z (3 x 8 bytes doubles)
	# - Quaternion x, y, z, w (4 x 8 bytes doubles)
	
	if packet.size() < 8:
		return
	
	# Stub: actual parsing would go here
	pass

## Returns true if connected and receiving valid data.
func is_tracking() -> bool:
	return _is_tracking and _connected

## Returns a human-readable connection status.
func get_status() -> String:
	if not _connected:
		return "Disconnected"
	elif not _is_tracking:
		return "Connected, waiting for data..."
	else:
		return "Tracking"
