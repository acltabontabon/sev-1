extends Node
## Local run state. Bonuses add against the base; resources are never mutated.

@export_range(1, 100) var debt_limit: int = 100
@export_range(0, 1) var damage_bonus: float = .35
@export_range(0, .4) var defense_bonus: float = .20
@export_range(0, .4) var recovery_bonus: float = .25
@export var ship_debt: int = 30
@export var workaround_debt: int = 15
@export_range(0, .15) var pursuit_per_band: float = .05
var debt: int = 0
var choices: Array[int] = []
const TITLES: Array[String] = ["Ship It Friday", "Add More Tests", "Temporary Workaround"]


func reset_run() -> void:
	debt = 0
	choices.clear()


func select(index: int) -> void:
	choices.append(index)
	debt = clampi(debt + cost(index), 0, debt_limit)


func cost(index: int) -> int:
	return [ship_debt, 0, workaround_debt][index]


func band(value: int = -1) -> int:
	return clampi((debt if value < 0 else value) / 25, 0, 3)


func severity(value: int = -1) -> String:
	return ["STABLE", "FRAGILE", "UNSTABLE", "CRITICAL"][band(value)]


func pressure(value: int = -1) -> float:
	return 1.0 + pursuit_per_band * band(value)


func outgoing() -> float:
	return 1.0 + choices.count(0) * damage_bonus


func incoming() -> float:
	return maxf(.4, 1.0 - choices.count(1) * defense_bonus)


func recovery() -> float:
	return maxf(.5, 1.0 - choices.count(2) * recovery_bonus)


func apply_to(player: CharacterBody3D) -> void:
	player.melee.damage_multiplier = outgoing()
	player.incoming_damage_multiplier = incoming()
	player.dodge_recovery_multiplier = recovery()


func option_text(index: int) -> String:
	var benefits: Array[String] = [
		"+%d%% base attack damage" % roundi(damage_bonus * 100),
		"−%d%% incoming damage" % roundi(defense_bonus * 100),
		"−%d%% dodge recovery" % roundi(recovery_bonus * 100)]
	var after: int = clampi(debt + cost(index), 0, debt_limit)
	return "%d   %s\n%s  •  +%d debt\nNext: %s / %d debt / +%d%% enemy pursuit" % [index + 1, TITLES[index], benefits[index], cost(index), severity(after), after, roundi((pressure(after) - 1) * 100)]


func summary() -> String:
	var titles: PackedStringArray = []
	for index in choices:
		titles.append(TITLES[index])
	return ", ".join(titles) if not titles.is_empty() else "None"
