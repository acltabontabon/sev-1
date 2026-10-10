extends Node3D
## Meeting-wing ambience: calendar invites drift down the corridor like weather.
## Visual only; no collision, no gameplay state, deterministic placement. They drift up
## under the ceiling, out of the third-person camera's line, and step aside (hide) when
## the camera comes close so they never block the view.
const HEIGHT: float = 3.05

const INVITES: Array[String] = ["Quick Sync", "Sync about the Sync", "Alignment (re-aligned)", "Pre-mortem", "Retro of the Retro", "Optional (mandatory)", "Brainstorm: fewer meetings", "Status update update"]
var cards: Array[Node3D] = []
var clock: float = 0.0


func _ready() -> void:
	var paper: StandardMaterial3D = StandardMaterial3D.new()
	paper.albedo_color = Color(.62, .65, .7)
	paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	var stripe: StandardMaterial3D = StandardMaterial3D.new()
	stripe.albedo_color = Color(.36, .55, 1)
	stripe.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stripe.cull_mode = BaseMaterial3D.CULL_DISABLED
	for index in range(INVITES.size()):
		var card: Node3D = Node3D.new()
		card.position = Vector3(sin(index * 2.3) * .9, HEIGHT + fmod(index * .37, .3), -13.0 + index * 3.6)
		card.scale = Vector3.ONE * .72
		add_child(card)
		var face: MeshInstance3D = MeshInstance3D.new()
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(1.0, .56)
		face.mesh = quad
		face.material_override = paper
		face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		card.add_child(face)
		var header: MeshInstance3D = MeshInstance3D.new()
		var bar: QuadMesh = QuadMesh.new()
		bar.size = Vector2(1.0, .12)
		header.mesh = bar
		header.material_override = stripe
		header.position = Vector3(0, .22, .002)
		card.add_child(header)
		var label: Label3D = Label3D.new()
		label.text = INVITES[index] + "\nAccept · Decline · Maybe"
		# Sized so the longest title ("Brainstorm: fewer meetings") stays on its card.
		label.pixel_size = .0017
		label.font_size = 40
		label.modulate = Color(.12, .15, .22)
		label.outline_size = 0
		label.position = Vector3(0, -.04, .004)
		label.double_sided = false
		card.add_child(label)
		var back: Label3D = label.duplicate()
		back.position.z = -.004
		back.rotation.y = PI
		card.add_child(back)
		cards.append(card)


func _process(delta: float) -> void:
	clock += delta
	var camera: Camera3D = get_viewport().get_camera_3d()
	for index in range(cards.size()):
		var card: Node3D = cards[index]
		card.position.y = HEIGHT + fmod(index * .37, .3) + sin(clock * .6 + index) * .05
		card.visible = camera == null or camera.global_position.distance_to(card.global_position) > 3.6
		# Cards turn slowly to meet people walking either way down the corridor.
		card.rotation = Vector3(sin(clock * .4 + index) * .08, (PI if index % 2 else 0.0) + sin(clock * .3 + index * 1.7) * .6, sin(clock * .5 + index) * .05)
