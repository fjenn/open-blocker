# Key sprites

`render_key.py` renders `KeyModel.glb` in headless Blender (Cycles) with the
iOS `KeyView3D` camera: FOV 26, elevation 50°, distance factor 0.78, 300pt
square frame, yaw 28° (C-ring reads as the iPhone smile: two eyes + mouth).
Lights copy the iOS directional key/fill plus the studio environment. Two
stills are written — idle `0x9A9690` and fill `0x7A7671` — then
`finalize_sprites.py` copies lossless WebP into `app/src/main/res/drawable-nodpi/`
without trimming, so the camera padding matches the 300pt KeyStage box.

```bash
blender --background --python android/tools/render_key.py -- /path/to/repo
python3 android/tools/finalize_sprites.py
```

`OPENBLOCKER_KEY_ENGINE` (default `CYCLES`) and `OPENBLOCKER_KEY_SAMPLES`
(default 64) override the renderer. `OPENBLOCKER_KEY_SPIN=12` writes a 30s
idle-spin sequence (`key_spin_XX` / `key_fill_spin_XX`). The running app and
Paparazzi both draw these sprites; Filament is not shipped.
