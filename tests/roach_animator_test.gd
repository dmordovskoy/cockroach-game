extends GdUnitTestSuite


func after_test() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")


func test_imported_model_has_rig_and_named_animations() -> void:
	var runner := scene_runner("res://scenes/player/player.tscn")
	await runner.simulate_frames(1, 16)
	var animator := runner.scene().get_node("Cockroach") as RoachAnimator
	var skeleton := animator.find_child("Skeleton3D", true, false) as Skeleton3D

	assert_object(skeleton).is_not_null()
	assert_int(skeleton.get_bone_count()).is_equal(17)
	assert_bool(animator.animation_player.has_animation("scuttle")).is_true()
	assert_bool(animator.animation_player.has_animation("idle")).is_true()


func test_step_selects_animation_from_horizontal_velocity() -> void:
	var runner := scene_runner("res://scenes/player/player.tscn")
	await runner.simulate_frames(1, 16)
	var player := runner.scene() as Player
	var animator := player.get_node("Cockroach") as RoachAnimator

	player.velocity = Vector3(0.19, 10.0, 0.0)
	animator.step(0.016)
	assert_str(animator.animation_player.current_animation).is_equal("idle")

	player.velocity = Vector3(6.0, 0.0, 0.0)
	animator.step(0.016)
	assert_str(animator.animation_player.current_animation).is_equal("scuttle")
	assert_float(animator.animation_player.speed_scale).is_equal_approx(1.0, 0.001)


func test_scene_scuttles_while_moving_then_returns_to_idle() -> void:
	var runner := scene_runner("res://scenes/player/player.tscn")
	Input.action_press("move_right")
	await runner.simulate_frames(2, 16)
	var player := runner.scene() as Player
	var animator := player.get_node("Cockroach") as RoachAnimator

	assert_str(animator.animation_player.current_animation).is_equal("scuttle")

	Input.action_release("move_right")
	for _step_index in range(10):
		player._physics_process(0.016)
		animator.step(0.016)
	assert_str(animator.animation_player.current_animation).is_equal("idle")
