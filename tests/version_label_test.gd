extends GdUnitTestSuite


func test_version_label_matches_project_setting() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(1)
	var version_label := runner.scene().get_node("VersionLabel") as CanvasLayer
	var label := version_label.get_node("Label") as Label

	assert_object(version_label).is_not_null()
	assert_str(label.text).is_equal(
		str(ProjectSettings.get_setting("application/config/version", "dev"))
	)


func test_version_stamp_stays_small_at_4k() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(1)
	var version_label := runner.scene().get_node("VersionLabel")
	var label := version_label.get_node("Label") as Label

	version_label.apply_render_scale(Vector2(3840.0, 2160.0), Vector2(1152.0, 648.0))

	assert_float(label.scale.x).is_equal_approx(0.3, 0.001)
	assert_float(label.scale.y).is_equal_approx(0.3, 0.001)
