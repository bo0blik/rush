extends SceneTree
var failures: int = 0
func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var demo: Node3D = load("res://demo/scenes/forest_demo.tscn").instantiate()
	root.add_child(demo)
	await process_frame
	var bike: DemoMotorcycle = demo.get_node("Motorcycle")
	bike.set_physics_process(false)
	demo.get_node("Traffic").set_physics_process(false)
	for i in range(3):
		for acceleration: float in [0.0, 3.0, -3.0]:
			bike.dynamics.acceleration = acceleration
			bike.dynamics.lean = 0.2
			bike.character._pose_mounted(0.0)
			bike.bike_visual._process(0.2)
			var visual: Sprite3D = bike.character.mounted_visual
			visual._process(0.2)
			var seat: Vector2 = visual.texture.get_meta("seat")
			var seat_world: Vector3 = visual.global_position + visual.global_basis.x * (seat.x - visual.texture.get_width() * 0.5) * visual.pixel_size
			seat_world += visual.global_basis.y * (visual.texture.get_height() * 0.5 - seat.y) * visual.pixel_size
			var expected: Vector3 = bike.character.global_position + bike.character.global_basis.y * bike.profile.seat_anchor.y
			var up: Vector3 = bike.character.global_basis.y.normalized()
			_check(absf((seat_world - expected).dot(up)) < 0.001, "All riding poses must register the pelvis on this motorcycle's seat")
			for hand_key: String in ["hand_left", "hand_right"]:
				var hand: Vector2 = visual.texture.get_meta(hand_key)
				var grip_x: float = absf(hand.x - seat.x) * visual.pixel_size
				var grip_y: float = bike.profile.seat_anchor.y + (seat.y - hand.y) * visual.pixel_size
				_check(absf(grip_x - bike.profile.handlebar_anchor.x) < 0.06 and absf(grip_y - bike.profile.handlebar_anchor.y) < 0.06, "Authored gloves must reach this motorcycle's handlebar without distorting the body")
			var boot: Vector2 = visual.texture.get_meta("boot")
			var boot_world: Vector3 = visual.global_position + visual.global_basis.y * (visual.texture.get_height() * 0.5 - boot.y) * visual.pixel_size
			var half_boot_height: float = float(visual.texture.get_meta("boot_height")) * visual.pixel_size * 0.5
			_check(absf((boot_world - bike.character.global_position).dot(up) - bike.profile.footpeg_anchor.y) < half_boot_height + 0.04, "Footpegs must lie within the boot contact area without image distortion")
			var half_boot: float = float(visual.texture.get_meta("boot_width")) * visual.pixel_size * 0.5
			_check(absf((boot.x - seat.x) * visual.pixel_size - bike.profile.footpeg_anchor.x) < half_boot + 0.04, "Footpegs must lie within the boot contact area without splaying the calves")
			_check(visual.global_basis.y.normalized().dot(bike.bike_visual.global_basis.y.normalized()) > 0.9999, "Seated rider and motorcycle must bank together")
			_check(bike.bike_visual.rear_overlay.visible, "Rear fender must occlude the seated rider's inner legs")
			_check(visual.global_basis.get_scale().is_equal_approx(Vector3.ONE), "Rider art must retain its drawn proportions without anisotropic stretching")
		bike.cycle_bike()
	print("RIDER SEATING: ", "PASS" if failures == 0 else "FAIL", " | three motorcycles, idle/acceleration/braking, pelvis, pegs, roll, rear fender")
	quit(0 if failures == 0 else 1)
