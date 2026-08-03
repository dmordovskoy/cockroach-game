extends GdUnitTestSuite


func test_fade_step_rises_falls_and_clamps() -> void:
	var fade: OccluderFade = auto_free(OccluderFade.new())
	var mesh: MeshInstance3D = auto_free(MeshInstance3D.new())
	fade.fade_speed = 1.0
	fade.target_transparency = 0.65

	fade.step_fade(mesh, true, 0.25)
	assert_float(mesh.transparency).is_equal_approx(0.25, 0.001)
	fade.step_fade(mesh, true, 1.0)
	assert_float(mesh.transparency).is_equal_approx(0.65, 0.001)

	fade.step_fade(mesh, false, 0.25)
	assert_float(mesh.transparency).is_equal_approx(0.4, 0.001)
	fade.step_fade(mesh, false, 1.0)
	assert_float(mesh.transparency).is_equal_approx(0.0, 0.001)


func test_main_scene_uses_close_tunable_camera() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var camera: Camera3D = runner.scene().get_node("Camera3D")
	var fade: OccluderFade = camera.get_node("OccluderFade")

	assert_int(camera.projection).is_equal(Camera3D.PROJECTION_ORTHOGONAL)
	assert_float(camera.size).is_equal_approx(6.5, 0.001)
	assert_float(fade.camera_size).is_equal_approx(6.5, 0.001)


func test_scene_fades_counter_and_restores_in_open_floor() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var main := runner.scene()
	var player: Player = main.get_node("Player")
	var camera: Camera3D = main.get_node("Camera3D")
	var fade: OccluderFade = camera.get_node("OccluderFade")
	var counter_mesh: MeshInstance3D = main.get_node("Kitchen/SideCounter/MeshInstance3D")
	var camera_offset := Vector3(12.0, 10.0, 12.0)
	var floor_height := player.position.y
	fade.fade_speed = 100.0

	player.position = Vector3(5.0, floor_height, -5.0)
	camera.position = player.position + camera_offset + Vector3(-6.0, 0.0, 0.0)
	fade.step(1.0 / 60.0)
	assert_float(counter_mesh.transparency).is_greater(0.0)

	player.position = Vector3(0.0, floor_height, 0.0)
	camera.position = player.position + camera_offset + Vector3(-6.0, 0.0, 0.0)
	fade.step(1.0 / 60.0)
	assert_float(counter_mesh.transparency).is_equal_approx(0.0, 0.001)
