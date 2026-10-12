extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event


func _run() -> void:
	var demo: Node3D = load("res://demo/scenes/forest_demo.tscn").instantiate()
	root.add_child(demo)
	await process_frame
	var track: DemoTrack = demo.get_node("Track")
	var world: Node3D = track.get_node("GeneratedWorld")
	var effects = demo.get_node("ScreenEffects")
	var camera: DemoChaseCamera = demo.get_node("ChaseCamera")
	var hud: DemoHUD = demo.get_node("HUD/Interface")
	demo.get_node("Motorcycle").set_physics_process(false)
	demo.get_node("Traffic").set_physics_process(false)
	camera.set_physics_process(false)
	effects.set_process(false)
	_check(world.get_meta("tree_count", 0) >= 2400, "The forest must remain dense around rural clearings")
	_check(world.get_meta("ground_prop_count", 0) >= 5000, "The understory must have thousands of clustered props")
	_check(world.get_meta("scenery_batch_count", 1000) < 300, "Scenery must use bounded section batches")
	_check(world.has_node("ForestCabin0") and world.has_node("ForestCabin4") and world.has_node("PicnicSpot5"), "Roadside landmarks must build around the loop")
	_check(world.has_node("VillageRiver") and world.has_node("VillageChurch") and world.has_node("VillageHouse11") and world.has_node("RiverFootbridge"), "River, village, church and bridge must build")
	_check(world.get_meta("crop_count", 0) > 2000, "Fields must contain dense sunflower and wheat rows")
	var fence_segments: int = 0
	for fence: Node in world.get_children():
		if not fence.name.begins_with("FarmFence"):
			continue
		for piece: MeshInstance3D in fence.get_children():
			# Verify both ends of every rail, not just the fence's starting anchor.
			var size: Vector3 = piece.mesh.size
			if size.z < 0.2:
				continue
			fence_segments += 1
			for end: float in [-0.5, 0.0, 0.5]:
				var point: Vector3 = piece.to_global(Vector3(0, 0, size.z * end))
				var along: float = track.curve.get_closest_offset(track.to_local(point))
				var frame: Transform3D = track.frame_at(along)
				var clearance: float = absf((point - frame.origin).dot(frame.basis.x)) - track.road_width * 0.5
				_check(clearance > 1.0, "Fence rails must stay outside the entire road through bends")
	_check(fence_segments > 400, "Long fences must follow bends in short segments")
	var valid_bounds: bool = true
	var instance_count: int = 0
	for node: Node in world.get_children():
		if not node.name.begins_with("SceneryBatch_"):
			continue
		var mesh: MultiMesh = node.multimesh
		instance_count += mesh.instance_count
		# The headless dummy renderer does not retain per-instance GPU transforms.
		valid_bounds = valid_bounds and mesh.custom_aabb.size.is_finite() and mesh.custom_aabb.size.y > 0.3 and mesh.custom_aabb.size.x > 0.3
	_check(valid_bounds and instance_count > 8000, "All shader-expanded scenery must have explicit bounds")
	_check(InputMap.action_get_events("cycle_graphics")[0].physical_keycode == KEY_F2, "F2 must open graphics settings")
	_check(InputMap.action_get_events("toggle_speed_effects")[0].physical_keycode == KEY_F3, "F3 must toggle motion effects")
	var settings = demo.get_node("GraphicsSettings")
	settings.values = settings.DEFAULTS.duplicate()
	settings._apply_world()
	demo._unhandled_input(_key(KEY_F2))
	_check(settings.panel.visible and paused, "Graphics menu must open and pause the ride")
	_check(hud.settings_open, "Graphics preview must not be dimmed by the pause overlay")
	settings._select_preset(4)
	_check(effects.mode_index == 4 and is_zero_approx(effects.settings.dither), "Cinematic preset must disable noisy dithering")
	settings._change("stability", 0.9, true)
	_check(is_equal_approx(effects.effect.get_shader_parameter("stability"), 0.9), "Custom settings must reach the screen shader")
	settings._change("corner_hud", false, false)
	_check(not hud.corner_layout, "Classic centered HUD must remain selectable")
	settings.toggle_hud()
	_check(hud.corner_layout, "HUD shortcut must restore corner instruments")
	settings.values.bake = 2.0
	settings._apply_textures()
	var atlas: AtlasTexture = settings.atlases[0]
	var original: Texture2D = atlas.get_meta("graphics_source")
	_check(atlas.atlas != original and atlas.atlas.get_size() == original.get_size(), "Baked atlases must preserve source coordinates")
	settings.values.bake = 1.0
	settings.values.mipmaps = false
	settings._apply_textures()
	_check(atlas.atlas == original, "Source atlas must be recoverable without mipmaps or baking")
	settings.toggle_menu()
	_check(not settings.panel.visible and not paused, "Closing settings must restore the previous pause state")
	effects.apply_mode(2)
	effects.speed_amount = 0.8
	paused = true
	settings.toggle_menu()
	_check(settings.panel.visible and effects.mode_index == 2, "Graphics settings must remain accessible while paused")
	settings.toggle_menu()
	demo._unhandled_input(_key(KEY_F3))
	_check(not effects.motion_enabled and is_zero_approx(camera.speed_visual_strength), "F3 must disable both screen streaks and camera widening")
	_check(is_zero_approx(effects.effect.get_shader_parameter("speed_amount")), "Motion must disappear immediately while paused")
	demo._unhandled_input(_key(KEY_F3))
	_check(effects.motion_enabled and camera.speed_visual_strength > 0.0, "F3 must restore motion")
	paused = false
	demo._unhandled_input(_key(KEY_R))
	_check(effects.mode_index == 2 and is_zero_approx(effects.speed_amount), "Restart must keep the chosen look and clear speed effects")
	effects.apply_mode(0)
	_check(is_zero_approx(effects.effect.get_shader_parameter("steps")) and is_zero_approx(camera.speed_visual_strength), "Original mode must disable color filtering and speed distortion")
	print("SCENERY / GRAPHICS: %s | %d trees, %d ground props, %d batches; 5 presets, F2 menu, corner HUD, texture baking, F3, pause, reset" % ["PASS" if failures == 0 else "FAIL", world.get_meta("tree_count"), world.get_meta("ground_prop_count"), world.get_meta("scenery_batch_count")])
	demo.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit(0 if failures == 0 else 1)
