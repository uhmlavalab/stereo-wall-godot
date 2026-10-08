# Releasing a New Version

Releases are published on GitHub as a zip that contains only `addons/stereo_wall_display/` (`.gitattributes` leaves everything else out).

1. Set `version` in `addons/stereo_wall_display/plugin.cfg` (for example `0.8.1`).
2. Open the project in Godot, run `examples/example_scene.tscn`, and press F2 to check both Edit and Stereo mode.
3. Commit and merge into `main`.
4. In Terminal, run these one at a time (replace `0.8.1` with the new version):
   ```sh
   cd ~/Code/Godot/stereo-wall-godot && git checkout main && git pull
   git tag v0.8.1 && git push origin v0.8.1
   git archive --format=zip --output stereo_wall_display-0.8.1.zip v0.8.1
   gh release create v0.8.1 stereo_wall_display-0.8.1.zip --title "Stereo Wall Display 0.8.1" --generate-notes
   rm stereo_wall_display-0.8.1.zip
   ```
5. Open the release on GitHub and edit the notes to say what changed, in plain words.

Version numbers: bump the last number for fixes (0.8.1), the middle one for new features (0.9.0). 1.0.0 is for when the addon is considered stable.
