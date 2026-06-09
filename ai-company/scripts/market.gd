extends Node
## AI market simulation: player vs competitor market share.

signal market_changed

class Competitor:
	var name: String
	var share: float
	var momentum: float
	var specialty: String


const PLAYER_NAME := "あなたの会社"

var competitors: Array[Competitor] = []
var player_share: float = 4.0


func _ready() -> void:
	competitors.append(_make_competitor("ApexAI", 34.0, 0.12, "LLM"))
	competitors.append(_make_competitor("VisionForge", 26.0, 0.08, "画像AI"))
	competitors.append(_make_competitor("RecoNet", 20.0, 0.05, "推薦"))
	_normalize_shares()
	market_changed.emit()


func advance_day() -> void:
	for c in competitors:
		c.share += randf_range(-0.35, 0.45) + c.momentum
		c.share = clampf(c.share, 3.0, 55.0)

	_update_player_share_from_performance()
	_normalize_shares()
	market_changed.emit()


func on_player_launch(product: AIProject) -> void:
	var bump := 1.2 + product.accuracy * 0.04 + product.safety * 0.02
	match product.type:
		AIProject.Type.LLM:
			bump += 0.8
		AIProject.Type.VISION:
			bump += 0.5
		AIProject.Type.RECOMMEND:
			bump += 0.4
	player_share += bump
	Game.add_log("市場シェア拡大の兆候 (+%.1f%%)" % bump)
	_normalize_shares()
	market_changed.emit()


func apply_competitor_pressure(amount: float) -> void:
	player_share = clampf(player_share - amount, 1.0, 80.0)
	_normalize_shares()
	market_changed.emit()


func get_revenue_multiplier() -> float:
	# シェアが低いと収益が伸びにくい。10%前後で1.0倍の目安。
	return clampf(player_share / 12.0, 0.25, 2.0)


func get_rank() -> int:
	var rank := 1
	for c in competitors:
		if c.share > player_share:
			rank += 1
	return rank


func get_share_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append("%s  %.1f%%" % [PLAYER_NAME, player_share])
	for c in competitors:
		lines.append("%s  %.1f%%" % [c.name, c.share])
	lines.append("その他  %.1f%%" % _other_share())
	return lines


func get_leader_name() -> String:
	var leader := PLAYER_NAME
	var top := player_share
	for c in competitors:
		if c.share > top:
			top = c.share
			leader = c.name
	return leader


func _update_player_share_from_performance() -> void:
	var power := Game.reputation * 0.08
	power += Game.launched_products.size() * 1.5
	for product in Game.launched_products:
		power += product.accuracy * 0.03 + product.daily_revenue * 0.002
	player_share += power * 0.02 - 0.05
	player_share = clampf(player_share, 1.0, 60.0)


func _normalize_shares() -> void:
	var total := player_share
	for c in competitors:
		total += c.share
	if total <= 0.0:
		return
	var scale := 96.0 / total
	player_share *= scale
	for c in competitors:
		c.share *= scale


func _other_share() -> float:
	var used := player_share
	for c in competitors:
		used += c.share
	return clampf(100.0 - used, 0.0, 100.0)


func _make_competitor(name: String, share: float, momentum: float, specialty: String) -> Competitor:
	var c := Competitor.new()
	c.name = name
	c.share = share
	c.momentum = momentum
	c.specialty = specialty
	return c
