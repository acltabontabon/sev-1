extends RefCounted
## The night shift's talk, loaded from assets/audio/voices/talk.json: who the overtime crew
## are (`crew`), what they say when the engineer stops to talk (`trees`), and their
## Kokoro voice profiles. Satire aims at the systems (incentives, process, policy), never
## at a profession.
##
## Each tree: who/role for the name plate, "start" (and optional "again" for a second
## visit), and nodes: {text, replies: [[reply, next node or "" to leave, effect]]}.
## A node without replies ends the talk. Effects are tiny and optional:
## {"burnout": n, "note": why} goes through the run's normal Burnout bookkeeping.
## Every node is voiced as `<voice><node>.ogg` under assets/audio/voices/talk/.

const MANIFEST: String = "res://assets/audio/voices/talk.json"
const AUDIO: String = "res://assets/audio/voices/talk/%s.ogg"
static var cache: Dictionary = {}


static func data() -> Dictionary:
	if cache.is_empty():
		cache = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	return cache


static func has_tree(name: String) -> bool:
	return data().trees.has(name)


## A coworker's talk, tagged with the prefix its voiced lines use.
static func tree(name: String) -> Dictionary:
	var talk: Dictionary = (data().trees[name] as Dictionary).duplicate(true)
	talk.voice = "talk_%s_" % name.to_lower()
	return talk


## Who an archetype used to be, in planting order.
static func crew(kind: String) -> Array:
	return data().crew.get(kind, data().crew.record)


## The talk with an employee a wave is waiting inside: polite, and wrong.
static func host_tree(identity: Dictionary, kind: String) -> Dictionary:
	return {"who": identity.get("name", "EMPLOYEE"), "role": "%s · overtime" % identity.get("team", "Payments"), "start": "a",
		"voice": "host_%s_" % str(identity.get("name", "")).to_lower(), "nodes": {
		"a": {"text": identity.get("line", "…"), "replies": [
			["Are you okay?", "wrong", {}],
			["…I'll just go.", "soon", {}]]},
		"wrong": {"text": data().host_replies.get(kind, "Fine."), "replies": [["(Back away slowly.)", "soon", {}]]},
		"soon": {"text": data().host_soon, "replies": []},
	}}


static func audio(id: String) -> String:
	return AUDIO % id


## The engineer's spoken reply clip; tools/voices.py reply_id() uses the same rule.
static func reply_id(text: String) -> String:
	var slug: String = ""
	for character in text.to_lower():
		if character in "abcdefghijklmnopqrstuvwxyz0123456789":
			slug += character
		elif not slug.ends_with("_"):
			slug += "_"
	return "you_" + slug.lstrip("_").rstrip("_").left(40)


## Stage directions in parentheses and bare ellipses are not spoken.
static func voiced_reply(text: String) -> bool:
	if text.begins_with("("):
		return false
	for character in text:
		if character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789":
			return true
	return false
