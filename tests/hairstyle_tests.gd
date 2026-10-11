extends "res://tests/incident_tests.gd"
## Every overtime employee wears their own haircut, on their own animated head: it covers
## the crown, follows the head through animation, shrinks away with a sliced torso, and is
## not duplicated by a retry.

const HAIR = preload("res://game/incidents/hairstyles.gd")
const DIALOGUES = preload("res://game/incidents/dialogues.gd")


func hairstyles(body: Node3D) -> Array[Node]:
	return body.find_children("Hairstyle", "BoneAttachment3D", true, false)


func stock_hair(body: Node3D) -> bool:
	for mesh: Node in body.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = mesh as MeshInstance3D
		if instance.skin == null:
			continue
		for surface in instance.mesh.get_surface_count():
			var material: Material = instance.mesh.surface_get_material(surface)
			if material != null and material.resource_name == "Hair":
				return true
	return false


func head_at(body: Node3D) -> Vector3:
	var skeleton: Skeleton3D = body.find_child("Skeleton3D", true, false)
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin


func world_bounds(hair: MeshInstance3D) -> AABB:
	return hair.global_transform * hair.mesh.get_aabb()


## Check the actual triangle surface, not its bounding box: the former thin buzz cap
## exposed skin between vertices around the temples and crown in rendered portraits.
func check_scalp_coverage() -> void:
	var faces: PackedVector3Array = HAIR.mesh("buzz_beard").get_faces()
	var exposed: int = 0
	for polar in [8.0, 24.0, 40.0, 53.0, 76.0]:
		for azimuth in range(0, 360, 15):
			# Forehead is intentionally exposed below the front hairline.
			if polar > 55 and (azimuth < 65 or azimuth > 295):
				continue
			var skin: Vector3 = HAIR._on(azimuth + 3.0, polar, .004)
			var ray: Vector3 = (skin - HAIR.SCALP).normalized() * .2
			var covered: bool = false
			for triangle in range(0, faces.size(), 3):
				if Geometry3D.segment_intersects_triangle(skin, skin + ray,
						faces[triangle], faces[triangle + 1], faces[triangle + 2]) != null:
					covered = true
					break
			if not covered:
				exposed += 1
	check(exposed == 0, "buzz cut covers sampled scalp between mesh vertices (%d exposed points)" % exposed)


func _run() -> void:
	check_scalp_coverage()
	for style in HAIR.STYLES:
		var bounds: AABB = HAIR.mesh(style).get_aabb()
		check(bounds.size.x > (.2 if style == "mohawk" else .5) and bounds.size.length() < 3.5 and AABB(Vector3(-1.3, -1.3, -1.3), Vector3.ONE * 2.6).encloses(bounds),
			"the %s cut is built around the head: %s" % [style, bounds])
	var crew_styles: Array = []
	for kind: String in ["record", "blocker", "invite", "scope"]:
		for identity: Dictionary in DIALOGUES.crew(kind):
			check(identity.get("hair", "") in HAIR.STYLES, "%s, planted employee, has a real haircut" % identity.name)
			crew_styles.append(identity.get("hair", ""))
	scene = load("res://game/incidents/missing_transaction.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	incident = scene.get_node("Incident")
	incident.presentation.skip()
	incident._cleanup()
	incident._enter(incident.Stage.INVESTIGATION)
	paused = false
	await frames(2)
	var crew: Node3D = incident.coworkers
	crew.set_process(false)
	var worn: Dictionary = {}
	for person: Dictionary in crew.people:
		var body: Node3D = person.body
		var style: String = person.entry.get("hair", "")
		if style == "":
			check(hairstyles(body).is_empty() and stock_hair(body), "%s keeps the pack's own hair" % person.entry.name)
			continue
		check(not worn.has(style), "%s's %s cut is nobody else's on the floor" % [person.entry.name, style])
		worn[style] = true
		check(hairstyles(body).size() == 1 and not stock_hair(body), "%s wears one fitted %s cut instead of the stock hair" % [person.entry.name, style])
		var hair: MeshInstance3D = hairstyles(body)[0].find_child("Hair", true, false)
		var size: float = body.global_basis.get_scale().x
		var bounds: AABB = world_bounds(hair)
		if style == "mullet":
			check(bounds.position.y < head_at(body).y - .2 * size, "Facilities' mullet hangs below the hard hat")
		elif style == "mohawk":
			check(bounds.end.y > head_at(body).y + 1.1 * size and hair.mesh.get_aabb().size.x < .35, "Microwave wears a tall narrow mohawk with exposed sides")
		else:
			check(bounds.end.y > head_at(body).y + .85 * size, "%s's hair reaches above the crown" % person.entry.name)
	check(worn.size() >= 11, "eleven coworkers wear eleven different haircuts")
	# Through animation, the cut stays on the head.
	var manager: Dictionary = crew.person("Manager")
	check(manager.body.scene_file_path.ends_with("suit_female.fbx"), "Morgan retains main's female office body after the rebase")
	var cut: Node3D = hairstyles(manager.body)[0]
	manager.animator.play("CharacterArmature|Walk", 0.0)
	manager.animator.seek(.1, true)
	manager.animator.pause()
	await frames(2)
	var head_before: Vector3 = head_at(manager.body)
	var offset_before: Vector3 = cut.global_position - head_before
	manager.animator.play("ual/talking", 0.0)
	manager.animator.seek(1.2, true)
	manager.animator.pause()
	await frames(2)
	var head_after: Vector3 = head_at(manager.body)
	check(head_before.distance_to(head_after) > .005 and (cut.global_position - head_after).distance_to(offset_before) < .02,
		"the manager's side part moves with the animated head")
	# Planted employees wear theirs under the corruption overlay.
	var host: Node3D = preload("res://game/enemies/employee_host.gd").create("record", 0)
	incident.add_child(host)
	host.global_position = player.global_position + Vector3(6, 0, 6)
	await frames(2)
	check(hairstyles(host.body).size() == 1 and not stock_hair(host.body), "%s keeps their %s cut as a planted employee" % [host.identity.name, host.identity.hair])
	var overlaid: MeshInstance3D = hairstyles(host.body)[0].find_child("Hair", true, false)
	check(host.meshes.has(overlaid) and overlaid.get_surface_override_material(0).next_pass != null,
		"the planted employee's hair glows with the rest of the corruption")
	host.queue_free()
	# A sliced coworker's head, and its hair, leave with the flying half.
	var designer: Dictionary = crew.person("Designer")
	designer.dead = true
	var standing: Node3D = hairstyles(designer.body)[0].find_child("Hair", true, false)
	crew._slice(designer, Vector3.RIGHT)
	await frames(2)
	var flying: Node3D = designer.pieces[0]
	check(standing.global_basis.get_scale().x < .05 * designer.body.global_basis.get_scale().x
		and hairstyles(flying).size() == 1, "the cut shrinks off the standing legs and flies with the upper half")
	var nodes: int = crew.person("Manager").body.find_children("*", "", true, false).size()
	scene.reset_encounter()
	incident.presentation.skip()
	await frames(3)
	check(hairstyles(crew.person("Designer").body).size() == 1 and crew.person("Manager").body.find_children("*", "", true, false).size() == nodes,
		"retry keeps exactly one haircut per coworker")
	print("RESULT: ", failures, " failure(s)")
	for sound in scene.find_children("*", "AudioStreamPlayer", true, false) + scene.find_children("*", "AudioStreamPlayer3D", true, false):
		sound.stop()
	scene.queue_free()
	paused = false
	await frames(2)
	quit(0 if failures == 0 else 1)
