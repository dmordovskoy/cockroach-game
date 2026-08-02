extends GdUnitTestSuite


func test_camera_is_orthographic() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var camera: Camera3D = runner.scene().get_node("Camera3D")
	assert_int(camera.projection).is_equal(Camera3D.PROJECTION_ORTHOGONAL)


func test_camera_target_resolves() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var camera: Camera3D = runner.scene().get_node("Camera3D")
	assert_object(camera.target).is_not_null()


func test_camera_follow_converges_on_target() -> void:
	var camera_offset := Vector3(12.0, 10.0, 12.0)
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	var target := Node3D.new()
	world.add_child(target)
	var camera := Camera3D.new()
	camera.set_script(load("res://scripts/camera_follow.gd"))
	camera.position = camera_offset
	camera.set("target", target)
	world.add_child(camera)
	target.position = Vector3(5.0, 0.0, 0.0)
	for _i in 180:
		camera.step(1.0 / 60.0)
	var goal := target.global_position + camera_offset
	assert_float(camera.global_position.distance_to(goal)).is_less(0.5)
