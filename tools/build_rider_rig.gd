extends SceneTree
## Save an editable physical skeleton using the installed Auto Ragdoll generator.
const Generator = preload("res://addons/ragdoll_generator/ragdoll_generator.gd")

func _initialize() -> void:
	var root := Node3D.new()
	root.name = "Character"
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	root.add_child(skeleton)
	skeleton.owner = root
	var bones: Array = [
		["hips", -1, Vector3(0, 0.9, 0)],
		["spine", 0, Vector3(0, 0.12, 0)],
		["spine1", 1, Vector3(0, 0.12, 0)],
		["spine2", 2, Vector3(0, 0.15, 0)],
		["head", 3, Vector3(0, 0.24, 0)],
		["left_shoulder", 3, Vector3(-0.16, 0.06, 0)],
		["left_upper_arm", 5, Vector3(-0.08, 0, 0)],
		["left_forearm", 6, Vector3(-0.28, 0, 0)],
		["left_hand", 7, Vector3(-0.27, 0, 0)],
		["right_shoulder", 3, Vector3(0.16, 0.06, 0)],
		["right_upper_arm", 9, Vector3(0.08, 0, 0)],
		["right_forearm", 10, Vector3(0.28, 0, 0)],
		["right_hand", 11, Vector3(0.27, 0, 0)],
		["left_upper_leg", 0, Vector3(-0.13, -0.02, 0)],
		["left_lower_leg", 13, Vector3(0, -0.4, 0)],
		["left_foot", 14, Vector3(0, -0.4, 0)],
		["right_upper_leg", 0, Vector3(0.13, -0.02, 0)],
		["right_lower_leg", 16, Vector3(0, -0.4, 0)],
		["right_foot", 17, Vector3(0, -0.4, 0)]]
	for data: Array in bones:
		skeleton.add_bone(data[0])
		var index: int = skeleton.get_bone_count() - 1
		skeleton.set_bone_parent(index, data[1])
		skeleton.set_bone_rest(index, Transform3D(Basis.IDENTITY, data[2]))
		skeleton.set_bone_pose(index, Transform3D(Basis.IDENTITY, data[2]))
	get_root().add_child(root)
	Generator.generate_ragdoll(skeleton, {"total_mass": 80.0})
	var simulator: PhysicalBoneSimulator3D = skeleton.get_node("PhysicalBoneSimulator3D")
	simulator.active = false
	for bone: PhysicalBone3D in simulator.get_children():
		bone.collision_layer = 4
		bone.collision_mask = 3
		bone.linear_damp = 0.12
		bone.angular_damp = 0.8
		bone.friction = 0.65
	var scene := PackedScene.new()
	assert(scene.pack(root) == OK)
	assert(ResourceSaver.save(scene, "res://demo/scenes/rider_physical_rig.tscn") == OK)
	print("RIDER RIG: saved ", simulator.get_child_count(), " physical bones")
	quit()
