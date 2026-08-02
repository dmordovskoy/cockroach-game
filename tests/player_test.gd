extends GdUnitTestSuite


func after_test() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")


func test_idle_without_input() -> void:
	var runner := scene_runner("res://scenes/player/player.tscn")
	await runner.simulate_frames(30)
	var player: Player = runner.scene()
	assert_float(player.velocity.x).is_equal_approx(0.0, 0.001)
	assert_float(player.velocity.z).is_equal_approx(0.0, 0.001)


func test_uses_grounded_forward_facing_cockroach_model() -> void:
	var runner := scene_runner("res://scenes/player/player.tscn")
	await runner.simulate_frames(1)
	var player: Player = runner.scene()
	var model := player.get_node("Cockroach") as Node3D
	var collision := player.get_node("CollisionShape3D") as CollisionShape3D
	var collision_shape := collision.shape as BoxShape3D
	var head := model.find_child("Head", true, false) as MeshInstance3D
	var left_eye := model.find_child("EyeLeft", true, false) as MeshInstance3D

	assert_object(model).is_not_null()
	assert_vector(model.position).is_equal(Vector3(0.0, 0.175, 0.0))
	assert_vector(collision.position).is_equal(Vector3(0.0, 0.3, 0.0))
	assert_vector(collision_shape.size).is_equal(Vector3(0.6, 0.25, 1.0))
	assert_object(head).is_not_null()
	assert_object(left_eye).is_not_null()
	assert_float(left_eye.get_aabb().get_center().z).is_less(head.get_aabb().get_center().z)


func test_moves_left_on_input() -> void:
	var runner := scene_runner("res://scenes/player/player.tscn")
	Input.action_press("move_left")
	await runner.simulate_frames(30)
	var player: Player = runner.scene()
	assert_float(player.velocity.x).is_less(0.0)


func test_turns_toward_movement_direction() -> void:
	var runner := scene_runner("res://scenes/player/player.tscn")
	Input.action_press("move_left")
	await runner.simulate_frames(90)
	var player: Player = runner.scene()
	assert_float(absf(angle_difference(player.rotation.y, PI / 2))).is_less(0.2)
