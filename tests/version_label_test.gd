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


func test_version_label_scales_with_viewport_height_and_clamps() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(1)
	var version_label := runner.scene().get_node("VersionLabel")
	var label := version_label.get_node("Label") as Label

	version_label.apply_viewport_height(1080.0)
	assert_int(label.get_theme_font_size("font_size")).is_equal(24)

	version_label.apply_viewport_height(2160.0)
	assert_int(label.get_theme_font_size("font_size")).is_equal(48)

	version_label.apply_viewport_height(4320.0)
	assert_int(label.get_theme_font_size("font_size")).is_equal(48)

	version_label.apply_viewport_height(360.0)
	assert_int(label.get_theme_font_size("font_size")).is_equal(12)
