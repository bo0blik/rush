extends SceneTree

var failures: int = 0


func _initialize() -> void:
	Engine.max_fps = 120
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var demo: Node3D = load("res://demo/scenes/forest_demo.tscn").instantiate()
	root.add_child(demo)
	await process_frame
	var rider = demo.get_node("Motorcycle")
	var traffic = demo.get_node("Traffic")
	var camera = demo.get_node("ChaseCamera")
	rider.set_physics_process(false)
	traffic.set_physics_process(false)
	camera.set_physics_process(false)
	_check(rider.character.parts.size() == 12, "Character must use independent articulated clothing parts")
	var car = traffic.vehicles[0]
	_check(car.body_width > rider.profile.body_width_m * 1.8, "Car must be substantially wider than the motorcycle")
	for vehicle_name: String in ["sedan", "truck"]:
		var frames: SpriteFrames = load("res://demo/resources/%s_animation_frames.tres" % vehicle_name)
		for pose in range(6):
			var texture: AtlasTexture = frames.get_frame_texture(&"front_angles", pose)
			_check(bool(texture.get_meta("source_flip_h", false)) == (vehicle_name == "sedan"), "Sedan front quarter artwork must match the truck's canonical side")
			car.sprite.set_pair(texture, frames.get_frame_texture(&"side_angles", 2), 0.5, false)
			_check(bool(car.sprite.material.get_shader_parameter("source_flip_a")) == (vehicle_name == "sedan") and not bool(car.sprite.material.get_shader_parameter("source_flip_b")), "Each side/front source must retain its own orientation while blending")
	var road_frame: Transform3D = traffic.track.frame_at(car.distance)
	var center: Vector3 = road_frame.origin + road_frame.basis.x * car.lateral
	camera.global_position = center + road_frame.basis.z * 10.0
	car.place(traffic.track, camera)
	_check(car.current_view == 0, "Behind a car must display its rear")
	_check(absf(car.display_angle) < 0.01, "Straight rear alignment must select a straight angle")
	camera.global_position = center + road_frame.basis.x * 10.0 + road_frame.basis.z
	car.place(traffic.track, camera, 1.0 / 60.0)
	_check(car.display_angle > 0.0 and car.display_angle < 0.5, "View angle must ease rather than snap")
	car.place(traffic.track, camera)
	var region_a: Vector4 = car.sprite.material.get_shader_parameter("rect_a")
	var region_b: Vector4 = car.sprite.material.get_shader_parameter("rect_b")
	var blend: float = car.sprite.material.get_shader_parameter("frame_blend")
	var scale_a: Vector2 = car.sprite.material.get_shader_parameter("scale_a")
	var scale_b: Vector2 = car.sprite.material.get_shader_parameter("scale_b")
	var rendered_width: float = lerpf(scale_a.x * (region_a.z - 2.0), scale_b.x * (region_b.z - 2.0), blend)
	_check(is_equal_approx(scale_a.x, scale_a.y) and is_equal_approx(scale_b.x, scale_b.y), "Car artwork must never stretch on one axis")
	_check(rendered_width > car.body_width * 1.8, "An authored side profile must show the vehicle length")
	# Both sides of a pass converge on the exact same profile instead of flipping front/rear.
	for z: float in [0.01, -0.01]:
		camera.global_position = center + road_frame.basis.x * 10.0 + road_frame.basis.z * z
		car.place(traffic.track, camera)
		_check(car.sprite.animation == &"side_angles", "Crossing the car's midpoint must retain the side profile")
		var amount: float = car.sprite.material.get_shader_parameter("frame_blend")
		_check(amount < 0.001 or amount > 0.999, "A pass must converge continuously on the same side frame")
	camera.snap_to_rider()
	var effects = demo.get_node("ScreenEffects")
	effects.set_process(false)
	effects.reset()
	rider.speed = 32.0
	effects._process(1.0)
	_check(effects.speed_amount > 0.5, "High speed and acceleration must create peripheral speed streaks")
	rider.speed = 0.0
	effects._process(1.0)
	_check(effects.speed_amount < 0.05, "Speed streaks must fade when the rider stops")
	paused = true
	_check(not effects.can_process(), "Screen motion must pause with the game")
	paused = false
	effects.reset()
	_check(is_zero_approx(effects.speed_amount) and is_zero_approx(effects.motion_time), "Reset must clear screen motion")
	rider.reset()
	rider.speed = 30.0
	rider.hit_traffic(45.0, -1.0, 0.0, 0.8)
	_check(rider.character.ragdoll_active, "Major hit must release the physical rider")
	rider.step_controls(1.0, 0.0, 1.0, 0.4)
	_check(is_zero_approx(rider.speed), "Throttle must not move the bike after rider detaches")
	rider.reset()
	rider.hit_traffic(12.0, -1.0, 0.0, 0.8)
	_check(not rider.character.ragdoll_active and rider.impact_duration < 1.0, "Glancing contact must retain the mounted rider")
	rider.reset()
	_check(not rider.character.ragdoll_active and is_zero_approx(rider.impact_time), "Reset must restore riding")
	print("ANIMATION SMOKE: %s | articulated rider / 27 car frames, uniform scale, continuous pass, screen effects, fall, recovery, reset" %
		("PASS" if failures == 0 else "FAIL (%d)" % failures))
	demo.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit(0 if failures == 0 else 1)
