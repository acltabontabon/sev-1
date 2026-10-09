extends Node
## Local run state. Bonuses add against the base; resources are never mutated.

@export_range(1, 100) var debt_limit: int = 100
@export_range(0, 1) var damage_bonus: float = .35
@export_range(0, .4) var defense_bonus: float = .20
@export_range(0, .4) var recovery_bonus: float = .25
@export var ship_debt: int = 30
@export var workaround_debt: int = 15
@export_range(0, .15) var pursuit_per_band: float = .05
@export_range(70, 200) var burnout_limit: int = 100
@export var meaningful_hit: int = 10
@export var hit_burnout: int = 8
@export var commit_burnout: int = 35
@export var estimate_burnout: int = 8
@export var dependency_relief: int = 20
@export var containment_relief: int = 15
@export var commitment_reward: int = 20
@export_range(0, .25) var pressured_bonus: float = .10
@export_range(0, .30) var overloaded_bonus: float = .25
@export_range(0, .25) var pressured_risk: float = .10
@export_range(0, .25) var overloaded_risk: float = .25
var burnout: int = 0
var burnout_notice: String = ""
var debt: int = 0
var choices: Array[int] = []
const TITLES: Array[String] = ["Ship It Friday", "Add More Tests", "Temporary Workaround"]


func reset_run() -> void:
	debt = 0
	burnout = 0
	burnout_notice = ""
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


func outgoing(extra_choice: int = -1, burnout_value: int = -1) -> float:
	return clampf(1.0 + (choices.count(0) + (1 if extra_choice == 0 else 0)) * damage_bonus + burnout_offense(burnout_value), 1.0, 2.0)


func incoming(extra_choice: int = -1, burnout_value: int = -1) -> float:
	return clampf(1.0 - (choices.count(1) + (1 if extra_choice == 1 else 0)) * defense_bonus + burnout_risk(burnout_value), .4, 1.25)


func recovery(extra_choice: int = -1) -> float:
	return maxf(.5, 1.0 - (choices.count(2) + (1 if extra_choice == 2 else 0)) * recovery_bonus)


func modifier_summary(extra_choice: int = -1, burnout_value: int = -1) -> String:
	return "Damage %d%% • Taken %d%% • Dodge recovery %d%%" % [roundi(outgoing(extra_choice, burnout_value) * 100), roundi(incoming(extra_choice, burnout_value) * 100), roundi(recovery(extra_choice) * 100)]


func apply_to(player: CharacterBody3D) -> void:
	player.melee.damage_multiplier = outgoing()
	player.incoming_damage_multiplier = incoming()
	player.dodge_recovery_multiplier = recovery()


func option_text(index: int) -> String:
	var benefits: Array[String] = [
		"+%d%% base attack damage" % roundi(damage_bonus * 100),
		"−%d%% base incoming damage" % roundi(defense_bonus * 100),
		"−%d%% base dodge recovery" % roundi(recovery_bonus * 100)]
	var after: int = clampi(debt + cost(index), 0, debt_limit)
	return "%d   %s\n%s • +%d debt\nAfter: %s\nNext enemies: +%d%% pursuit • %d debt / %s" % [index + 1, TITLES[index], benefits[index], cost(index), modifier_summary(index), roundi((pressure(after) - 1) * 100), after, severity(after)]


func summary() -> String:
	var titles: PackedStringArray = []
	for index in choices:
		titles.append(TITLES[index])
	return ", ".join(titles) if not titles.is_empty() else "None"


func change_burnout(amount: int, source: String) -> void:
	var before: int = burnout
	burnout = clampi(burnout + amount, 0, burnout_limit)
	burnout_notice = "%s: %+d" % [source, burnout - before]


func burnout_band(value: int = -1) -> int:
	var pressure_value: int = burnout if value < 0 else value
	return 2 if pressure_value >= 70 else (1 if pressure_value >= 30 else 0)


func burnout_title(value: int = -1) -> String:
	return ["COMPOSED", "PRESSURED", "OVERLOADED"][burnout_band(value)]


func burnout_offense(value: int = -1) -> float:
	return [0.0, pressured_bonus, overloaded_bonus][burnout_band(value)]


func burnout_risk(value: int = -1) -> float:
	return [0.0, pressured_risk, overloaded_risk][burnout_band(value)]
