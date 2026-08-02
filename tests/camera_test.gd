extends GdUnitTestSuite


func after_test() -> void:
	Input.action_release("move_right")


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


func test_camera_follows_player() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(10)
	var scene: Node3D = runner.scene()
	var camera: Camera3D = scene.get_node("Camera3D")
	var player: Node3D = scene.get_node("Player")
	var offset: Vector3 = camera.global_position - player.global_position
	Input.action_press("move_right")
	await runner.simulate_frames(120)
	Input.action_release("move_right")
	await runner.simulate_frames(150)
	var goal := player.global_position + offset
	assert_float(camera.global_position.distance_to(goal)).is_less(1.0)
