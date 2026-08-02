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
