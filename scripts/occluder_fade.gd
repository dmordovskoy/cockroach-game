class_name OccluderFade
extends Node

const WORLD_COLLISION_MASK := 1
const MAX_RAY_HITS := 32
const TARGET_HEIGHT_OFFSET := Vector3(0.0, 0.3, 0.0)
const OCCLUDER_GROUP := &"camera_occluder"

@export_range(1.0, 20.0, 0.1) var camera_size := 6.5
@export_range(0.0, 1.0, 0.05) var target_transparency := 0.65
@export_range(0.0, 10.0, 0.1) var fade_speed := 3.0
@export var target: Node3D
@export var outline_mesh: GeometryInstance3D

var _camera: Camera3D
var _tracked_meshes: Array[GeometryInstance3D] = []


func _ready() -> void:
	_set_outline_enabled(false)
	_camera = get_parent() as Camera3D
	if _camera == null:
		push_error("OccluderFade must be a child of Camera3D")
		return
	_camera.size = camera_size


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if _camera == null or target == null:
		return

	_camera.size = camera_size
	var blocked_meshes := _collect_blocked_meshes()
	_set_outline_enabled(not blocked_meshes.is_empty())
	for mesh in blocked_meshes:
		if not _tracked_meshes.has(mesh):
			_tracked_meshes.append(mesh)

	for index in range(_tracked_meshes.size() - 1, -1, -1):
		var mesh := _tracked_meshes[index]
		if not is_instance_valid(mesh):
			_tracked_meshes.remove_at(index)
			continue
		var is_blocked := blocked_meshes.has(mesh)
		step_fade(mesh, is_blocked, delta)
		if not is_blocked and is_zero_approx(mesh.transparency):
			_tracked_meshes.remove_at(index)


func step_fade(mesh: GeometryInstance3D, blocked: bool, delta: float) -> void:
	var fade_target := clampf(target_transparency, 0.0, 1.0) if blocked else 0.0
	var fade_amount := maxf(fade_speed, 0.0) * maxf(delta, 0.0)
	mesh.transparency = move_toward(mesh.transparency, fade_target, fade_amount)


func _collect_blocked_meshes() -> Array[GeometryInstance3D]:
	var blocked_meshes: Array[GeometryInstance3D] = []
	var world := _camera.get_world_3d()
	if world == null:
		return blocked_meshes

	var ray_target := target.global_position + TARGET_HEIGHT_OFFSET
	var view_direction := -_camera.global_basis.z.normalized()
	var view_depth := maxf((ray_target - _camera.global_position).dot(view_direction), 0.0)
	var ray_origin := ray_target - view_direction * view_depth
	var exclusions: Array[RID] = []
	for _hit_index in MAX_RAY_HITS:
		var query := PhysicsRayQueryParameters3D.create(
			ray_origin, ray_target, WORLD_COLLISION_MASK, exclusions
		)
		query.collide_with_areas = false
		var hit := world.direct_space_state.intersect_ray(query)
		if hit.is_empty():
			break

		var collider := hit.get("collider") as CollisionObject3D
		if collider == null:
			break
		exclusions.append(collider.get_rid())
		if not collider.is_in_group(OCCLUDER_GROUP):
			continue

		var mesh := _find_occluder_mesh(collider)
		if mesh != null and not blocked_meshes.has(mesh):
			blocked_meshes.append(mesh)

	return blocked_meshes


func _find_occluder_mesh(body: Node) -> GeometryInstance3D:
	for child in body.get_children():
		var mesh := child as MeshInstance3D
		if mesh != null:
			return mesh
	return null


func _set_outline_enabled(enabled: bool) -> void:
	if outline_mesh == null:
		return
	var outline_material := outline_mesh.material_overlay as ShaderMaterial
	if outline_material != null:
		outline_material.set_shader_parameter("outline_enabled", enabled)
