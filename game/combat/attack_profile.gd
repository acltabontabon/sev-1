class_name AttackProfile
extends Resource
## One editable light-attack step. Only the player's three existing steps use it.

@export var title: String = "Slash"
@export_range(1, 200) var damage: int = 25
@export_range(0.01, 1.0) var windup: float = 0.12
@export_range(0.01, 1.0) var active_time: float = 0.12
@export_range(0.01, 1.0) var recovery: float = 0.28
@export_range(0.5, 4.0) var reach: float = 2.25
@export_range(10, 90) var half_angle_degrees: float = 65.0
@export_range(-1, 1) var swing_direction: int = 1
@export_range(0.0, 0.12) var hitstop: float = 0.045
@export var color: Color = Color(0.3, 0.95, 1)
