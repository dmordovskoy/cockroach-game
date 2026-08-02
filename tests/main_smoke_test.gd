extends GdUnitTestSuite


func test_main_scene_boots_without_errors() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(60)
	assert_object(runner.scene()).is_not_null()
