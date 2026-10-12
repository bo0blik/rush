extends SceneTree
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var demo: Node3D = load("res://demo/scenes/forest_demo.tscn").instantiate()
	root.add_child(demo)
	await process_frame
	var bike: DemoMotorcycle = demo.get_node("Motorcycle")
	bike.set_physics_process(false)
	demo.get_node("Traffic").set_physics_process(false)
	for profile: MotorcycleSpec in bike.BIKE_PROFILES:
		bike.profile = profile
		bike.dynamics.configure(profile)
		bike.reset()
		var largest_drift: float = 0.0
		var largest_curvature: float = 0.0
		for i in range(9000):
			bike.speed = 12.0
			var frame: Transform3D = bike.track.frame_at(bike.start_distance + bike.traveled)
			var ahead: Transform3D = bike.track.frame_at(bike.start_distance + bike.traveled + 0.75)
			largest_curvature = maxf(largest_curvature, absf(atan2(frame.basis.z.cross(ahead.basis.z).y, frame.basis.z.dot(ahead.basis.z)) / 0.75))
			bike.step_controls(0.35, 0.0, 0.0, 1.0 / 60.0)
			largest_drift = maxf(largest_drift, absf(bike.lateral - 1.6))
			if bike.character.ragdoll_active:
				break
		print("Lane stability ", profile.resource_path, " drift ", largest_drift, " distance ", bike.traveled, " max curvature ", largest_curvature)
		if largest_drift > 0.6 or bike.character.ragdoll_active:
			failures += 1
			push_error("Normal-speed riding must complete the real winding route without sideways drift or an uncommanded fall")
	print("LANE STABILITY: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

