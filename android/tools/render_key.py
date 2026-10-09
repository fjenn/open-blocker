#!/usr/bin/env python3
"""
Headless Blender render of KeyModel.glb to match iOS KeyView3D stills.

Camera matches ios-source KeyView3D.frameCamera:
  FOV 26 (vertical), elevation 50 deg from the horizon,
  distance = radius / tan(fov/2 * 0.78), 300pt square frame.

Lights match KeyView3D: directional key euler (-0.95, -0.7),
fill euler (-0.4, 0.9), plus the studio environment (intensity 0.7).

Yaw 180 turns the engraved C-ring into the iPhone smile (opening toward
the camera, dimple at the bottom of the gap).

Usage (from repo root or this folder):
    blender --background --python android/tools/render_key.py -- /path/to/repo
"""

from __future__ import annotations

import math
import os
import sys
from pathlib import Path

import bpy
from mathutils import Vector

# Repo paths. When Blender runs this file, sys.argv is blender's, so locate
# the script via bpy.path / this file.
SCRIPT = Path(__file__).resolve() if "__file__" in dir() else None


def repo_root() -> Path:
    argv = sys.argv
    if "--" in argv:
        extra = argv[argv.index("--") + 1 :]
        if extra:
            return Path(extra[0]).resolve()
    here = Path(bpy.data.filepath).resolve() if bpy.data.filepath else Path.cwd()
    for candidate in (here, Path.cwd(), Path("/workspace")):
        if (candidate / "android" / "app" / "src" / "main").exists():
            return candidate
        if (candidate / "app" / "src" / "main").exists():
            return candidate.parent
    return Path("/workspace")


ROOT = repo_root()
_script_dir = SCRIPT.parent if SCRIPT else ROOT / "android" / "tools"
GLB = _script_dir / "KeyModel.glb"
if not GLB.exists():
    GLB = ROOT / "android" / "app" / "src" / "main" / "assets" / "models" / "KeyModel.glb"
USDZ = _script_dir / "KeyModel.usdz"
if not USDZ.exists():
    USDZ = ROOT / "ios-source" / "ios" / "OpenBlocker" / "Resources" / "KeyModel.usdz"
OUT_DIR = ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi"
WORK = ROOT / "android" / "tools" / "renders"
OUT_DIR.mkdir(parents=True, exist_ok=True)
WORK.mkdir(parents=True, exist_ok=True)

# iOS KeyView3D
FOV_DEG = 26.0
ELEVATION_DEG = 50.0
DISTANCE_FACTOR = 0.78
# 300pt @ 4x so xxxhdpi / emulator 420dpi stays sharp.
RES = 1200
# Keep the iOS camera padding. Do not zoom in — 300.dp on Android is 300pt on iOS.
SIZE_BOOST = 1.0
# Native pose plus a little yaw so the C-ring reads as the iPhone smile
# (opening up the face, dimple as the eyes). 0 is the imported rest pose.
MODEL_YAW_DEG = float(os.environ.get("OPENBLOCKER_KEY_YAW", "28"))

BODY = (0x9A / 255.0, 0x96 / 255.0, 0x90 / 255.0, 1.0)
FILL = (0x7A / 255.0, 0x76 / 255.0, 0x71 / 255.0, 1.0)
ROUGHNESS = 0.82
ENV_INTENSITY = 0.7


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_model() -> list[bpy.types.Object]:
    source = os.environ.get("OPENBLOCKER_KEY_SOURCE", "glb").lower()
    if source == "usdz" and USDZ.exists():
        bpy.ops.wm.usd_import(filepath=str(USDZ))
    else:
        if not GLB.exists():
            raise FileNotFoundError(GLB)
        bpy.ops.import_scene.gltf(filepath=str(GLB))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        raise RuntimeError("Key model had no mesh")
    yaw = math.radians(MODEL_YAW_DEG)
    for obj in meshes:
        obj.rotation_mode = "XYZ"
        obj.rotation_euler[2] += yaw
        # Same idea as iOS MDLMesh.addNormals(creaseThreshold: 0.85).
        if hasattr(obj.data, "use_auto_smooth"):
            obj.data.use_auto_smooth = True
            obj.data.auto_smooth_angle = math.radians(50)
        for poly in obj.data.polygons:
            poly.use_smooth = True
        bpy.context.view_layer.update()
    return meshes


def world_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    mins = Vector((math.inf, math.inf, math.inf))
    maxs = Vector((-math.inf, -math.inf, -math.inf))
    for obj in objects:
        for corner in obj.bound_box:
            w = obj.matrix_world @ Vector(corner)
            mins.x, mins.y, mins.z = min(mins.x, w.x), min(mins.y, w.y), min(mins.z, w.z)
            maxs.x, maxs.y, maxs.z = max(maxs.x, w.x), max(maxs.y, w.y), max(maxs.z, w.z)
    return mins, maxs


def apply_matte(objects: list[bpy.types.Object], color: tuple[float, float, float, float], name: str) -> None:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = ROUGHNESS
    bsdf.inputs["Metallic"].default_value = 0.0
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.22
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 0.0
    if "Sheen Weight" in bsdf.inputs:
        bsdf.inputs["Sheen Weight"].default_value = 0.06
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    for obj in objects:
        obj.data.materials.clear()
        obj.data.materials.append(mat)
        for slot in obj.material_slots:
            slot.material = mat


def ios_dir_from_euler(pitch: float, yaw: float) -> Vector:
    """SceneKit directional light shines along -Z after (pitch, yaw, 0)."""
    x, y, z = 0.0, 0.0, -1.0
    cp, sp = math.cos(pitch), math.sin(pitch)
    y, z = y * cp - z * sp, y * sp + z * cp
    cy, sy = math.cos(yaw), math.sin(yaw)
    x, z = x * cy + z * sy, -x * sy + z * cy
    return Vector((x, y, z))


def ios_to_blender(direction: Vector) -> Vector:
    # glTF import is Z-up: iOS (x, y, z) -> Blender (x, -z, y).
    return Vector((direction.x, -direction.z, direction.y)).normalized()


def write_studio_hdri(path: Path) -> Path:
    """Same stand-in as iOS KeyView3D.studioEnvironment() — lat-long 512x256."""
    w, h = 512, 256
    c0 = (0.98, 0.98, 0.98)
    c1 = (0.80, 0.80, 0.80)
    c2 = (0.52, 0.50, 0.47)
    c3 = (0.28, 0.27, 0.26)
    rows: list[tuple[float, float, float]] = []
    for y in range(h):
        t = y / (h - 1)
        if t < 0.38:
            u = t / 0.38
            col = tuple(c0[i] + (c1[i] - c0[i]) * u for i in range(3))
        elif t < 0.55:
            u = (t - 0.38) / 0.17
            col = tuple(c1[i] + (c2[i] - c1[i]) * u for i in range(3))
        else:
            u = (t - 0.55) / 0.45
            col = tuple(c2[i] + (c3[i] - c2[i]) * u for i in range(3))
        rows.append(col)  # type: ignore[arg-type]
    # Blender pixels are flattened RGBA, bottom-left origin.
    flat: list[float] = []
    for by in range(h):
        src_y = h - 1 - by
        col = rows[src_y]
        for x in range(w):
            r, g, b = col
            # Softboxes (iOS fills two white rects on the 512x256 image).
            if 20 <= src_y < 66 and 120 <= x < 260:
                r, g, b = 1.0, 1.0, 1.0
            elif 40 <= src_y < 70 and 360 <= x < 420:
                r, g, b = 1.0, 1.0, 1.0
            flat.extend((r, g, b, 1.0))
    img = bpy.data.images.new("studio_env", width=w, height=h, alpha=True, float_buffer=True)
    img.pixels = flat
    img.filepath_raw = str(path)
    img.file_format = "PNG"
    img.save()
    return path


def add_studio_lights(center: Vector) -> None:
    env_path = WORK / "studio_env.png"
    write_studio_hdri(env_path)

    world = bpy.data.worlds.new("Studio")
    world.use_nodes = True
    nodes = world.node_tree.nodes
    links = world.node_tree.links
    nodes.clear()
    tex = nodes.new("ShaderNodeTexEnvironment")
    tex.image = bpy.data.images.load(str(env_path))
    bg = nodes.new("ShaderNodeBackground")
    bg.inputs["Strength"].default_value = ENV_INTENSITY
    out = nodes.new("ShaderNodeOutputWorld")
    links.new(tex.outputs["Color"], bg.inputs["Color"])
    links.new(bg.outputs["Background"], out.inputs["Surface"])
    bpy.context.scene.world = world

    def add_sun(name: str, ios_euler: tuple[float, float], energy: float, color: tuple[float, float, float]) -> None:
        direction = ios_to_blender(ios_dir_from_euler(ios_euler[0], ios_euler[1]))
        bpy.ops.object.light_add(type="SUN", location=center - direction * 4)
        lamp = bpy.context.object
        lamp.name = name
        lamp.data.energy = energy
        lamp.data.angle = math.radians(12)
        lamp.data.color = color
        # Sun points along local -Z.
        lamp.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()

    # iOS intensities 700 / 160 around a 1000 default. Keep the key from
    # more above so the C sides wash out and the smile + eyes remain.
    add_sun("keyLight", (-1.15, -0.55), 2.6, (1.0, 0.99, 0.96))
    add_sun("fillLight", (-0.35, 0.9), 0.7, (1.0, 0.995, 0.98))

    # Large overhead softbox — pillowy dome, less raking on the ring.
    bpy.ops.object.light_add(type="AREA", location=center + Vector((-0.55, -0.45, 2.6)))
    soft = bpy.context.object
    soft.name = "softbox"
    soft.data.energy = 28
    soft.data.size = 4.2
    soft.data.color = (1.0, 0.99, 0.96)
    soft.rotation_euler = (math.radians(-18), math.radians(-10), 0)


def add_camera(center: Vector, radius: float) -> bpy.types.Object:
    fov = math.radians(FOV_DEG)
    elevation = math.radians(ELEVATION_DEG)
    distance = max(radius, 0.1) / math.tan(fov * 0.5 * DISTANCE_FACTOR) / SIZE_BOOST
    # Blender is Z-up. glTF import maps iOS/Y-up +Y -> +Z and +Z -> -Y,
    # so iOS (0, sin(e), cos(e)) becomes (0, -cos(e), sin(e)).
    direction = Vector((0.0, -math.cos(elevation), math.sin(elevation))).normalized()
    loc = center + direction * distance
    bpy.ops.object.camera_add(location=loc)
    cam = bpy.context.object
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = fov
    cam.data.clip_start = 0.01
    cam.data.clip_end = 50.0
    look = center - loc
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    print(
        f"bounds radius={radius:.4f} dist={distance:.4f} yaw={MODEL_YAW_DEG} "
        f"center={tuple(round(c, 4) for c in center)} cam={tuple(round(c, 4) for c in loc)}"
    )
    return cam


def configure_render(path: Path) -> None:
    scene = bpy.context.scene
    engine = os.environ.get("OPENBLOCKER_KEY_ENGINE", "CYCLES")
    scene.render.engine = engine
    if engine.startswith("CYCLES"):
        scene.cycles.device = "CPU"
        scene.cycles.samples = int(os.environ.get("OPENBLOCKER_KEY_SAMPLES", "96"))
        scene.cycles.use_denoising = True
    else:
        scene.eevee.taa_render_samples = int(os.environ.get("OPENBLOCKER_KEY_SAMPLES", "64"))
        scene.eevee.use_shadows = True
        if hasattr(scene.eevee, "use_raytracing"):
            scene.eevee.use_raytracing = True
    scene.render.resolution_x = int(os.environ.get("OPENBLOCKER_KEY_RES", str(RES)))
    scene.render.resolution_y = scene.render.resolution_x
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.compression = 15
    scene.render.filepath = str(path)
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = float(os.environ.get("OPENBLOCKER_KEY_EXPOSURE", "-0.30"))
    scene.view_settings.gamma = 1.0
    scene.display_settings.display_device = "sRGB"


def render_variant(color: tuple[float, float, float, float], dest: Path) -> None:
    reset_scene()
    meshes = import_model()
    mins, maxs = world_bounds(meshes)
    center = (mins + maxs) * 0.5
    # iOS frames the rest pose (radius 0.5). Yaw must not inflate the AABB.
    radius = 0.5
    print(f"imported {len(meshes)} mesh(es) min={mins} max={maxs} size={maxs - mins}")
    apply_matte(meshes, color, dest.stem)
    add_studio_lights(center)
    add_camera(center, radius)
    configure_render(dest)
    bpy.ops.render.render(write_still=True)
    print(f"wrote {dest} ({dest.stat().st_size} bytes)")


def main() -> None:
    idle = WORK / "key_idle.png"
    filled = WORK / "key_fill.png"
    render_variant(BODY, idle)
    render_variant(FILL, filled)
    for src, name in ((idle, "key_idle.png"), (filled, "key_fill.png")):
        dest = OUT_DIR / name
        dest.write_bytes(src.read_bytes())
        print(f"copied {dest}")


if __name__ == "__main__":
    main()
