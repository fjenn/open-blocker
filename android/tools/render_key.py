#!/usr/bin/env python3
"""
Headless Blender render of KeyModel.glb to match iOS KeyView3D stills.

Camera matches ios KeyView3D.frameCamera:
  FOV 26 (vertical), elevation 50 deg from the horizon,
  distance = radius / tan(fov/2 * 0.78), 300pt square frame.

Usage (from repo root or this folder):
  blender --background --python android/tools/render_key.py
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
# Exact iOS framing. Compose scales the sprite ~15% so it matches the stills.
SIZE_BOOST = 1.0
# Small yaw so the engraved ring sits like the iPhone idle pose.
MODEL_YAW_DEG = 90.0

BODY = (0x9A / 255.0, 0x96 / 255.0, 0x90 / 255.0, 1.0)
FILL = (0x7A / 255.0, 0x76 / 255.0, 0x71 / 255.0, 1.0)
ROUGHNESS = 0.82


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_model() -> list[bpy.types.Object]:
    if not GLB.exists():
        raise FileNotFoundError(GLB)
    bpy.ops.import_scene.gltf(filepath=str(GLB))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        raise RuntimeError("KeyModel.glb had no mesh")
    yaw = math.radians(MODEL_YAW_DEG)
    for obj in meshes:
        obj.rotation_mode = "XYZ"
        obj.rotation_euler[2] += yaw
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
        bsdf.inputs["Specular IOR Level"].default_value = 0.18
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 0.0
    if "Sheen Weight" in bsdf.inputs:
        bsdf.inputs["Sheen Weight"].default_value = 0.04
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    for obj in objects:
        obj.data.materials.clear()
        obj.data.materials.append(mat)
        for slot in obj.material_slots:
            slot.material = mat


def add_studio_lights(center: Vector) -> None:
    # Soft key from the top-left (iOS keyLight euler -0.95, -0.7).
    bpy.ops.object.light_add(type="AREA", location=center + Vector((-1.2, -0.8, 2.4)))
    key = bpy.context.object
    key.data.energy = 55
    key.data.size = 3.4
    key.data.color = (1.0, 0.99, 0.97)
    key.rotation_euler = (math.radians(-55), math.radians(-22), 0)

    bpy.ops.object.light_add(type="AREA", location=center + Vector((1.6, -0.3, 1.0)))
    fill = bpy.context.object
    fill.data.energy = 22
    fill.data.size = 3.8
    fill.data.color = (1.0, 1.0, 1.0)
    fill.rotation_euler = (math.radians(-22), math.radians(40), 0)

    bpy.ops.object.light_add(type="AREA", location=center + Vector((0.15, 1.8, 0.35)))
    rim = bpy.context.object
    rim.data.energy = 6
    rim.data.size = 2.2
    rim.data.color = (0.92, 0.90, 0.87)
    rim.rotation_euler = (math.radians(12), 0, 0)

    world = bpy.data.worlds.new("Studio")
    world.use_nodes = True
    wnodes = world.node_tree.nodes
    wlinks = world.node_tree.links
    wnodes.clear()
    bg = wnodes.new("ShaderNodeBackground")
    bg.inputs["Color"].default_value = (0.72, 0.70, 0.67, 1.0)
    bg.inputs["Strength"].default_value = 0.38
    wout = wnodes.new("ShaderNodeOutputWorld")
    wlinks.new(bg.outputs["Background"], wout.inputs["Surface"])
    bpy.context.scene.world = world


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
        f"bounds radius={radius:.4f} dist={distance:.4f} "
        f"center={tuple(round(c, 4) for c in center)} cam={tuple(round(c, 4) for c in loc)}"
    )
    return cam


def configure_render(path: Path) -> None:
    scene = bpy.context.scene
    # Eevee is enough for a matte soft-touch puck and iterates in seconds.
    # Cycles stays available via OPENBLOCKER_KEY_ENGINE=CYCLES.
    engine = os.environ.get("OPENBLOCKER_KEY_ENGINE", "CYCLES")
    scene.render.engine = engine
    if engine.startswith("CYCLES"):
        scene.cycles.device = "CPU"
        scene.cycles.samples = int(os.environ.get("OPENBLOCKER_KEY_SAMPLES", "48"))
        scene.cycles.use_denoising = True
    else:
        scene.eevee.taa_render_samples = int(os.environ.get("OPENBLOCKER_KEY_SAMPLES", "64"))
        scene.eevee.use_shadows = True
        scene.eevee.use_raytracing = True
    scene.render.resolution_x = RES
    scene.render.resolution_y = RES
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.compression = 15
    scene.render.filepath = str(path)
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = -0.08
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
    # Copy into drawable-nodpi as the committed sprites (PNG; packed later as webp if smaller).
    for src, name in ((idle, "key_idle.png"), (filled, "key_fill.png")):
        dest = OUT_DIR / name
        dest.write_bytes(src.read_bytes())
        print(f"copied {dest}")


if __name__ == "__main__":
    main()
