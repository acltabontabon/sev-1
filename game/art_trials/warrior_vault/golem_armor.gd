extends Node3D
## Original low-poly armor additions for the CC0 Warrior; presentation only.
var body: Node3D
var skeleton: Skeleton3D
var steel: StandardMaterial3D
var edge: StandardMaterial3D
var axe: Node3D
var base_scale: Vector3
var enabled: bool = true
var head_index: int = -1


func build(source_body: Node3D, source_axe: Node3D) -> void:
	body = source_body
	axe = source_axe
	skeleton = body.find_child("Skeleton3D", true, false) as Skeleton3D
	base_scale = body.scale
	head_index = skeleton.find_bone("head")
	process_priority = 20
	steel = _material(Color(.13, .17, .23), .8, .15)
	edge = _material(Color(.25, .30, .37), .72, .2)
	for side: String in ["l", "r"]:
		var sign_: float = 1.0 if side == "l" else -1.0
		_plate("upperarm." + side, Vector3(sign_ * .22, -.15, 0), Vector3(.76, .48, .60), steel)
		_plate("upperarm." + side, Vector3(sign_ * .22, .06, 0), Vector3(.80, .12, .64), edge)
		_plate("lowerarm." + side, Vector3(0, -.16, 0), Vector3(.34, .38, .36), steel)
		_plate("foot." + side, Vector3(0, .10, .04), Vector3(.38, .27, .44), steel)
	_plate("spine", Vector3(0, .20, .28), Vector3(.90, .48, .42), steel)
	_plate("spine", Vector3(0, -.05, .14), Vector3(.68, .11, .36), edge)
	set_enabled(true)


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _plate(bone: String, offset: Vector3, size: Vector3, material: Material) -> void:
	var index: int = skeleton.find_bone(bone)
	assert(index >= 0, "Golem armor attachment missing: " + bone)
	var joint: BoneAttachment3D = BoneAttachment3D.new()
	joint.bone_name = bone
	skeleton.add_child(joint)
	var pose: Transform3D = skeleton.get_bone_global_pose(index)
	var model_to_skeleton: Transform3D = skeleton.global_transform.affine_inverse() * body.global_transform
	var center: Vector3 = pose.origin + model_to_skeleton.basis * offset
	var plate: MeshInstance3D = MeshInstance3D.new()
	plate.mesh = _beveled_box(size)
	plate.material_override = material
	plate.transform = pose.affine_inverse() * Transform3D(model_to_skeleton.basis, center)
	joint.add_child(plate)
	# Keep the owning attachments with this component for visibility toggling.
	joint.set_meta("golem_armor", true)


## Chamfered cuboid: flat polygon panels, deliberately matching the source armor.
func _beveled_box(size: Vector3) -> ArrayMesh:
	var bevel: float = minf(size.x, minf(size.y, size.z)) * .18
	var half: Vector3 = size * .5
	var vertices: Array[Vector3] = []
	# Bevel the four corners in X/Z and taper the upper/lower rim.
	var ring: Array[Vector2] = [Vector2(-half.x + bevel, -half.z), Vector2(half.x - bevel, -half.z), Vector2(half.x, -half.z + bevel), Vector2(half.x, half.z - bevel), Vector2(half.x - bevel, half.z), Vector2(-half.x + bevel, half.z), Vector2(-half.x, half.z - bevel), Vector2(-half.x, -half.z + bevel)]
	for y: float in [-half.y, -half.y + bevel, half.y - bevel, half.y]:
		var inset: float = .84 if absf(y) == half.y else 1.0
		for point: Vector2 in ring:
			vertices.append(Vector3(point.x * inset, y, point.y * inset))
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer: int in range(3):
		for index: int in range(8):
			var next: int = (index + 1) % 8
			_triangle(surface, vertices[layer * 8 + index], vertices[(layer + 1) * 8 + index], vertices[(layer + 1) * 8 + next])
			_triangle(surface, vertices[layer * 8 + index], vertices[(layer + 1) * 8 + next], vertices[layer * 8 + next])
	for index: int in range(1, 7):
		_triangle(surface, vertices[0], vertices[index], vertices[index + 1])
		_triangle(surface, vertices[24], vertices[24 + index + 1], vertices[24 + index])
	surface.generate_normals()
	return surface.commit()


func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for vertex: Vector3 in [a, c, b]:
		surface.add_vertex(vertex)


func set_enabled(value: bool) -> void:
	enabled = value
	body.scale = base_scale * (Vector3(1.27, 1.08, 1.12) if enabled else Vector3.ONE)
	if axe != null:
		axe.scale = Vector3.ONE * (1.25 if enabled else 1.0)
	for child: Node in skeleton.get_children():
		if child is BoneAttachment3D and child.has_meta("golem_armor"):
			(child as Node3D).visible = enabled


func _process(_delta: float) -> void:
	if skeleton != null and head_index >= 0:
		# After the supplied AnimationPlayer: smaller skull makes the armored body read
		# as a heavy construct. The additional root height keeps it boss-sized.
		skeleton.set_bone_pose_scale(head_index, Vector3(.80, .84, .84) if enabled else Vector3.ONE)
