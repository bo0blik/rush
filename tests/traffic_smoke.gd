extends SceneTree

var failures: int = 0
var collision_count: int = 0


func _initialize() -> void:
	Engine.max_fps = 120
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _hit(_speed: float) -> void:
	collision_count += 1


func _run() -> void:
	var demo: Node3D = load("res://demo/scenes/forest_demo.tscn").instantiate()
	root.add_child(demo)
	await process_frame
	var rider = demo.get_node("Motorcycle")
	var traffic = demo.get_node("Traffic")
	var camera = demo.get_node("ChaseCamera")
	var track = demo.get_node("Track")
	rider.set_physics_process(false)
	traffic.set_physics_process(false)
	camera.set_physics_process(false)
	traffic.collision.connect(_hit)
	_check(traffic.vehicles.size() == 8, "Traffic must have eight pooled vehicles")
	var player_distance: float = rider.start_distance
	var following = traffic.vehicles[0]
	var oncoming = traffic.vehicles[4]
	var old_following: float = following.distance
	var old_oncoming: float = oncoming.distance
	traffic.step_traffic(0.1)
	_check(following.distance > old_following and oncoming.distance < old_oncoming,
		"Traffic must move in both directions")
	_check(following.current_view < 3 and oncoming.current_view >= 3,
		"Ahead cars must show rear and oncoming front sprites")
	_check(following.lateral > 0.0 and oncoming.lateral < 0.0, "Traffic must use opposite road lanes")
	# Passing an adjacent car must not collide.
	rider.reset()
	traffic.reset()
	rider.speed = 30.0
	rider.lateral = -2.0
	traffic.previous_player_lateral = rider.lateral
	following.distance = player_distance + 2.0
	rider.traveled = 6.0
	traffic.step_traffic(0.2)
	_check(collision_count == 0 and is_equal_approx(rider.speed, 30.0), "An overtake in the other lane must be safe")
	# Swept collision detects a fast head-on pass even with no end-frame overlap.
	rider.reset()
	traffic.reset()
	rider.speed = 30.0
	rider.lateral = oncoming.lateral
	traffic.previous_player_lateral = rider.lateral
	oncoming.distance = player_distance + 12.0
	rider.traveled = 20.0
	traffic.step_traffic(0.5)
	_check(collision_count == 1 and rider.speed < 10.0 and rider.impact_time > 0.0,
		"A swept head-on collision must slow and stun the rider")
	_check(absf(rider.lateral - oncoming.lateral) > oncoming.body_width * 0.5 + 0.32,
		"A collision must separate the rider from the car")
	_check(demo.get_node("HUD/Interface").collision_time > 0.0, "A collision must notify HUD")
	traffic.step_traffic(0.01)
	_check(collision_count == 1, "Contact cooldown must prevent repeated impacts")
	# Rear-end contact and closed-track seam use the same collision rules.
	rider.reset()
	traffic.reset()
	rider.speed = 30.0
	rider.lateral = following.lateral
	traffic.previous_player_lateral = rider.lateral
	following.distance = player_distance + 4.0
	rider.traveled = 5.0
	traffic.step_traffic(0.1)
	_check(collision_count == 2 and rider.speed < 20.0, "Rear-end contact must slow the rider")
	rider.reset()
	rider.traveled = track.length - rider.start_distance - 2.0
	traffic.reset()
	rider.speed = 30.0
	rider.lateral = following.lateral
	traffic.previous_player_lateral = rider.lateral
	following.distance = 1.0
	rider.traveled += 5.0
	traffic.step_traffic(0.1)
	_check(collision_count == 3, "Collision must work across the closed-track seam")
	# Recycle a car behind the player without allocating a new node.
	rider.reset()
	traffic.reset()
	following.distance = player_distance - 60.0
	var original_id: int = following.get_instance_id()
	traffic.step_traffic(0.1)
	var gap: float = traffic.signed_gap(following.distance, player_distance)
	_check(gap >= 189.0 and gap <= 431.0 and following.get_instance_id() == original_id,
		"A passed car must recycle ahead using the same node")
	# Continuous recycling must not send cars beyond the spawn band.
	for i in range(2000):
		traffic.step_traffic(0.1)
		for vehicle in traffic.vehicles:
			var current_gap: float = traffic.signed_gap(vehicle.distance, player_distance)
			_check(current_gap >= -45.01 and current_gap <= 430.01, "Pool must stay inside its recycling band")
			for other in traffic.vehicles:
				if other != vehicle and other.direction == vehicle.direction:
					_check(absf(traffic.signed_gap(other.distance, vehicle.distance)) >
						(vehicle.body_length + other.body_length) * 0.5,
						"Cars in the same lane must not overlap")
	paused = true
	_check(not traffic.can_process(), "Pause must stop traffic")
	paused = false
	rider.reset()
	traffic.reset()
	demo.get_node("HUD/Interface").clear_collision()
	_check(is_zero_approx(rider.impact_time) and is_equal_approx(following.distance, player_distance + 42.0),
		"Reset must restore rider and traffic positions")
	print("TRAFFIC SMOKE: %s | lanes, views, overtake, swept collisions, seam, recycling, pause, reset" %
		("PASS" if failures == 0 else "FAIL (%d)" % failures))
	demo.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit(0 if failures == 0 else 1)
