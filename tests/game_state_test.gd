extends GdUnitTestSuite

const GameStateScript := preload("res://scripts/game_state.gd")
const DetectionScript := preload("res://scripts/detection.gd")


func before_test() -> void:
	get_tree().paused = false


func after_test() -> void:
	Input.action_release("confirm")
	Input.action_release("jump")
	Input.action_release("debug_die")
	Input.action_release("debug_game_over")
	get_tree().paused = false


func test_state_machine_tracks_lives_reason_transitions_and_clamps() -> void:
	var game_state := _create_game_state()
	assert_int(game_state.state).is_equal(GameState.State.READY)
	assert_int(game_state.lives).is_equal(5)
	assert_bool(get_tree().paused).is_true()

	game_state.start_run()
	assert_int(game_state.state).is_equal(GameState.State.PLAYING)
	assert_bool(get_tree().paused).is_false()

	for death_number in range(1, 6):
		var reason := "Test death %d" % death_number
		game_state.kill_player(reason)
		assert_int(game_state.lives).is_equal(5 - death_number)
		assert_str(game_state.death_reason).is_equal(reason)
		assert_bool(get_tree().paused).is_true()
		if death_number < 5:
			assert_int(game_state.state).is_equal(GameState.State.DEAD)
			game_state.dismiss_death()
			assert_int(game_state.state).is_equal(GameState.State.PLAYING)
		else:
			assert_int(game_state.state).is_equal(GameState.State.GAME_OVER)

	game_state.kill_player("Ignored after game over")
	assert_int(game_state.lives).is_equal(0)
	assert_str(game_state.death_reason).is_equal("Test death 5")


func test_dismiss_game_over_restores_fresh_ready_state() -> void:
	var game_state := _create_game_state()
	game_state.start_run()
	game_state.player.global_position = Vector3(20.0, 0.0, -20.0)
	game_state.player.velocity = Vector3(4.0, 1.0, 3.0)
	game_state.detection.level = 0.8
	for death_number in range(5):
		game_state.kill_player("Death %d" % death_number)
		if game_state.state == GameState.State.DEAD:
			game_state.dismiss_death()

	game_state.dismiss_game_over()

	assert_int(game_state.state).is_equal(GameState.State.READY)
	assert_int(game_state.lives).is_equal(5)
	assert_str(game_state.death_reason).is_empty()
	assert_vector(game_state.player.global_position).is_equal(
		game_state.spawn_point.global_position
	)
	assert_vector(game_state.player.velocity).is_equal(Vector3.ZERO)
	assert_float(game_state.detection.level).is_equal(0.0)
	assert_bool(get_tree().paused).is_true()


func test_debug_actions_drive_death_and_game_over() -> void:
	var game_state := _create_game_state()
	game_state.start_run()

	Input.action_press("debug_die")
	game_state.step_input()
	Input.action_release("debug_die")
	assert_int(game_state.state).is_equal(GameState.State.DEAD)
	assert_str(game_state.death_reason).is_equal("Squished by the debug key")
	game_state.dismiss_death()

	Input.action_press("debug_game_over")
	game_state.step_input()
	Input.action_release("debug_game_over")
	assert_int(game_state.state).is_equal(GameState.State.GAME_OVER)
	assert_int(game_state.lives).is_equal(0)


func test_run_actions_use_expected_physical_keys() -> void:
	assert_bool(_action_uses_physical_key("confirm", KEY_ENTER)).is_true()
	assert_bool(_action_uses_physical_key("confirm", KEY_SPACE)).is_true()
	assert_bool(_action_uses_physical_key("debug_die", KEY_K)).is_true()
	assert_bool(_action_uses_physical_key("debug_game_over", KEY_G)).is_true()


func test_canvas_ui_scales_from_shared_design_resolution() -> void:
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_width")).is_equal(1152)
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_height")).is_equal(648)
	assert_str(ProjectSettings.get_setting("display/window/stretch/mode")).is_equal("canvas_items")
	assert_str(ProjectSettings.get_setting("display/window/stretch/aspect")).is_equal("expand")


func test_main_boots_paused_on_visible_start_screen_and_button_starts() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(1)
	var main := runner.scene()
	var game_state: GameState = main.get_node("GameState")
	var run_ui: RunUI = main.get_node("RunUI")

	assert_int(game_state.state).is_equal(GameState.State.READY)
	assert_bool(get_tree().paused).is_true()
	assert_bool(main.get_node("Player").can_process()).is_false()
	assert_bool(run_ui.can_process()).is_true()
	assert_bool(run_ui.start_overlay.visible).is_true()
	assert_bool(run_ui.death_overlay.visible).is_false()
	assert_bool(run_ui.game_over_overlay.visible).is_false()
	assert_int(run_ui.hearts.get_child_count()).is_equal(5)

	run_ui.start_button.pressed.emit()
	assert_int(game_state.state).is_equal(GameState.State.PLAYING)
	assert_bool(get_tree().paused).is_false()
	assert_bool(main.get_node("Player").can_process()).is_true()


func test_confirm_action_starts_after_shared_jump_input_clears() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(1)
	var game_state: GameState = runner.scene().get_node("GameState")
	var run_ui: RunUI = runner.scene().get_node("RunUI")
	var player: Player = runner.scene().get_node("Player")

	Input.action_press("confirm")
	Input.action_press("jump")
	run_ui.step_input()
	assert_int(game_state.state).is_equal(GameState.State.READY)
	assert_bool(get_tree().paused).is_true()

	Input.action_release("confirm")
	Input.action_release("jump")
	await runner.simulate_frames(2)

	assert_int(game_state.state).is_equal(GameState.State.PLAYING)
	assert_bool(get_tree().paused).is_false()
	assert_float(player.velocity.y).is_less(player.jump_velocity)


func test_confirm_action_dismisses_paused_run_overlays() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(1)
	var game_state: GameState = runner.scene().get_node("GameState")
	var run_ui: RunUI = runner.scene().get_node("RunUI")
	var player: Player = runner.scene().get_node("Player")
	game_state.start_run()
	game_state.kill_player("Mapped continue")

	Input.action_press("confirm")
	Input.action_press("jump")
	run_ui.step_input()
	assert_int(game_state.state).is_equal(GameState.State.DEAD)
	Input.action_release("confirm")
	Input.action_release("jump")
	await runner.simulate_frames(2)
	assert_int(game_state.state).is_equal(GameState.State.PLAYING)
	assert_float(player.velocity.y).is_less(player.jump_velocity)

	for death_number in range(5):
		game_state.kill_player("Death %d" % death_number)
		if game_state.state == GameState.State.DEAD:
			game_state.dismiss_death()
	Input.action_press("confirm")
	run_ui.step_input()
	assert_int(game_state.state).is_equal(GameState.State.GAME_OVER)
	Input.action_release("confirm")
	await runner.simulate_frames(2)

	assert_int(game_state.state).is_equal(GameState.State.READY)
	assert_int(game_state.lives).is_equal(5)


func test_focus_navigation_key_uses_early_any_key_dismissal() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(1)
	var game_state: GameState = runner.scene().get_node("GameState")
	var run_ui: RunUI = runner.scene().get_node("RunUI")
	game_state.start_run()
	game_state.kill_player("Focused continue")
	run_ui.continue_button.grab_focus()

	var tab_event := InputEventKey.new()
	tab_event.physical_keycode = KEY_TAB
	tab_event.pressed = true
	run_ui._input(tab_event)
	assert_int(game_state.state).is_equal(GameState.State.DEAD)

	await runner.simulate_frames(2)
	assert_int(game_state.state).is_equal(GameState.State.PLAYING)


func test_debug_keys_used_as_any_key_do_not_trigger_again_after_dismissal() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(1)
	var game_state: GameState = runner.scene().get_node("GameState")
	var run_ui: RunUI = runner.scene().get_node("RunUI")
	game_state.start_run()

	var debug_actions := ["debug_die", "debug_game_over"]
	var debug_keys := [KEY_K, KEY_G]
	for index in range(debug_actions.size()):
		game_state.kill_player("Set up death overlay")
		var expected_lives := game_state.max_lives - index - 1
		Input.action_press(debug_actions[index])
		var key_event := InputEventKey.new()
		key_event.physical_keycode = debug_keys[index]
		key_event.pressed = true
		run_ui._input(key_event)

		game_state.step_input()
		assert_int(game_state.state).is_equal(GameState.State.DEAD)
		assert_int(game_state.lives).is_equal(expected_lives)

		Input.action_release(debug_actions[index])
		await runner.simulate_frames(2)
		assert_int(game_state.state).is_equal(GameState.State.PLAYING)
		assert_int(game_state.lives).is_equal(expected_lives)


func test_death_overlay_loses_heart_and_continue_respawns() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(1)
	var main := runner.scene()
	var game_state: GameState = main.get_node("GameState")
	var run_ui: RunUI = main.get_node("RunUI")
	var player: Player = main.get_node("Player")
	var detection: Detection = player.get_node("Detection")
	var spawn_point := main.get_node("KitchenSpawn") as Marker3D
	var camera_rig: CameraRig = main.get_node("CameraRig")
	game_state.start_run()
	player.global_position = Vector3(9.0, 0.0, -9.0)
	player.velocity = Vector3(2.0, 0.0, 1.0)
	detection.level = 0.7
	camera_rig.global_position = player.global_position

	game_state.kill_player("Caught in the cookie jar")

	assert_bool(run_ui.death_overlay.visible).is_true()
	assert_str(run_ui.cause_label.text).is_equal("Cause: Caught in the cookie jar")
	assert_int(game_state.lives).is_equal(4)
	assert_float((run_ui.hearts.get_child(4) as Label).modulate.a).is_less(
		(run_ui.hearts.get_child(0) as Label).modulate.a
	)

	run_ui.continue_button.pressed.emit()

	assert_int(game_state.state).is_equal(GameState.State.PLAYING)
	assert_vector(player.global_position).is_equal(spawn_point.global_position)
	assert_vector(player.velocity).is_equal(Vector3.ZERO)
	assert_float(detection.level).is_equal(0.0)
	assert_vector(camera_rig.global_position).is_equal(spawn_point.global_position)
	assert_bool(get_tree().paused).is_false()


func test_fifth_death_shows_game_over_and_return_restores_start() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(1)
	var main := runner.scene()
	var game_state: GameState = main.get_node("GameState")
	var run_ui: RunUI = main.get_node("RunUI")
	game_state.start_run()

	for death_number in range(5):
		game_state.kill_player("Death %d" % death_number)
		if game_state.state == GameState.State.DEAD:
			game_state.dismiss_death()

	assert_int(game_state.state).is_equal(GameState.State.GAME_OVER)
	assert_int(game_state.lives).is_equal(0)
	assert_bool(run_ui.game_over_overlay.visible).is_true()
	assert_bool(get_tree().paused).is_true()

	run_ui.game_over_button.pressed.emit()

	assert_int(game_state.state).is_equal(GameState.State.READY)
	assert_int(game_state.lives).is_equal(5)
	assert_bool(run_ui.start_overlay.visible).is_true()
	assert_bool(run_ui.game_over_overlay.visible).is_false()
	assert_bool(get_tree().paused).is_true()


func test_keyboard_game_over_button_stops_on_start_screen() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(1)
	var game_state: GameState = runner.scene().get_node("GameState")
	var run_ui: RunUI = runner.scene().get_node("RunUI")
	game_state.start_run()
	for death_number in range(5):
		game_state.kill_player("Death %d" % death_number)
		if game_state.state == GameState.State.DEAD:
			game_state.dismiss_death()

	Input.action_press("confirm")
	run_ui.game_over_button.pressed.emit()
	run_ui.step_input()
	assert_int(game_state.state).is_equal(GameState.State.GAME_OVER)

	Input.action_release("confirm")
	await runner.simulate_frames(3)
	assert_int(game_state.state).is_equal(GameState.State.READY)
	assert_bool(run_ui.start_overlay.visible).is_true()
	assert_bool(get_tree().paused).is_true()


func _create_game_state() -> GameState:
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	var player := CharacterBody3D.new()
	player.position = Vector3(8.0, 0.0, 8.0)
	world.add_child(player)
	var detection := DetectionScript.new()
	player.add_child(detection)
	var spawn_point := Marker3D.new()
	spawn_point.position = Vector3(3.0, 0.0, -2.0)
	world.add_child(spawn_point)
	var game_state: GameState = GameStateScript.new()
	game_state.player = player
	game_state.spawn_point = spawn_point
	game_state.detection = detection
	world.add_child(game_state)
	return game_state


func _action_uses_physical_key(action: StringName, physical_keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event != null and key_event.physical_keycode == physical_keycode:
			return true
	return false
