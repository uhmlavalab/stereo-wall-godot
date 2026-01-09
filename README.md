# Stereo Wall Display

A Godot 4.x addon for stereoscopic 3D rendering on large display walls with off-axis projection.

![Godot 4.x](https://img.shields.io/badge/Godot-4.x-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

![Editor View](screenshots/editor.jpeg)

## Features

- Off-axis (asymmetric) frustum projection for accurate perspective
- Side-by-side stereoscopic output for passive 3D displays
- Works as a camera rig - parent to any Node3D (player head, vehicle, etc.)
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

1. Add a `StereoWallDisplay` node as a child of your player's head/camera position
2. Configure wall dimensions to match your physical display
3. Set `edit_mode = true` during development
4. Set `edit_mode = false` for deployment

### Scene Structure

```
Player (CharacterBody3D)
├── CollisionShape3D
└── Head (Node3D)
	└── StereoWallDisplay  ← Add here!
```

The `StereoWallDisplay` follows its parent's transform, so as your player moves and looks around, the stereo cameras track accordingly.

## Configuration

### General Settings
- `edit_mode` - Toggle between development (single camera) and stereo output

### Render Settings
- `eye_separation` - Inter-ocular distance in meters (default: 0.063m / 63mm)
- `swap_eyes` - Swap left and right eye output
- `resolution_width` / `resolution_height` - Resolution per eye (default: 4800x1620)
- `near_clip` / `far_clip` - Camera clipping planes

### Wall Physical Settings
Configure these to match your physical display wall:
- `wall_width` / `wall_height` - Physical dimensions in meters
- `wall_distance` - Distance from viewer to wall

## Production Deployment

When `edit_mode` is disabled:
- Window automatically sets to borderless mode
- Window positions at (0, 0)
- Resolution sets to full stereo output (resolution_width × 2 × resolution_height)

## Example

See `addons/stereo_wall_display/example_scene/` for a complete demo with a simple FPS player controller showing how to integrate the stereo display with your own player.

### Example Controls

| Input | Action |
|-------|--------|
| WASD / Left Stick | Move |
| Mouse / Right Stick | Look |
| R | Reset position |
| ESC | Quit application |

## License

MIT License - see LICENSE file
