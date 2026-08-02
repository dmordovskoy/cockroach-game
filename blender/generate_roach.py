#!/usr/bin/env python3
"""Build, validate, export, and render the static cockroach model."""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


REPO_ROOT = Path(__file__).resolve().parents[1]
BLEND_PATH = REPO_ROOT / "blender" / "cockroach.blend"
GLB_PATH = REPO_ROOT / "assets" / "models" / "cockroach.glb"
RENDER_DIR = REPO_ROOT / "blender" / "renders"
TRIANGLE_LIMIT = 2_000

MODEL_OBJECTS: list[bpy.types.Object] = []
BODY_OBJECTS: list[bpy.types.Object] = []


def clear_scene() -> None:
	"""Start from an empty file so repeated runs produce the same scene."""
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete(use_global=False)

	for collection in list(bpy.data.collections):
		bpy.data.collections.remove(collection)
	for mesh in list(bpy.data.meshes):
		bpy.data.meshes.remove(mesh)
	for material in list(bpy.data.materials):
		bpy.data.materials.remove(material)
	for camera in list(bpy.data.cameras):
		bpy.data.cameras.remove(camera)
	for light in list(bpy.data.lights):
		bpy.data.lights.remove(light)


def make_material(name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
	material = bpy.data.materials.new(name=name)
	material.diffuse_color = color
	material.use_nodes = True
	principled = material.node_tree.nodes.get("Principled BSDF")
	principled.inputs["Base Color"].default_value = color
	principled.inputs["Roughness"].default_value = 0.72
	return material


def move_to_collection(obj: bpy.types.Object, collection: bpy.types.Collection) -> None:
	for source_collection in list(obj.users_collection):
		source_collection.objects.unlink(obj)
	collection.objects.link(obj)


def register_mesh(
	obj: bpy.types.Object,
	material: bpy.types.Material,
	collection: bpy.types.Collection,
	*,
	body_part: bool = False,
	smooth: bool = True,
) -> bpy.types.Object:
	obj.data.materials.append(material)
	for polygon in obj.data.polygons:
		polygon.use_smooth = smooth
	move_to_collection(obj, collection)
	MODEL_OBJECTS.append(obj)
	if body_part:
		BODY_OBJECTS.append(obj)
	return obj


def add_ellipsoid(
	name: str,
	location: tuple[float, float, float],
	scale: tuple[float, float, float],
	material: bpy.types.Material,
	collection: bpy.types.Collection,
	*,
	body_part: bool = False,
	segments: int = 8,
	ring_count: int = 6,
) -> bpy.types.Object:
	bpy.ops.mesh.primitive_uv_sphere_add(
		segments=segments,
		ring_count=ring_count,
		calc_uvs=False,
		location=location,
	)
	obj = bpy.context.object
	obj.name = name
	obj.scale = scale
	return register_mesh(obj, material, collection, body_part=body_part)


def add_ico_sphere(
	name: str,
	location: tuple[float, float, float],
	radius: float,
	material: bpy.types.Material,
	collection: bpy.types.Collection,
	*,
	scale: tuple[float, float, float] = (1.0, 1.0, 1.0),
) -> bpy.types.Object:
	bpy.ops.mesh.primitive_ico_sphere_add(
		subdivisions=1,
		radius=radius,
		calc_uvs=False,
		location=location,
	)
	obj = bpy.context.object
	obj.name = name
	obj.scale = scale
	return register_mesh(obj, material, collection)


def add_tapered_segment(
	name: str,
	start: tuple[float, float, float] | Vector,
	end: tuple[float, float, float] | Vector,
	start_radius: float,
	end_radius: float,
	material: bpy.types.Material,
	collection: bpy.types.Collection,
) -> bpy.types.Object:
	start_vector = Vector(start)
	end_vector = Vector(end)
	direction = end_vector - start_vector
	bpy.ops.mesh.primitive_cone_add(
		vertices=6,
		radius1=start_radius,
		radius2=end_radius,
		depth=direction.length,
		end_fill_type="NGON",
		calc_uvs=False,
		location=(start_vector + end_vector) * 0.5,
	)
	obj = bpy.context.object
	obj.name = name
	obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
	return register_mesh(obj, material, collection)


def add_chain(
	name: str,
	points: list[tuple[float, float, float]],
	radii: list[float],
	materials: tuple[bpy.types.Material, ...],
	collection: bpy.types.Collection,
) -> None:
	for index, (start, end) in enumerate(zip(points, points[1:])):
		add_tapered_segment(
			f"{name}_{index + 1:02d}",
			start,
			end,
			radii[index],
			radii[index + 1],
			materials[index % len(materials)],
			collection,
		)


def create_model(collection: bpy.types.Collection) -> None:
	# Blender +Y exports as Godot -Z, so the face and antennae extend toward +Y here.
	shell = make_material("Shell", (0.095, 0.012, 0.004, 1.0))
	shell_light = make_material("ShellLight", (0.16, 0.025, 0.009, 1.0))
	belly = make_material("Belly", (0.40, 0.12, 0.025, 1.0))
	belly_light = make_material("BellyLight", (0.55, 0.20, 0.055, 1.0))
	dark = make_material("DarkBrown", (0.035, 0.008, 0.004, 1.0))
	eye = make_material("EyeCream", (0.97, 0.88, 0.68, 1.0))
	pupil = make_material("Pupil", (0.018, 0.010, 0.007, 1.0))
	highlight = make_material("EyeHighlight", (1.0, 0.97, 0.88, 1.0))

	# A warm, segmented underside remains visible below the split wing cases.
	add_ellipsoid(
		"AbdomenCore",
		(0.0, -0.10, 0.145),
		(0.265, 0.405, 0.125),
		shell_light,
		collection,
		body_part=True,
	)
	for index, y_position in enumerate((-0.34, -0.17, 0.0, 0.16)):
		add_ellipsoid(
			f"BellyBand_{index + 1:02d}",
			(0.0, y_position, 0.095 + index * 0.006),
			(0.290 - index * 0.006, 0.086, 0.062),
			belly if index % 2 == 0 else belly_light,
			collection,
			body_part=True,
		)

	# Two overlapping low-poly ellipsoids create the broad shell and central seam.
	add_ellipsoid(
		"WingCaseLeft",
		(-0.115, -0.105, 0.225),
		(0.185, 0.385, 0.13),
		shell,
		collection,
		body_part=True,
	)
	add_ellipsoid(
		"WingCaseRight",
		(0.115, -0.105, 0.225),
		(0.185, 0.385, 0.13),
		shell,
		collection,
		body_part=True,
	)
	add_chain(
		"WingSeam",
		[(0.0, -0.455, 0.264), (0.0, -0.29, 0.332), (0.0, -0.04, 0.359), (0.0, 0.205, 0.305)],
		[0.009, 0.009, 0.008, 0.006],
		(dark,),
		collection,
	)

	add_ellipsoid(
		"Thorax",
		(0.0, 0.235, 0.215),
		(0.27, 0.155, 0.13),
		shell_light,
		collection,
		body_part=True,
	)
	add_ellipsoid(
		"Head",
		(0.0, 0.405, 0.205),
		(0.225, 0.18, 0.14),
		shell_light,
		collection,
		body_part=True,
	)

	for side, label in ((-1.0, "Left"), (1.0, "Right")):
		add_ellipsoid(
			f"Eye{label}",
			(side * 0.092, 0.548, 0.253),
			(0.083, 0.027, 0.082),
			eye,
			collection,
			body_part=True,
		)
		pupil_x = side * 0.068
		add_ellipsoid(
			f"Pupil{label}",
			(pupil_x, 0.574, 0.252),
			(0.033, 0.014, 0.046),
			pupil,
			collection,
			body_part=True,
		)
		add_ico_sphere(
			f"EyeHighlight{label}",
			(pupil_x - side * 0.008, 0.588, 0.273),
			0.012,
			highlight,
			collection,
			scale=(0.8, 0.45, 1.0),
		)

	# A shallow U-shaped smirk keeps the face readable from the gameplay camera.
	add_chain(
		"Smirk",
		[
			(-0.13, 0.563, 0.167),
			(-0.07, 0.577, 0.145),
			(0.0, 0.582, 0.139),
			(0.07, 0.577, 0.145),
			(0.13, 0.563, 0.172),
		],
		[0.007, 0.007, 0.007, 0.007, 0.006],
		(dark,),
		collection,
	)

	leg_materials = (shell_light, shell)
	leg_sets = (
		((0.225, 0.22, 0.19), (0.335, 0.30, 0.13), (0.415, 0.37, 0.052), (0.485, 0.43, 0.018)),
		((0.255, -0.03, 0.17), (0.38, 0.0, 0.115), (0.455, 0.06, 0.045), (0.525, 0.11, 0.018)),
		((0.235, -0.29, 0.17), (0.35, -0.36, 0.115), (0.425, -0.44, 0.043), (0.49, -0.515, 0.018)),
	)
	leg_radii = [0.031, 0.025, 0.018, 0.007]
	for side, side_name in ((-1.0, "Left"), (1.0, "Right")):
		for leg_index, right_side_points in enumerate(leg_sets):
			points = [(side * x, y, z) for x, y, z in right_side_points]
			add_ico_sphere(
				f"LegJoint{side_name}_{leg_index + 1:02d}",
				points[0],
				0.038,
				shell,
				collection,
				scale=(1.0, 0.82, 0.82),
			)
			add_chain(
				f"Leg{side_name}_{leg_index + 1:02d}",
				points,
				leg_radii,
				leg_materials,
				collection,
			)

	antenna_radii = [0.018, 0.017, 0.015, 0.013, 0.011, 0.009, 0.005]
	for side, side_name in ((-1.0, "Left"), (1.0, "Right")):
		antenna_points = [
			(side * 0.075, 0.49, 0.315),
			(side * 0.09, 0.61, 0.405),
			(side * 0.12, 0.75, 0.475),
			(side * 0.17, 0.89, 0.515),
			(side * 0.23, 1.02, 0.505),
			(side * 0.30, 1.13, 0.455),
			(side * 0.39, 1.22, 0.375),
		]
		add_chain(
			f"Antenna{side_name}",
			antenna_points,
			antenna_radii,
			(shell, shell_light),
			collection,
		)


def object_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
	bpy.context.view_layer.update()
	minimum = Vector((math.inf, math.inf, math.inf))
	maximum = Vector((-math.inf, -math.inf, -math.inf))
	for obj in objects:
		for vertex in obj.data.vertices:
			point = obj.matrix_world @ vertex.co
			minimum.x = min(minimum.x, point.x)
			minimum.y = min(minimum.y, point.y)
			minimum.z = min(minimum.z, point.z)
			maximum.x = max(maximum.x, point.x)
			maximum.y = max(maximum.y, point.y)
			maximum.z = max(maximum.z, point.z)
	return minimum, maximum


def center_and_ground_model() -> None:
	body_minimum, body_maximum = object_bounds(BODY_OBJECTS)
	body_center = (body_minimum + body_maximum) * 0.5
	for obj in MODEL_OBJECTS:
		obj.location.x -= body_center.x
		obj.location.y -= body_center.y

	model_minimum, _ = object_bounds(MODEL_OBJECTS)
	for obj in MODEL_OBJECTS:
		obj.location.z -= model_minimum.z

	bpy.context.view_layer.update()
	for obj in MODEL_OBJECTS:
		bpy.ops.object.select_all(action="DESELECT")
		obj.select_set(True)
		bpy.context.view_layer.objects.active = obj
		bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def triangle_count() -> int:
	total = 0
	depsgraph = bpy.context.evaluated_depsgraph_get()
	for obj in MODEL_OBJECTS:
		evaluated_object = obj.evaluated_get(depsgraph)
		evaluated_mesh = evaluated_object.to_mesh()
		evaluated_mesh.calc_loop_triangles()
		total += len(evaluated_mesh.loop_triangles)
		evaluated_object.to_mesh_clear()
	return total


def validate_model() -> None:
	model_minimum, model_maximum = object_bounds(MODEL_OBJECTS)
	body_minimum, body_maximum = object_bounds(BODY_OBJECTS)
	body_size = body_maximum - body_minimum
	body_center = (body_minimum + body_maximum) * 0.5
	triangles = triangle_count()

	assert abs(model_minimum.z) < 0.0001, f"Feet must rest at z=0 in Blender, got {model_minimum.z:.5f}"
	assert abs(body_center.x) < 0.0001 and abs(body_center.y) < 0.0001, (
		f"Body origin must be centered in X/Y, got ({body_center.x:.5f}, {body_center.y:.5f})"
	)
	assert 0.50 <= body_size.x <= 0.70, f"Body width out of contract: {body_size.x:.3f}"
	assert 0.90 <= body_size.y <= 1.15, f"Body length out of contract: {body_size.y:.3f}"
	assert 0.28 <= body_size.z <= 0.40, f"Body height out of contract: {body_size.z:.3f}"
	assert triangles <= TRIANGLE_LIMIT, f"Triangle budget exceeded: {triangles} > {TRIANGLE_LIMIT}"

	for obj in MODEL_OBJECTS:
		assert obj.location.length < 0.0001, f"Unapplied location on {obj.name}"
		assert obj.rotation_euler.to_matrix().is_identity, f"Unapplied rotation on {obj.name}"
		assert all(abs(component - 1.0) < 0.0001 for component in obj.scale), f"Unapplied scale on {obj.name}"

	print(
		"Model contract: "
		f"body={body_size.x:.3f}w x {body_size.y:.3f}l x {body_size.z:.3f}h, "
		f"total_height={model_maximum.z - model_minimum.z:.3f}, triangles={triangles}"
	)


def export_glb() -> None:
	GLB_PATH.parent.mkdir(parents=True, exist_ok=True)
	bpy.ops.object.select_all(action="DESELECT")
	for obj in MODEL_OBJECTS:
		obj.select_set(True)
	bpy.context.view_layer.objects.active = MODEL_OBJECTS[0]
	bpy.ops.export_scene.gltf(
		filepath=str(GLB_PATH),
		export_format="GLB",
		use_selection=True,
		export_yup=True,
		export_materials="EXPORT",
		export_texcoords=False,
		export_normals=True,
		export_cameras=False,
		export_lights=False,
		export_animations=False,
	)


def add_render_object(obj: bpy.types.Object, collection: bpy.types.Collection) -> bpy.types.Object:
	move_to_collection(obj, collection)
	return obj


def aim_camera(camera: bpy.types.Object, target: tuple[float, float, float]) -> None:
	direction = Vector(target) - camera.location
	camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def create_render_setup(collection: bpy.types.Collection) -> bpy.types.Object:
	scene = bpy.context.scene
	scene.render.engine = "BLENDER_EEVEE"
	scene.render.resolution_x = 640
	scene.render.resolution_y = 640
	scene.render.resolution_percentage = 100
	scene.render.image_settings.file_format = "PNG"
	scene.render.image_settings.color_mode = "RGB"
	scene.render.dither_intensity = 0.0
	scene.render.film_transparent = False
	scene.render.use_file_extension = True

	world = bpy.data.worlds.new("RenderWorld") if scene.world is None else scene.world
	scene.world = world
	world.use_nodes = True
	world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.055, 0.043, 0.038, 1.0)
	world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.22

	ground_material = make_material("Ground", (0.12, 0.085, 0.065, 1.0))
	bpy.ops.mesh.primitive_plane_add(size=200.0, location=(0.0, 0.0, -0.006))
	ground = add_render_object(bpy.context.object, collection)
	ground.name = "Ground"
	ground.data.materials.append(ground_material)

	light_specs = (
		("KeyLight", (2.6, 3.4, 4.2), 430.0, 4.0, (1.0, 0.88, 0.76)),
		("FillLight", (-3.2, 1.4, 2.1), 250.0, 3.0, (0.52, 0.67, 1.0)),
		("RimLight", (0.2, -3.2, 3.3), 360.0, 3.0, (1.0, 0.48, 0.28)),
	)
	for name, location, energy, size, color in light_specs:
		light_data = bpy.data.lights.new(name=name, type="AREA")
		light_data.energy = energy
		light_data.shape = "DISK"
		light_data.size = size
		light_data.color = color
		light = bpy.data.objects.new(name, light_data)
		collection.objects.link(light)
		light.location = location
		aim_camera(light, (0.0, 0.05, 0.16))

	camera_data = bpy.data.cameras.new("ReviewCamera")
	camera_data.type = "ORTHO"
	camera_data.lens = 50.0
	camera = bpy.data.objects.new("ReviewCamera", camera_data)
	collection.objects.link(camera)
	scene.camera = camera
	return camera


def render_views(camera: bpy.types.Object) -> None:
	RENDER_DIR.mkdir(parents=True, exist_ok=True)
	views = (
		("front", (0.0, 2.8, 0.25), (0.0, 0.05, 0.24), 1.10),
		("side", (2.8, 0.32, 0.32), (0.0, 0.32, 0.25), 1.90),
		("top", (0.0, 0.32, 3.2), (0.0, 0.32, 0.0), 1.90),
		("three_quarter", (2.3, 2.65, 1.75), (0.0, 0.26, 0.22), 1.58),
	)
	for name, location, target, ortho_scale in views:
		camera.location = location
		camera.data.ortho_scale = ortho_scale
		aim_camera(camera, target)
		bpy.context.scene.render.filepath = str(RENDER_DIR / f"{name}.png")
		bpy.ops.render.render(write_still=True)


def main() -> None:
	BLEND_PATH.parent.mkdir(parents=True, exist_ok=True)
	clear_scene()

	scene = bpy.context.scene
	scene.name = "CockroachReview"
	scene.unit_settings.system = "METRIC"
	scene.unit_settings.scale_length = 1.0

	model_collection = bpy.data.collections.new("CockroachModel")
	render_collection = bpy.data.collections.new("RenderSetup")
	scene.collection.children.link(model_collection)
	scene.collection.children.link(render_collection)

	create_model(model_collection)
	center_and_ground_model()
	validate_model()
	export_glb()
	camera = create_render_setup(render_collection)
	render_views(camera)
	scene.render.filepath = "//renders/"
	bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH), compress=True, relative_remap=True)
	print(f"Saved {BLEND_PATH.relative_to(REPO_ROOT)}")
	print(f"Exported {GLB_PATH.relative_to(REPO_ROOT)}")
	print(f"Rendered four review views to {RENDER_DIR.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
	main()
