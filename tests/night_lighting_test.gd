extends GdUnitTestSuite


func test_main_scene_uses_night_lighting_with_readable_danger_pools() -> void:
	var runner := scene_runner("res://scenes/main/main.tscn")
	await runner.simulate_frames(2)
	var main := runner.scene()
	var world_environment := main.get_node("WorldEnvironment") as WorldEnvironment
	var environment := world_environment.environment
	var moonlight := main.get_node("Sun") as DirectionalLight3D
	var window_light := main.get_node("Kitchen/WindowLightZone/SpotLight3D") as SpotLight3D
	var cabinet_light := main.get_node("Kitchen/UnderCabinetLightZone/OmniLight3D") as OmniLight3D
	var light_pool := main.get_node("Kitchen/WindowLightZone/LightPool") as MeshInstance3D
	var light_pool_material := light_pool.mesh.material as StandardMaterial3D
	var roach_head := main.get_node("Player/Cockroach/Head") as MeshInstance3D
	var roach_outline := roach_head.material_overlay as ShaderMaterial

	assert_int(environment.background_mode).is_equal(Environment.BG_SKY)
	assert_int(environment.ambient_light_source).is_equal(Environment.AMBIENT_SOURCE_COLOR)
	assert_float(environment.ambient_light_energy).is_greater(0.0)
	assert_float(environment.ambient_light_energy).is_less(1.0)
	assert_float(moonlight.light_color.b).is_greater(moonlight.light_color.r)
	assert_float(moonlight.light_energy).is_less(window_light.light_energy)
	assert_float(moonlight.light_energy).is_less(cabinet_light.light_energy)
	assert_bool(moonlight.shadow_enabled).is_true()
	assert_bool(window_light.shadow_enabled).is_true()
	assert_bool(cabinet_light.shadow_enabled).is_true()
	assert_bool(light_pool_material.emission_enabled).is_true()
	assert_float(light_pool_material.albedo_color.a).is_greater(0.4)
	assert_object(roach_outline.shader).is_not_null()
	assert_float(roach_outline.get_shader_parameter("outline_size")).is_less(0.02)
	assert_bool(roach_outline.get_shader_parameter("outline_enabled")).is_false()
