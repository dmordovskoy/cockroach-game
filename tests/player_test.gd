extends GdUnitTestSuite


func after_test() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	Input.action_release("jump")


func test_jump_action_uses_physical_space() -> void:
	var has_physical_space := false
	for event in InputMap.action_get_events("jump"):
		var key_event := event as InputEventKey
		if key_event != null and key_event.physical_keycode == KEY_SPACE:
			has_physical_space = true
			break
	assert_bool(has_physical_space).is_true()


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


func test_jump_rises_lands_and_rejects_midair_impulse() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var player: Player = runner.scene().get_node("Player")
	_simulate_until_grounded(player)
	assert_bool(player.is_on_floor()).is_true()
	var floor_height := player.position.y

	Input.action_press("jump")
	player._physics_process(1.0 / 60.0)
	Input.action_release("jump")
	assert_float(player.position.y).is_greater(floor_height)
	assert_float(player.velocity.y).is_equal_approx(player.jump_velocity, 0.001)

	player._physics_process(1.0 / 60.0)
	var velocity_before_second_press := player.velocity.y
	Input.action_press("jump")
	player._physics_process(1.0 / 60.0)
	Input.action_release("jump")
	assert_float(player.velocity.y).is_less(velocity_before_second_press)
	assert_float(player.velocity.y).is_less(player.jump_velocity)

	_simulate_until_grounded(player)
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.position.y).is_equal_approx(floor_height, 0.001)


func test_horizontal_movement_unaffected_while_airborne() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var player: Player = runner.scene().get_node("Player")
	_simulate_until_grounded(player)
	var starting_position := player.position

	Input.action_press("jump")
	player._physics_process(1.0 / 60.0)
	Input.action_release("jump")
	Input.action_press("move_right")
	for _step in 10:
		player._physics_process(1.0 / 60.0)

	assert_float(player.position.x).is_greater(starting_position.x)
	assert_float(player.position.y).is_greater(starting_position.y)
	assert_float(player.velocity.x).is_greater(0.0)


func _simulate_until_grounded(player: Player) -> void:
	for _step in 120:
		if player.is_on_floor():
			return
		player._physics_process(1.0 / 60.0)
