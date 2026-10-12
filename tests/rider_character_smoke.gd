extends SceneTree
var failures: int = 0
func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var demo: Node3D = load("res://demo/scenes/forest_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	await process_frame
	var bike: DemoMotorcycle = demo.get_node("Motorcycle")
	var character: RiderCharacter = bike.character
	bike.set_physics_process(false)
	demo.get_node("Traffic").set_physics_process(false)
	_check(character.simulator.get_child_count() == 19, "Installed Auto Ragdoll must generate 19 physical bones")
	_check(not bike.has_node("Rider") and character.parts.size() == 12, "Legacy combined artwork must be replaced by independent rider parts")
	character._process(0.0)
	character.mounted_visual._process(0.0)
	_check(character.mounted_visual.visible and not character.parts[0].sprite.visible, "Mounted rider must use one connected authored silhouette")
	var head: Vector3 = character.skeleton.get_bone_global_pose(character.bone_ids.head).origin
	_check(head.y > 1.3 and head.y < 1.8, "Seated skeleton must keep correct human scale")
	var original_jacket: int = character.jacket
	character.jacket = 1 - original_jacket
	character._refresh_textures(false)
	var texture = character.parts[0].sprite.texture
	bike.cycle_bike()
	_check(character.jacket == 1 - original_jacket and character.parts[0].sprite.texture == texture, "Outfit must survive bike switching")
	character.jacket = original_jacket
	character._refresh_textures(false)
	for kind: String in ["punch", "kick"]:
		for side: float in [-1.0, 1.0]:
			character.mount(bike)
			var endpoint: String = ("left" if side < 0 else "right") + ("_hand" if kind == "punch" else "_foot")
			var index: int = character.bone_ids[endpoint]
			var resting: Vector3 = character.skeleton.get_bone_global_pose(index).origin
			character.start_attack(kind, side)
			character._physics_process(character.attack_duration * 0.4)
			var striking: Vector3 = character.skeleton.get_bone_global_pose(index).origin
			_check((striking.x - resting.x) * side > 0.35, "Punch/kick must extend the correct limb outward")
			character._physics_process(character.attack_duration)
			_check(character.attack.is_empty(), "Attack must blend back to riding")
	character.mount(bike)
	await physics_frame
	var start: Vector3 = character.focus_position()
	bike.speed = 20.0
	bike.hit_traffic(30.0, 1.0, bike.lateral, 0.0)
	_check(character.ragdoll_active and character.top_level and character.simulator.is_simulating_physics(), "Severe impact must detach the rider and enable physical simulation")
	character._process(0.0)
	character.mounted_visual._process(0.0)
	_check(not character.mounted_visual.visible and character.parts[0].sprite.visible, "A crash must transfer rendering to the articulated physical body")
	_check(bike.bike_visual.free_body != null, "Motorcycle must fall separately from its rider")
	character.start_attack("kick", 1.0)
	_check(character.attack.is_empty(), "Detached rider must not attack")
	for i in range(90):
		await physics_frame
	var finish: Vector3 = character.focus_position()
	print("Ragdoll displacement: ", finish - start, " simulator active: ", character.simulator.active)
	_check(start.distance_to(finish) > 2.0 and finish.is_finite(), "Ragdoll must fly through the world, not play a stationary sprite animation")
	_check(character.simulator.active, "Physical simulator must remain active throughout the fall")
	for i in range(180):
		await physics_frame
	var landed: Vector3 = character.focus_position()
	var ray := PhysicsRayQueryParameters3D.create(landed + Vector3.UP * 10.0, landed - Vector3.UP * 20.0, 1)
	var ground: Dictionary = root.get_world_3d().direct_space_state.intersect_ray(ray)
	print("Landed: ", landed, " ground: ", ground.get("position", Vector3.ZERO))
	_check(not ground.is_empty() and landed.y >= Vector3(ground.position).y - 0.4 and landed.y < Vector3(ground.position).y + 1.5, "Ragdoll must land on local road collision rather than fall through the ground")
	bike.reset()
	await physics_frame
	_check(not character.ragdoll_active and not character.top_level and not character.simulator.is_simulating_physics(), "R must restore the seated rider and stop simulation")
	_check(bike.bike_visual.free_body == null, "Reset must remove fallen motorcycle body")
	# Use the same staged parked-car collision as F9, including the real swept detector.
	bike.speed = 22.0
	demo.get_node("Traffic").setup_crash_test()
	var car: Node3D = demo.get_node("Traffic").vehicles[0]
	var cleared_car: bool = false
	var above_roof: bool = false
	var highest: float = 0.0
	var furthest: float = 100.0
	for i in range(120):
		bike.step_controls(0.0, 0.0, 0.0, 1.0 / 60.0)
		demo.get_node("Traffic").step_traffic(1.0 / 60.0)
		await physics_frame
		if character.ragdoll_active:
			var relative: Vector3 = car.to_local(character.focus_position())
			above_roof = above_roof or relative.y > car.body_height
			cleared_car = cleared_car or relative.z < -car.body_length * 0.5
			highest = maxf(highest, relative.y)
			furthest = minf(furthest, relative.z)
	print("Car flight: active=", character.ragdoll_active, " highest=", highest, " furthest=", furthest)
	_check(character.ragdoll_active and above_roof and cleared_car, "Parked-car crash must physically eject the rider above and beyond the car")
	bike.reset()
	for kind: String in ["punch", "kick"]:
		for side: float in [-1.0, 1.0]:
			character.mount(bike)
			car.distance = bike.start_distance + bike.traveled
			car.lateral = bike.lateral + side * 1.6
			car.attack_reaction = 0.0
			car.place(bike.track, demo.get_node("ChaseCamera"))
			await physics_frame
			character.start_attack(kind, side)
			character._physics_process(character.attack_duration * 0.4)
			_check(car.attack_reaction > 0.5 and character.attack_hits.size() == 1, "Each hand/foot strike must hit the adjacent car once during its active window")
	bike.reset()
	print("RIDER CHARACTER: ", "PASS" if failures == 0 else "FAIL", " | separate art, outfit, IK, four attacks, detached flight, ground, reset")
	demo.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit(0 if failures == 0 else 1)
