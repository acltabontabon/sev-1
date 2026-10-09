extends Node3D
## Local deterministic motion and state indicators, independent of damage rules.
var clock: float = 0.0
var actor: CharacterBody3D
var status_material: StandardMaterial3D
@onready var details: Node3D = $RecordDetails


func _ready() -> void:
	actor = get_parent() as CharacterBody3D
	process_physics_priority = 10
	status_material = $Eye.mesh.material.duplicate() as StandardMaterial3D
	$Eye.material_override = status_material
	for i in range(4):
		details.get_node("Slab%d/Row" % i).material_override = status_material


func reset_pose() -> void:
	clock = 0
	position = Vector3.ZERO
	details.rotation = Vector3.ZERO
	details.position = Vector3.ZERO
	$Body.rotation = Vector3.ZERO
	$LeftArm.rotation = Vector3.ZERO
	$RightArm.rotation = Vector3.ZERO
	_pose(0)


func defeat() -> void:
	position.y = -.25
	details.rotation.z = -.35
	details.position.y = -.35
	for i in range(4):
		var slab: Node3D = details.get_node("Slab%d" % i)
		slab.position.y = .45 + i * .13
		slab.rotation.z = (i - 1.5) * .12
	$LeftArm.rotation.z = -.5
	$RightArm.rotation.z = .7
	status_material.emission_energy_multiplier = 0
	status_material.albedo_color = Color(.13, .16, .16)


func _physics_process(delta: float) -> void:
	if actor.health <= 0 or actor.hitstop_left > 0:
		return
	clock += delta
	_pose(delta)


func _pose(delta: float) -> void:
	var pursuit: bool = actor.state == actor.State.APPROACH
	var melee: Node3D = actor.melee
	var arm: float = sin(clock * 5) * .12 if pursuit else .06
	if melee.attacking:
		if melee.elapsed < melee.windup:
			arm = lerpf(.06, 1.05, smoothstep(0, 1, melee.elapsed / melee.windup))
		elif melee.is_active():
			arm = lerpf(1.05, -1.25, (melee.elapsed - melee.windup) / melee.active_time)
		else:
			arm = lerpf(-1.25, .06, smoothstep(0, 1, (melee.elapsed - melee.windup - melee.active_time) / melee.recovery))
	$LeftArm.rotation.x = arm
	$RightArm.rotation.x = arm * .9
	# Move the centered mesh around a shoulder instead of its own center.
	$LeftArm.position = Vector3(-.53, 1.53, 0) + Basis(Vector3.RIGHT, arm) * Vector3(0, -.4, 0)
	$RightArm.position = Vector3(.53, 1.53, 0) + Basis(Vector3.RIGHT, arm * .9) * Vector3(0, -.4, 0)
	for i in range(4):
		var slab: Node3D = details.get_node("Slab%d" % i)
		var sign_: float = -1 if i % 2 else 1
		slab.position.y = .85 + i * .245
		slab.position.x = sign_ * (.07 + sin(clock * 1.8 + i) * .018)
		slab.rotation.z = sin(clock * 2.0 + i) * .025
		if actor.flash_left > 0:
			slab.material_override = actor.flash_material
		else:
			slab.material_override = null
	var color: Color = Color(.65, .25, .08)
	if actor.state == actor.State.TELEGRAPH or actor.state == actor.State.ATTACK:
		color = Color(1, .45, .08)
	elif actor.state == actor.State.REACT:
		color = Color(.8, .9, 1)
	elif actor.state == actor.State.RECOVER:
		color = Color(.25, .45, .5)
	status_material.albedo_color = color
	status_material.emission = color
	status_material.emission_energy_multiplier = 1.1 if melee.attacking else .4
	# The short recoil is separate from the committed attack arm motion.
	details.rotation.x = move_toward(details.rotation.x, -.15 if actor.stagger_left > 0 else 0.0, delta * 4)
