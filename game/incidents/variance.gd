extends "res://game/enemies/incident.gd"
## The existing pursuer with one bounded false-positive event and visible openings.
signal false_positives

## Its moveset: corporate euphemisms, done literally. Each has a name for the banner, a
## line it says as it does it, what it means, and (in the fight) the way out of it. It
## used them on the night shift first; see variance_moves.gd for the fight.
const MOVES: Dictionary = {
	"delayer": {"name": "DELAYERING", "tagline": "removing one layer of management", "hint": "step out from under it", "line": "move_delayer"},
	"decommission": {"name": "DECOMMISSION", "tagline": "service has reached end of life", "hint": "roll through the ring", "line": "move_decommission"},
	"pop": {"name": "DESTRUCTIVE FEEDBACK", "tagline": "cropped to approved dimensions", "hint": "don't stand under the feedback", "line": "move_pop"},
	"expose": {"name": "PAID IN EXPOSURE", "tagline": "unpaid internship, fully compensated", "hint": "look away from the flash", "line": "move_expose"},
	"downsize": {"name": "DOWNSIZING", "tagline": "headcount adjusted", "hint": "get out of the beam", "line": "move_downsize"},
}
const MOVESET: Script = preload("res://game/incidents/variance_moves.gd")
## When in each shield cycle it uses a move (it opens at 4.5).
const MOVE_AT: float = .6

var duplicated: bool = false
var phase_time: float = 0.0
var exposed: bool = false
var marker: Label3D
var seal: MeshInstance3D
var moves: Node3D


func _ready() -> void:
	rig_kind = "variance"
	attack_style = "cataclysm"
	super._ready()
	title = "THE VARIANCE"
	magic_color = Color(1, .22, .28)
	magic_accent = Color(.3, 1, .5)
	magic_words = ["SUCCESS", "FAILED", "NOT FOUND"]
	magic_radius = 2.4
	motto = "Difference detected. Explanation unavailable."
	marker = Label3D.new()
	marker.position.y = 4.1
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.font_size = 44
	marker.modulate = Color(.5, 1, .95)
	add_child(marker)
	label.hide()
	seal = MeshInstance3D.new()
	var shape: BoxMesh = BoxMesh.new()
	shape.size = Vector3(.36, .36, .12)
	seal.mesh = shape
	seal.position.y = 3.5
	seal.rotation.z = PI / 4
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(.4, 1, .9)
	seal.material_override = material
	add_child(seal)
	_crown()
	moves = MOVESET.new(self)
	add_child(moves)


## Three truths orbit its head: the same transaction as each system reports it.
var crown: Node3D


func _crown() -> void:
	crown = Node3D.new()
	crown.position.y = 3.6
	visual.add_child(crown)
	for index in range(3):
		var state: Array = [["SUCCESS", Color(.3, 1, .6)], ["FAILED", Color(1, .3, .18)], ["NOT FOUND", Color(1, .75, .25)]][index]
		var screen: MeshInstance3D = MeshInstance3D.new()
		var panel: BoxMesh = BoxMesh.new()
		panel.size = Vector3(.78, .36, .04)
		screen.mesh = panel
		var glow: StandardMaterial3D = StandardMaterial3D.new()
		glow.albedo_color = Color(.02, .03, .04)
		glow.emission_enabled = true
		glow.emission = state[1] * .35
		screen.material_override = glow
		screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var angle: float = index * TAU / 3
		screen.position = Vector3(cos(angle), 0, sin(angle)) * .95
		screen.rotation.y = -angle - PI * .5
		crown.add_child(screen)
		var word: Label3D = Label3D.new()
		word.text = state[0]
		word.font = preload("res://assets/fonts/barlow_condensed_bold.ttf")
		word.font_size = 64
		word.pixel_size = .004
		word.modulate = state[1]
		word.outline_size = 0
		word.double_sided = true
		word.position.z = .03
		screen.add_child(word)
	# A split body: one half reconciled cyan, the other failed red.
	var cold: StandardMaterial3D = StandardMaterial3D.new()
	cold.albedo_color = Color(.12, .2, .26)
	cold.emission_enabled = true
	cold.emission = Color(.1, .5, .6) * .4
	var hot: StandardMaterial3D = cold.duplicate()
	hot.albedo_color = Color(.26, .1, .12)
	hot.emission = Color(.7, .12, .1) * .4
	for index in range(4):
		visual.get_node("RecordDetails/Slab%d" % index).material_override = cold if index % 2 == 0 else hot


## The killing blow waits for the duel (duel.gd) when there is anyone to show it to.
var spared: bool = false
var dueled: bool = false


func receive_damage(amount: int, source: Vector3) -> bool:
	if not exposed:
		show_blocked()
		return false
	if spared:
		return false
	var story: Node = get_parent().get("presentation")
	if health - amount <= 0 and story != null and (DisplayServer.get_name() != "headless" or story.killcam_in_headless):
		spared = true
		dueled = true
		story.duel(self)
		return true
	var accepted: bool = super.receive_damage(amount, source)
	if health <= 0:
		marker.text = "✓ RECONCILED"
		seal.hide()
	if health > 0 and health <= max_health / 2 and not duplicated:
		duplicated = true
		false_positives.emit()
	return accepted


## The duel's last word: it dies, cut in half.
func final_blow() -> void:
	spared = false
	exposed = true
	super.receive_damage(health + 1000, global_position + Vector3.BACK)


func _physics_process(delta: float) -> void:
	if health <= 0:
		marker.text = "✓  RECONCILED"
		moves.cancel()
		return
	# The opening is combat time: impact must freeze it alongside the actor/weapon.
	if hitstop_left > 0:
		super._physics_process(delta)
		return
	crown.rotation.y += delta * (1.6 if exposed else .5)
	crown.position.y = 3.6 + sin(phase_time * 2.0) * .08
	phase_time = fmod(phase_time + delta, 8.0)
	var was_exposed: bool = exposed
	var before: float = phase_time - delta
	exposed = phase_time >= 4.5
	if exposed != was_exposed:
		_phase_magic()
	if not exposed and before < MOVE_AT and phase_time >= MOVE_AT and not moves.active() and is_instance_valid(target) \
			and target.health > 0 and global_position.distance_to(target.global_position) < 18.0:
		moves.start(target)
	if moves.active() and not exposed:
		# Busy with a move: it stands and does it.
		melee.cancel()
		var saved: CharacterBody3D = target
		target = null
		super._physics_process(delta)
		target = saved
		marker.text = "◆  VERIFIED ORIGINAL\nSHIELDED — EVADE"
	elif exposed:
		melee.cancel()
		var saved_target: CharacterBody3D = target
		target = null
		super._physics_process(delta)
		target = saved_target
		marker.text = "◆  VERIFIED ORIGINAL\nOPEN — STRIKE NOW"
	else:
		super._physics_process(delta)
		marker.text = "◆  VERIFIED ORIGINAL\nSHIELDED — EVADE"
	label.text = "THE VARIANCE  /  %d" % health


## The three verdicts argue in lightning whenever the shield opens or closes.
func _phase_magic() -> void:
	var crown_at: Vector3 = crown.global_position
	for index in range(3):
		var angle: float = TAU * index / 3.0 + phase_time
		var ground: Vector3 = global_position + Vector3(cos(angle), 0, sin(angle)) * 2.6
		ElementFx.bolt(self, crown_at, ground + Vector3.UP * .05, magic_accent if exposed else magic_color, .3, .12)
	ElementFx.flash(self, crown_at, magic_accent if exposed else magic_color, 5.0, 9.0, .35)
	ElementFx.sigil(self, global_position, magic_accent if exposed else magic_color, 3.0, 1.2, -1.0 if exposed else 1.0)


## The close-range cataclysm tears through scenery when its quake actually lands.
func _release_magic() -> void:
	super._release_magic()
	var forward: Vector3 = -visual.global_basis.z
	forward.y = 0
	var front: Vector3 = global_position + forward.normalized() * melee.reach * .6
	moves.smash_props(front, 3.4)
	moves.smash_props(global_position, 2.0)
