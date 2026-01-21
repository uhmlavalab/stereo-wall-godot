# Stereo Wall Display

Godot 4.x addon for stereoscopic 3D rendering on large display walls with off-axis projection.

## Quick Start

1. Add `StereoWallDisplay` node to your scene
2. Configure wall dimensions to match your physical display
3. Use WASD/mouse to fly around in edit mode
4. Set `edit_mode = false` for production stereo output

## Head Tracking

Select tracking method from the inspector:

- **None** — Static head at configurable height
- **Vive Tracker** — SteamVR/OpenXR tracking (coming soon)
- **VRPN** — VRPN server tracking (coming soon)

## Tracking API

```gdscript
$StereoWallDisplay.set_head_position(Vector3(x, y, z))
```

## Documentation

See the main [README.md](../../README.md) for full documentation.

## License

MIT License — Copyright (c) 2026 Laboratory for Advanced Visualizations and Applications (LAVA), University of Hawaii.
