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
