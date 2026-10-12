extends Node3D
## A fixed pool recycles outside the camera. Swept relative motion prevents missed hits.

const Vehicle = preload("res://demo/scripts/traffic_vehicle.gd")
const SEDAN = preload("res://demo/scenes/traffic_sedan.tscn")
const TRUCK = preload("res://demo/scenes/traffic_truck.tscn")
signal collision(relative_speed: float)

var track: DemoTrack
var rider: DemoMotorcycle
var camera: Camera3D
var vehicles: Array[Vehicle] = []
var previous_player_distance: float = 0.0
var previous_player_lateral: float = 0.0


func setup(road: DemoTrack, player: DemoMotorcycle, view_camera: Camera3D) -> void:
	track = road
	rider = player
	camera = view_camera
	for i in range(8):
		var scene: PackedScene = TRUCK if i % 3 == 1 else SEDAN
		var vehicle: Vehicle = scene.instantiate()
		vehicle.name = "Vehicle%d" % i
		add_child(vehicle)
		vehicles.append(vehicle)
	reset()


func reset() -> void:
	previous_player_distance = rider.start_distance + rider.traveled
	previous_player_lateral = rider.lateral
	for i in range(vehicles.size()):
		var vehicle: Vehicle = vehicles[i]
		vehicle.direction = 1.0 if i < 4 else -1.0
		vehicle.lateral = track.road_width * 0.24 * vehicle.direction
		vehicle.speed = (12.0 + i * 1.0) if i < 4 else (18.0 + (i - 4) * 1.5)
		vehicle.cruise_speed = vehicle.speed
		vehicle.distance = previous_player_distance + (42.0 + i * 78.0 if i < 4 else 95.0 + (i - 4) * 90.0)
		vehicle.collision_cooldown = 0.0
		vehicle.place(track, camera)
		vehicle.reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if rider != null:
		step_traffic(delta)


func signed_gap(distance: float, player_distance: float) -> float:
	return fposmod(distance - player_distance + track.length * 0.5, track.length) - track.length * 0.5

func setup_crash_test() -> void:
	reset()
	var target: Vehicle = vehicles[0]
	target.distance = rider.start_distance + rider.traveled + 9.0
	target.lateral = rider.lateral
	target.speed = 0.0
	target.cruise_speed = 0.0
	target.place(track, camera)


func step_traffic(delta: float) -> void:
	var player_distance: float = rider.start_distance + rider.traveled
	var player_step: float = player_distance - previous_player_distance
	for vehicle in vehicles:
		var old_gap: float = signed_gap(vehicle.distance, previous_player_distance)
		var desired_speed: float = vehicle.cruise_speed
		for other in vehicles:
			if other == vehicle or other.direction != vehicle.direction:
				continue
			var ahead_gap: float = signed_gap(other.distance, vehicle.distance) * vehicle.direction
			var clearance: float = (vehicle.body_length + other.body_length) * 0.5 + 8.0
			if ahead_gap > 0.0 and ahead_gap < clearance + 24.0:
				desired_speed = minf(desired_speed, maxf(0.0, other.speed + (ahead_gap - clearance) * 0.5))
		vehicle.speed = move_toward(vehicle.speed, desired_speed, 4.0 * delta)
		vehicle.distance += vehicle.speed * vehicle.direction * delta
		vehicle.collision_cooldown = maxf(0.0, vehicle.collision_cooldown - delta)
		var new_gap: float = old_gap + vehicle.speed * vehicle.direction * delta - player_step
		var bike_length: float = rider.profile.wheelbase_m + rider.profile.wheel_radius_m * 2.0
		var cosine: float = absf(cos(rider.dynamics.heading))
		var sine: float = absf(sin(rider.dynamics.heading))
		var half_length: float = vehicle.body_length * 0.5 + (bike_length * cosine + rider.profile.body_width_m * sine) * 0.5
		var half_width: float = vehicle.body_width * 0.5 + (rider.profile.body_width_m * cosine + bike_length * sine) * 0.5
		if rider.impact_time <= 0.0 and vehicle.collision_cooldown <= 0.0 and _swept_overlap(old_gap, new_gap,
			previous_player_lateral - vehicle.lateral, rider.lateral - vehicle.lateral, half_length, half_width):
			var relative_speed: float = absf(rider.speed * cos(rider.dynamics.heading) - vehicle.speed * vehicle.direction)
			if relative_speed > 1.0:
				var away: float = -1.0 if rider.lateral < vehicle.lateral else 1.0
				var normal: Vector3 = (rider.global_position - vehicle.global_position).normalized()
				normal.y = 0.0
				rider.hit_traffic(relative_speed, away, vehicle.lateral, half_width, normal.normalized())
				vehicle.collision_cooldown = 1.5
				collision.emit(relative_speed)
		var gap: float = signed_gap(vehicle.distance, player_distance)
		if gap < -45.0 or gap > 430.0:
			_recycle(vehicle, player_distance)
		vehicle.place(track, camera, delta)
	previous_player_distance = player_distance
	previous_player_lateral = rider.lateral


func _swept_overlap(old_gap: float, new_gap: float, old_side: float, new_side: float,
		half_length: float, half_width: float) -> bool:
	var enter: float = 0.0
	var leave: float = 1.0
	for axis in range(2):
		var start: float = old_gap if axis == 0 else old_side
		var finish: float = new_gap if axis == 0 else new_side
		var extent: float = half_length if axis == 0 else half_width
		var movement: float = finish - start
		if absf(movement) < 0.00001:
			if absf(start) > extent:
				return false
		else:
			var a: float = (-extent - start) / movement
			var b: float = (extent - start) / movement
			enter = maxf(enter, minf(a, b))
			leave = minf(leave, maxf(a, b))
	return enter <= leave


func _recycle(vehicle: Vehicle, player_distance: float) -> void:
	# Four well-separated slots guarantee room among the other three cars in this lane.
	var spawn_gap: float = 190.0
	for candidate: float in [190.0, 270.0, 350.0, 430.0]:
		var clear: bool = true
		for other in vehicles:
			if other != vehicle and other.direction == vehicle.direction and absf(signed_gap(other.distance, player_distance) - candidate) < 35.0:
				clear = false
		if clear:
			spawn_gap = candidate
			break
	vehicle.distance = player_distance + spawn_gap
	vehicle.collision_cooldown = 0.0
	vehicle.place(track, camera)
	vehicle.reset_physics_interpolation()
