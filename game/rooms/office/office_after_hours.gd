extends Node3D
## Camera-only blockers: large visible architecture without collision (door headers,
## ceiling beams, ducts, cable trays, whiteboards) gets a box on the Camera layer, so the
## gameplay camera stops in front of it instead of looking through it from the inside.
## Bodies, enemies, navigation and sight lines (layer 1) never see these boxes.

const CAMERA_LAYER: int = 1 << 8
## Smaller props (plants, lamps, monitors) stay see-through: bumping the lens on every
## pot plant would jerk the view around more than the clipping it prevents.
@export var min_blocker_size: float = 1.4


func _ready() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = node
		if mesh_node.mesh == null or not mesh_node.is_visible_in_tree() or _collides(mesh_node):
			continue
		var box: AABB = mesh_node.mesh.get_aabb()
		var size: Vector3 = box.size * mesh_node.global_basis.get_scale()
		if maxf(size.x, maxf(size.y, size.z)) < min_blocker_size:
			continue
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "CameraBlocker"
		body.collision_layer = CAMERA_LAYER
		body.collision_mask = 0
		var shape: CollisionShape3D = CollisionShape3D.new()
		var extents: BoxShape3D = BoxShape3D.new()
		extents.size = box.size
		shape.shape = extents
		shape.position = box.get_center()
		body.add_child(shape)
		mesh_node.add_child(body)


## True when the mesh already belongs to something solid to the world layer.
func _collides(mesh_node: Node) -> bool:
	var at: Node = mesh_node
	while at != null and at != self:
		if at is CollisionObject3D and (at.collision_layer & 1) != 0:
			return true
		for child in at.get_children():
			if child is CollisionObject3D and (child.collision_layer & 1) != 0:
				return true
		at = at.get_parent()
	return false
