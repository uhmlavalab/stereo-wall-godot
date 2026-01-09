# Stereo Wall Display

Godot 4.x addon for stereoscopic 3D rendering on large display walls.

See the main README.md for full documentation.

## Quick Start

1. Add `StereoWallDisplay` as a child of your player's head/camera node
2. Configure wall dimensions to match your display
3. Set `edit_mode = false` for production

## Scene Structure

```
Player (CharacterBody3D)
└── Head (Node3D)
    └── StereoWallDisplay
```

## License

MIT
