# Stereo Wall Display

A Godot 4.x addon for stereoscopic 3D rendering on large display walls with off-axis projection.

![Godot 4.x](https://img.shields.io/badge/Godot-4.x-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

![Editor View](screenshots/editor.jpeg)

## Features

- Off-axis (asymmetric) frustum projection for accurate perspective
- Side-by-side stereoscopic output for passive 3D displays
- Built-in FPS/fly camera controls with keyboard, mouse, and gamepad support
- Edit mode for development with standard resolution
- Production mode with automatic borderless fullscreen
- Configurable wall dimensions, eye separation, and resolution

## Installation

### From GitHub

1. Download or clone this repository
2. Copy `addons/stereo_wall_display/` into your project's `addons/` folder
3. Enable the plugin: Project > Project Settings > Plugins > Stereo Wall Display

### From Godot Asset Library

1. Open AssetLib in Godot
2. Search for "Stereo Wall Display"
3. Download and install
4. Enable the plugin in Project Settings

## Quick Start

1. Add a `StereoWallDisplay` node to your scene
2. Add your 3D content as children or siblings
3. Configure wall dimensions to match your physical display
4. Set `edit_mode = true` during development
5. Set `edit_mode = false` for deployment

## Controls

| Input | Action |
|-------|--------|
| WASD / Left Stick | Move |
| Mouse / Right Stick | Look |
| R | Reset position |
| ESC | Quit application |

## Configuration

### General Settings
- `edit_mode` - Toggle between development and stereo output
- `enable_gravity` - Enable for walking, disable for flying

### User Settings
- `start_position` - Initial spawn location
- `move_speed` - Movement speed in meters per second
- `look_sensitivity` - Mouse look sensitivity
- `controller_look_speed` - Gamepad right stick sensitivity

### Render Settings
- `resolution_width` / `resolution_height` - Resolution per eye (default: 4800x1620)
- `eye_separation` - Inter-ocular distance in meters (default: 0.063)
- `swap_eyes` - Swap left and right eye output

### Wall Physical Settings
Configure these to match your physical display wall:
- `wall_width` / `wall_height` - Physical dimensions in meters
- `wall_distance` - Distance from viewer to wall
- `wall_center_height` - Height of wall center from ground

## Production Deployment

When `edit_mode` is disabled:
- Window automatically sets to borderless mode
- Window positions at (0, 0)
- Resolution sets to full stereo output (resolution_width * 2 x resolution_height)

## Example

See `example_environment.tscn` for a demo scene.

## License

MIT License - see LICENSE file
