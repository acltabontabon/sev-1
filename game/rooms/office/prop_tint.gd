extends Node
## Brings the bright CC0 kit props into the after-hours palette: darker, less saturated,
## less glossy. Materials are duplicated once per source and shared between props.

@export var value: float = .5
@export var saturation: float = .55


func _ready() -> void:
	var tinted: Dictionary = {}
	for prop: Node in get_parent().get_children():
		if not prop.scene_file_path.contains("kenney_furniture"):
			continue
		for mesh: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var source: Material = mesh.get_active_material(surface)
				if not source is BaseMaterial3D:
					continue
				if not tinted.has(source):
					var material: BaseMaterial3D = source.duplicate()
					var color: Color = material.albedo_color
					color.s *= saturation
					color.v *= value
					material.albedo_color = color
					material.roughness = maxf(material.roughness, .6)
					tinted[source] = material
				mesh.set_surface_override_material(surface, tinted[source])
