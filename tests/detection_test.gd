extends GdUnitTestSuite

const DetectionScript := preload("res://scripts/detection.gd")
const LightZoneScript := preload("res://scripts/light_zone.gd")


func test_detection_fills_drains_and_clamps_with_direct_steps() -> void:
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	var zone := LightZoneScript.new()
	world.add_child(zone)
	var player := CharacterBody3D.new()
	world.add_child(player)
	var detection := DetectionScript.new()
	detection.fill_rate = 0.4
	detection.drain_rate = 0.25
	player.add_child(detection)

	zone.body_entered.emit(player)
	detection.step(1.0)
	assert_float(detection.level).is_equal_approx(0.4, 0.001)
	detection.step(10.0)
	assert_float(detection.level).is_equal(1.0)

	zone.body_exited.emit(player)
	detection.step(1.0)
	assert_float(detection.level).is_equal_approx(0.75, 0.001)
	detection.step(10.0)
	assert_float(detection.level).is_equal(0.0)


func test_detection_stays_lit_until_all_overlapping_zones_exit() -> void:
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	var first_zone := LightZoneScript.new()
	world.add_child(first_zone)
	var second_zone := LightZoneScript.new()
	world.add_child(second_zone)
	var player := CharacterBody3D.new()
	world.add_child(player)
	var detection := DetectionScript.new()
	player.add_child(detection)

	first_zone.body_entered.emit(player)
	second_zone.body_entered.emit(player)
	first_zone.body_exited.emit(player)

	assert_int(detection.light_zone_count).is_equal(1)
	assert_bool(detection.is_lit()).is_true()


func test_main_scene_fills_in_light_and_drains_in_shadow() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var main := runner.scene()
	var player: Player = main.get_node("Player")
	var detection := player.get_node("Detection") as DetectionScript
	var light_zone := main.get_node("Kitchen/WindowLightZone") as Area3D
	detection.set_physics_process(false)

	player.global_position = Vector3(
		light_zone.global_position.x, 0.0, light_zone.global_position.z
	)
	player.force_update_transform()
	player.velocity = Vector3.ZERO
	await runner.await_signal_on(light_zone, "body_entered", [player])
	var shadow_level := detection.level
	detection.step(0.5)
	assert_float(detection.level).is_greater(shadow_level)

	player.global_position = Vector3(-13.5, 0.0, 8.0)
	player.force_update_transform()
	player.velocity = Vector3.ZERO
	await runner.await_signal_on(light_zone, "body_exited", [player])
	assert_bool(detection.is_lit()).is_false()
	var light_level := detection.level
	detection.step(0.5)
	assert_float(detection.level).is_less(light_level)
