extends GdUnitTestSuite


func after_test() -> void:
	Input.action_release("move_right")


func test_kitchen_scene_boots_without_errors() -> void:
	var runner := scene_runner("res://scenes/kitchen/kitchen.tscn")
	await runner.simulate_frames(2)
	assert_object(runner.scene()).is_not_null()


func test_player_stops_at_east_wall() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var player: Player = runner.scene().get_node("Player")
	player.position = Vector3(13.0, 0.0, 7.0)
	player.velocity = Vector3.ZERO
	var starting_x := player.position.x
	Input.action_press("move_right")
	for _step in 120:
		player._physics_process(1.0 / 60.0)
	assert_float(player.position.x).is_greater(starting_x)
	assert_float(player.position.x).is_less(14.6)
