extends GdUnitTestSuite

const CAMERA_PATH := "CameraRig/SpringArm3D/Camera3D"


func after_test() -> void:
	Input.action_release("camera_toggle")
	Input.action_release("camera_zoom_in")
	Input.action_release("camera_zoom_out")


func test_camera_toggle_action_uses_physical_c() -> void:
	var has_physical_c := false
	for event in InputMap.action_get_events("camera_toggle"):
		var key_event := event as InputEventKey
		if key_event != null and key_event.physical_keycode == KEY_C:
			has_physical_c = true
			break
	assert_bool(has_physical_c).is_true()


func test_camera_zoom_actions_use_mouse_wheel() -> void:
	assert_bool(_action_uses_mouse_button("camera_zoom_in", MOUSE_BUTTON_WHEEL_UP)).is_true()
	assert_bool(_action_uses_mouse_button("camera_zoom_out", MOUSE_BUTTON_WHEEL_DOWN)).is_true()


func test_zoom_actions_adjust_pov_zoom_via_input_singleton() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var rig: CameraRig = runner.scene().get_node("CameraRig")
	rig.set_mode(CameraRig.CameraMode.POV)
	var initial_distance := rig.get_pov_distance()

	Input.action_press("camera_zoom_out")
	rig.step(0.0)
	Input.action_release("camera_zoom_out")

	assert_float(rig.get_pov_distance()).is_equal_approx(
		initial_distance + rig.mouse_wheel_zoom_step, 0.001
	)


func test_camera_is_orthographic() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var camera: Camera3D = runner.scene().get_node(CAMERA_PATH)
	assert_int(camera.projection).is_equal(Camera3D.PROJECTION_ORTHOGONAL)
	assert_float(camera.position.distance_to(Vector3(12.0, 10.0, 12.0))).is_less(0.001)
	assert_float(camera.basis.z.distance_to(Vector3(0.612372, 0.5, 0.612372))).is_less(0.001)


func test_camera_target_resolves() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var rig: CameraRig = runner.scene().get_node("CameraRig")
	assert_object(rig.target).is_not_null()


func test_camera_follow_converges_on_target() -> void:
	var camera_offset := Vector3(12.0, 10.0, 12.0)
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	var target := Node3D.new()
	world.add_child(target)
	var rig := Node3D.new()
	rig.set_script(load("res://scripts/camera_rig.gd"))
	var spring_arm := SpringArm3D.new()
	spring_arm.name = "SpringArm3D"
	rig.add_child(spring_arm)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = camera_offset
	spring_arm.add_child(camera)
	rig.set("target", target)
	world.add_child(rig)
	target.position = Vector3(5.0, 0.0, 0.0)
	for _i in 180:
		rig.step(1.0 / 60.0)
	var goal := target.global_position + camera_offset
	assert_float(camera.global_position.distance_to(goal)).is_less(0.5)


func test_camera_starts_isometric_and_toggles_to_pov_via_action() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var rig: CameraRig = runner.scene().get_node("CameraRig")
	var camera: Camera3D = runner.scene().get_node(CAMERA_PATH)

	assert_int(rig.current_mode).is_equal(CameraRig.CameraMode.ISOMETRIC)
	Input.action_press("camera_toggle")
	rig.step(0.0)
	Input.action_release("camera_toggle")

	assert_int(rig.current_mode).is_equal(CameraRig.CameraMode.POV)
	assert_int(camera.projection).is_equal(Camera3D.PROJECTION_PERSPECTIVE)

	rig.toggle_mode()
	assert_int(rig.current_mode).is_equal(CameraRig.CameraMode.ISOMETRIC)
	assert_int(camera.projection).is_equal(Camera3D.PROJECTION_ORTHOGONAL)
	assert_int(rig.spring_arm.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)
	assert_float(camera.position.distance_to(Vector3(12.0, 10.0, 12.0))).is_less(0.001)


func test_pov_orbit_pitch_clamps_at_exported_limits() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var rig: CameraRig = runner.scene().get_node("CameraRig")
	rig.set_mode(CameraRig.CameraMode.POV)

	rig.apply_orbit_delta(Vector2(0.0, 100000.0))
	assert_float(rig.get_pitch_degrees()).is_equal_approx(rig.min_pitch_degrees, 0.001)
	assert_float(rad_to_deg(rig.spring_arm.rotation.x)).is_equal_approx(
		-rig.min_pitch_degrees, 0.001
	)
	rig.apply_orbit_delta(Vector2(0.0, -100000.0))
	assert_float(rig.get_pitch_degrees()).is_equal_approx(rig.max_pitch_degrees, 0.001)
	assert_float(rad_to_deg(rig.spring_arm.rotation.x)).is_equal_approx(
		-rig.max_pitch_degrees, 0.001
	)


func test_default_pov_pitch_positions_camera_above_head_pivot() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var rig: CameraRig = runner.scene().get_node("CameraRig")
	var camera: Camera3D = runner.scene().get_node(CAMERA_PATH)

	rig.set_mode(CameraRig.CameraMode.POV)
	await runner.simulate_frames(1)

	assert_float(camera.global_position.y).is_greater(rig.spring_arm.global_position.y)


func test_pov_orbit_stays_world_relative_when_player_turns() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var player: Player = runner.scene().get_node("Player")
	var rig: CameraRig = runner.scene().get_node("CameraRig")
	rig.set_mode(CameraRig.CameraMode.POV)
	rig.apply_orbit_delta(Vector2(50.0, 0.0))
	var world_yaw := rig.spring_arm.global_rotation.y

	player.rotation.y = PI / 2.0
	rig.step(1.0 / 60.0)

	assert_float(absf(angle_difference(rig.spring_arm.global_rotation.y, world_yaw))).is_less(0.001)


func test_pov_zoom_clamps_at_exported_limits() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var rig: CameraRig = runner.scene().get_node("CameraRig")
	rig.set_mode(CameraRig.CameraMode.POV)

	rig.apply_zoom_delta(-1000.0)
	assert_float(rig.get_pov_distance()).is_equal_approx(rig.min_distance, 0.001)
	assert_float(rig.spring_arm.spring_length).is_equal_approx(rig.min_distance, 0.001)
	rig.apply_zoom_delta(1000.0)
	assert_float(rig.get_pov_distance()).is_equal_approx(rig.max_distance, 0.001)
	assert_float(rig.spring_arm.spring_length).is_equal_approx(rig.max_distance, 0.001)


func _action_uses_mouse_button(action: StringName, button_index: int) -> bool:
	for event in InputMap.action_get_events(action):
		var mouse_button := event as InputEventMouseButton
		if mouse_button != null and mouse_button.button_index == button_index:
			return true
	return false
