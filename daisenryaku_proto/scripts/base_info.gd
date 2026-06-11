class_name BaseInfo
extends RefCounted

enum Owner {
	NEUTRAL,
	PLAYER,
	ENEMY,
}

enum BaseType {
	CITY,
	AIRFIELD,
}

var base_name: String = "基地"
var owner: Owner = Owner.NEUTRAL
var base_type: BaseType = BaseType.CITY
var income: int = 200
var produced_this_turn: bool = false


func is_owned_by(faction: Unit.Faction) -> bool:
	match faction:
		Unit.Faction.PLAYER:
			return owner == Owner.PLAYER
		Unit.Faction.ENEMY:
			return owner == Owner.ENEMY
		_:
			return false


func set_owner_from_faction(faction: Unit.Faction) -> void:
	match faction:
		Unit.Faction.PLAYER:
			owner = Owner.PLAYER
		Unit.Faction.ENEMY:
			owner = Owner.ENEMY
		_:
			owner = Owner.NEUTRAL


func is_airfield() -> bool:
	return base_type == BaseType.AIRFIELD


func is_city() -> bool:
	return base_type == BaseType.CITY


func get_owner_color() -> Color:
	match owner:
		Owner.PLAYER:
			return Color(0.90, 0.35, 0.30, 0.85)
		Owner.ENEMY:
			return Color(0.30, 0.50, 0.90, 0.85)
		_:
			return Color(0.70, 0.70, 0.70, 0.85)
