class_name CameraRig
extends Node3D

enum CameraMode { ISOMETRIC, POV }

const HEAD_OFFSET := Vector3(0.0, 0.35, 0.0)

@export var target: Node3D
@export_range(0.0, 20.0, 0.1) var follow_speed := 5.0
@export_range(-89.0, 89.0, 1.0) var min_pitch_degrees := -10.0
@export_range(-89.0, 89.0, 1.0) var max_pitch_degrees := 60.0
@export_range(-89.0, 89.0, 1.0) var initial_pitch_degrees := 20.0
@export_range(0.1, 20.0, 0.1) var min_distance := 0.8
@export_range(0.1, 20.0, 0.1) var max_distance := 4.0
@export_range(0.1, 20.0, 0.1) var initial_distance := 2.0
@export_range(0.001, 0.1, 0.001) var orbit_sensitivity := 0.01
@export_range(0.01, 2.0, 0.01) var magnify_zoom_scale := 1.0
@export_range(0.01, 1.0, 0.01) var mouse_wheel_zoom_step := 0.25

var current_mode := CameraMode.ISOMETRIC
var _isometric_camera_transform := Transform3D.IDENTITY
var _isometric_camera_size := 6.5
var _orbit_yaw := 0.0
var _orbit_pitch := 0.0
var _pov_distance := 2.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	_isometric_camera_transform = camera.transform
	_isometric_camera_size = camera.size
	_orbit_pitch = clampf(
		deg_to_rad(initial_pitch_degrees),
		deg_to_rad(min_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)
	_pov_distance = clampf(initial_distance, min_distance, max_distance)
	set_mode(CameraMode.ISOMETRIC)


func _physics_process(delta: float) -> void:
	step(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_mode != CameraMode.POV:
		return

	if event is InputEventPanGesture:
		apply_orbit_delta(event.delta)
		get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		apply_zoom_delta((1.0 - event.factor) * magnify_zoom_scale)
		get_viewport().set_input_as_handled()


func step(delta: float) -> void:
	if Input.is_action_just_pressed("camera_toggle"):
		toggle_mode()
	if current_mode == CameraMode.POV:
		if Input.is_action_just_pressed("camera_zoom_in"):
			apply_zoom_delta(-mouse_wheel_zoom_step)
		elif Input.is_action_just_pressed("camera_zoom_out"):
			apply_zoom_delta(mouse_wheel_zoom_step)

	if target == null:
		return

	var goal := target.global_position
	global_position = global_position.lerp(goal, minf(maxf(follow_speed, 0.0) * delta, 1.0))


func toggle_mode() -> void:
	var next_mode := (
		CameraMode.POV if current_mode == CameraMode.ISOMETRIC else CameraMode.ISOMETRIC
	)
	set_mode(next_mode)


func set_mode(new_mode: CameraMode) -> void:
	current_mode = new_mode
	if current_mode == CameraMode.ISOMETRIC:
		spring_arm.process_mode = Node.PROCESS_MODE_DISABLED
		spring_arm.position = Vector3.ZERO
		spring_arm.rotation = Vector3.ZERO
		camera.transform = _isometric_camera_transform
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = _isometric_camera_size
	else:
		spring_arm.position = HEAD_OFFSET
		camera.transform = Transform3D.IDENTITY
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		_apply_pov_transform()
		spring_arm.process_mode = Node.PROCESS_MODE_INHERIT


func apply_orbit_delta(delta: Vector2) -> void:
	_orbit_yaw = wrapf(_orbit_yaw - delta.x * orbit_sensitivity, -PI, PI)
	_orbit_pitch = clampf(
		_orbit_pitch - delta.y * orbit_sensitivity,
		deg_to_rad(min_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)
	_apply_pov_transform()


func apply_zoom_delta(delta: float) -> void:
	_pov_distance = clampf(_pov_distance + delta, min_distance, max_distance)
	_apply_pov_transform()


func get_pitch_degrees() -> float:
	return rad_to_deg(_orbit_pitch)


func get_pov_distance() -> float:
	return _pov_distance


func _apply_pov_transform() -> void:
	if not is_node_ready() or current_mode != CameraMode.POV:
		return
	spring_arm.rotation = Vector3(-_orbit_pitch, _orbit_yaw, 0.0)
	spring_arm.spring_length = _pov_distance
	camera.position = Vector3(0.0, 0.0, _pov_distance)
