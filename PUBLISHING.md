# Publishing to the Godot Asset Store

The new store is at [store.godotengine.org](https://store.godotengine.org). The official guide is [Submitting to the Asset Store](https://docs.godotengine.org/en/latest/community/asset_store/submitting_to_asset_store.html). Unlike the old Asset Library, you **upload a zip for each version** instead of pointing the store at a git commit.

## The repo is already set up for it

- Everything users need is in `addons/stereo_wall_display/`, including `README.md`, `LICENSE`, `plugin.cfg`, the icon, `examples/` and `wall_kit/` (display wall PC setup).
- `LICENSE` is at the repo root (required).
- `.gitignore` keeps `.godot/` and `*.import` out of the repo (required).
- `.gitattributes` uses `export-ignore`, so `git archive` only packs `addons/`.
- `screenshots/` has a `.gdignore`, so Godot doesn't import it.

## Releasing a version

1. Bump `version` in `addons/stereo_wall_display/plugin.cfg`.
2. Open the project in Godot and run `examples/example_scene.tscn` in Edit mode and Stereo mode (F2) to check it works (the store rejects assets that don't).
3. Commit, tag and build the zip:
   ```sh
   git tag v2.0.0
   git push origin main --tags
   git archive --format=zip --output stereo_wall_display-2.0.0.zip v2.0.0
   ```
   The zip contains only `addons/stereo_wall_display/…`.
4. On the store, open your asset → **Versions** → upload the zip, write a changelog, and set **minimum Godot version: 4.7**.

## First-time submission

1. Log in and click **Upload Asset**.
2. Fill in the publisher, asset name, URL slug, description and screenshots.
3. **Icon**: use a direct link, e.g.
   `https://raw.githubusercontent.com/uhmlavalab/stereo-wall-godot/main/addons/stereo_wall_display/icon.png`
   (it must be `raw.githubusercontent.com`, not `github.com`).
4. **AI usage disclosure**: this is mandatory if AI was used. Version 2.0 was written with help from Claude (an AI assistant), so disclose it.
5. Upload the first version as described above, then press **Submit** for review.
