extends SceneTree
## Run: Godot --headless --path . --script res://tests/demo_smoke.gd

var failures: int = 0


func _initialize() -> void:
	Engine.max_fps = 120
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var scene: PackedScene = load("res://demo/scenes/forest_demo.tscn")
	_check(scene != null, "Demo scene must load")
	if scene == null:
		quit(1)
		return
	var demo: Node3D = scene.instantiate()
	root.add_child(demo)
	await process_frame
	var track: DemoTrack = demo.get_node("Track")
	var rider: DemoMotorcycle = demo.get_node("Motorcycle")
	rider.set_physics_process(false)
	demo.get_node("Traffic").set_physics_process(false)
	demo.get_node("ChaseCamera").set_physics_process(false)
	_check(track.curve.closed and track.length > 1000.0, "Route must be a long closed circuit")
	_check(track.frame_at(0.0).origin.distance_to(track.frame_at(track.length).origin) < 0.001,
		"Circuit must wrap without a position discontinuity")
	_check(track.frame_at(-0.01).basis.z.dot(track.frame_at(0.01).basis.z) > 0.99,
		"Circuit must wrap without a direction discontinuity")
	_check(track.get_node("GeneratedWorld/RoadAndVerge").mesh.get_surface_count() == 1,
		"Road geometry must build")
	for layer in range(3):
		_check(track.has_node("GeneratedWorld/ParallaxRidge%d" % layer), "Parallax ridge must build")
	_check(track.has_node("GeneratedWorld/LakeGuardrail") and track.has_node("GeneratedWorld/TimberBusStop0"),
		"Guardrails and roadside landmarks must build")
	_check(rider.character.parts.size() == 12, "Character must have modular visuals")
	for action: StringName in [&"accelerate", &"brake", &"rear_brake", &"steer_left", &"steer_right", &"pause_demo", &"reset_demo", &"cycle_bike", &"gear_up", &"gear_down"]:
		_check(InputMap.has_action(action), "Input binding missing: %s" % action)
	rider.reset()
	for i in range(60):
		rider.step_controls(1.0, 0.0, 0.0, 1.0 / 60.0)
	_check(rider.speed > 1.0 and rider.traveled > 0.5, "Engine torque must accelerate and move the bike")
	rider.speed = 8.0
	for i in range(180):
		rider.step_controls(0.0, 0.8, 0.0, 1.0 / 60.0, 0.6)
	_check(is_zero_approx(rider.speed), "Both brakes must stop the bike")
	var stopped_at: float = rider.traveled
	var stopped_lane: float = rider.lateral
	for i in range(30):
		rider.step_controls(0.0, 0.0, -1.0, 1.0 / 60.0)
	_check(is_equal_approx(rider.traveled, stopped_at) and is_equal_approx(rider.lateral, stopped_lane),
		"Stationary bike must not slide sideways")
	rider.reset()
	rider.speed = 12.0
	rider.lateral = 0.0
	for i in range(50):
		rider.step_controls(0.5, 0.0, 0.6, 1.0 / 60.0)
	_check(rider.lateral > 0.0 and rider.dynamics.heading > 0.0, "Right steering must change course and lateral position")
	rider.character._pose_mounted(0.0)
	rider.bike_visual._process(0.0)
	rider.character.mounted_visual._process(0.0)
	_check(rider.bike_visual.global_basis.y.dot(rider.character.mounted_visual.global_basis.y) > 0.9999, "Rider and motorcycle must share the same roll direction and amount")
	for i in range(180):
		rider.step_controls(1.0, 0.0, -1.0 if i % 60 < 30 else 1.0, 1.0 / 120.0)
		_check(absf(rider.visual_lean) <= deg_to_rad(18.0) + 0.0001, "Mounted visual bank must stay within 18 degrees even at full throttle")
		rider.character._pose_mounted(0.0)
		rider.bike_visual._process(0.0)
		_check(rider.character.global_basis.y.normalized().dot(rider.bike_visual.global_basis.y.normalized()) > 0.9999, "Visual bank must remain shared by rider and bike")
	var mounted = rider.character.mounted_visual
	rider.dynamics.acceleration = 0.0
	mounted._process(0.2)
	var idle_texture = mounted.texture
	rider.dynamics.acceleration = 3.0
	mounted._process(0.05)
	_check(mounted.texture == idle_texture, "Short acceleration pulses must not flicker the rider silhouette")
	mounted._process(0.2)
	_check(mounted.texture != idle_texture, "Sustained acceleration must still select its authored riding pose")
	var previous_lean: float = rider.dynamics.lean
	rider.step_controls(0.0, 0.0, -1.0, 0.1)
	_check(absf(rider.dynamics.lean - previous_lean) <= deg_to_rad(85.0) * 0.1 + 0.001, "Steering reversal must retain bounded roll inertia")
	rider.reset()
	rider.lateral = 14.0
	rider.hit_traffic(29.0, 1.0, rider.lateral, 0.0)
	_check(is_equal_approx(rider.lateral, 14.0), "An off-road fall must not teleport the rider back toward the road")
	rider.reset()
	rider.speed = 25.0
	rider.step_controls(0.0, 1.0, 0.0, 0.04)
	_check(rider.tire_effects.slipping and rider.tire_effects.smoke.emitting, "Hard braking must emit tire smoke")
	_check(rider.tire_effects.marks[0].visible, "Hard braking must leave a skid mark")
	rider.off_road = true
	rider.tire_effects.update_contact(8.0, 0.0, true, rider.global_transform, 0.04)
	_check(rider.tire_effects.dust.emitting and not rider.tire_effects.smoke.emitting, "Grass must emit dust rather than brake smoke")
	rider.reset()
	var first_mass: float = rider.profile.mass_kg
	rider.cycle_bike()
	_check(rider.profile.mass_kg != first_mass and rider.dynamics.spec == rider.profile and is_zero_approx(rider.speed), "Switching motorcycles must apply a different physical resource and reset dynamics")
	rider.traveled = track.length - 0.1
	rider.lateral = 0.0
	rider.off_road = false
	rider.speed = 5.0
	rider.step_controls(0.0, 0.0, 0.0, 0.1)
	_check(rider.traveled > track.length and rider.global_position.is_finite(), "Bike must pass the loop seam")
	paused = true
	_check(not rider.can_process(), "Pause must stop the rider despite the always-running demo root")
	paused = false
	rider.reset()
	_check(is_zero_approx(rider.speed) and is_zero_approx(rider.traveled), "Reset must restore the start")
	_check(not rider.tire_effects.marks[0].visible and not rider.tire_effects.dust.emitting,
		"Reset must clear tire effects and skid marks")
	print("DEMO SMOKE: %s | route %.1f m | motion easing, smoke, dust, skid reset, scenery, controls" %
		["PASS" if failures == 0 else "FAIL (%d)" % failures, track.length])
	demo.queue_free()
	await process_frame
	# AudioServer retires stopped generator voices on its next mix, not the scene tick.
	await create_timer(0.3).timeout
	quit(0 if failures == 0 else 1)
