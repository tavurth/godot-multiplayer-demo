extends StaticBody3D

var TREE_COUNT := 20
var GRASS_COUNT := 3000 if Options.high_quality else 500

@onready var scene_scale = $"tree_scene".scale

var available_trees: Array[MultiMeshInstance3D] = []
var available_grass: Array[MultiMeshInstance3D] = []
var available_branches: Array[MultiMeshInstance3D] = []

func _ready():
	rand_from_seed(123456789)

	available_grass = load_objects(GRASS_COUNT, [
		preload("objects/grass_01.res"),
		preload("objects/grass_02.res"),
	])
	available_trees = load_objects(TREE_COUNT, [
		preload("objects/tree_01.res"),
		preload("objects/tree_02.res"),
		preload("objects/tree_03.res"),
	])
	available_branches = load_objects(TREE_COUNT, [
		preload("objects/branches_01.res"),
		preload("objects/branches_02.res"),
		preload("objects/branches_03.res"),
	])

	place_objects()

func load_objects(max_count: int, to_load: Array) -> Array[MultiMeshInstance3D]:
	var to_return: Array[MultiMeshInstance3D] = []

	for mesh in to_load:
		# Load the model into a multimesh
		var multimesh = MultiMesh.new()
		multimesh.set_mesh(mesh)
		multimesh.set_transform_format(MultiMesh.TRANSFORM_3D)

		# Setup the multimesh instance
		var multimeshinstance = MultiMeshInstance3D.new()
		multimeshinstance.set_multimesh(multimesh)

		# Setup the maximum count and store the current count in meta
		multimesh.set_instance_count(max_count)
		multimesh.set_meta("count", 0)

		self.add_child(multimeshinstance)
		to_return.append(multimeshinstance)

	return to_return


func rand_index(array: Array[MultiMeshInstance3D]) -> int:
	return randi() % len(array)


func random_from(array: Array[MultiMeshInstance3D]) -> MultiMeshInstance3D:
	return array[rand_index(array)]


func scatter_item(instances: MultiMeshInstance3D, new_transform: Transform3D) -> void:
	var count = instances.multimesh.get_meta("count")

	if count > instances.multimesh.instance_count - 1:
		return

	instances.multimesh.set_meta("count", count + 1)
	instances.multimesh.set_instance_transform(
		count,
		new_transform
	)


func maybe_place_tree(idx: int, vertex: Vector3, _normal: Vector3) -> void:
	if idx % 20 != 0:
		return

	if vertex.y < 0:
		return

	var r_index = rand_index(available_trees)

	var to_transform = Transform3D\
		.IDENTITY\
		.translated(vertex - Vector3(0, 2, 0))\
		.rotated_local(Vector3(0, 1, 0), randf() * PI * 2)

	scatter_item(available_trees[r_index], to_transform)
	scatter_item(available_branches[r_index], to_transform)

	var collision = preload("objects/tree_collision.tscn").instantiate()
	collision.set_position(vertex)
	self.add_child(collision)


func maybe_place_grass(_idx: int, vertex: Vector3, normal: Vector3) -> void:
	if vertex.y < 0:
		return

	scatter_item(
		random_from(available_grass), 
		Transform3D\
			.IDENTITY\
			.rotated(Vector3(1, 0, 0), -PI / 2)\
			.translated(vertex - Vector3(0, 1, 0))\
			.rotated_local(Vector3(0, 0, 1), randf() * PI * 2)\
	)


func do_test_vertex(idx: int, vertex: Vector3, normal: Vector3) -> void:
	maybe_place_tree(idx, vertex, normal)
	maybe_place_grass(idx, vertex, normal)


func place_objects() -> void:
	for_each_vertex($"tree_scene/Ground", do_test_vertex)


func for_each_vertex(node: MeshInstance3D, to_call: Callable) -> void:
	var count: int
	var mdt := MeshDataTool.new()

	for surface_idx in node.mesh.get_surface_count():
		mdt.create_from_surface(node.mesh, surface_idx)
		count = mdt.get_vertex_count()

		for vertex_idx in range(count):
			# Call our input function and set the result
			to_call.call(
				vertex_idx,
				mdt.get_vertex(vertex_idx) * scene_scale,
				mdt.get_vertex_tangent(vertex_idx).normal
			)
