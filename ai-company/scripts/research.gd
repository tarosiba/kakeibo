extends Node
## Company-wide research tree progression.

signal research_changed

var _defs: Dictionary = {}
var unlocked: Dictionary = {}
var active_id: String = ""
var active_progress: float = 0.0


func _ready() -> void:
	for node in ResearchDefs.get_all():
		_defs[node.id] = node
		if node.starts_unlocked:
			unlocked[node.id] = true
	research_changed.emit()


func get_node(id: String) -> ResearchDefs.NodeInfo:
	return _defs.get(id)


func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)


func can_start(id: String) -> bool:
	if is_unlocked(id) or active_id == id:
		return false
	var node: ResearchDefs.NodeInfo = _defs.get(id)
	if node == null:
		return false
	for prereq in node.prerequisites:
		if not is_unlocked(prereq):
			return false
	return true


func start_research(id: String) -> Dictionary:
	if not can_start(id):
		return {"ok": false, "reason": "条件を満たしていません。"}
	if active_id != "":
		return {"ok": false, "reason": "別の研究が進行中です。"}

	var node: ResearchDefs.NodeInfo = _defs[id]
	if not Game.can_afford(node.cost):
		return {"ok": false, "reason": "資金不足です。"}

	Game.money -= node.cost
	active_id = id
	active_progress = 0.0
	research_changed.emit()
	return {"ok": true, "reason": ""}


func advance_day(employee_count: int) -> void:
	if active_id == "":
		return
	var node: ResearchDefs.NodeInfo = _defs.get(active_id)
	if node == null:
		active_id = ""
		return

	active_progress += employee_count * 6.0
	if active_progress < node.work_needed:
		return

	unlocked[active_id] = true
	Game.add_log("研究完了: %s" % node.name)
	active_id = ""
	active_progress = 0.0
	research_changed.emit()


func get_active_label() -> String:
	if active_id == "":
		return "研究なし"
	var node: ResearchDefs.NodeInfo = _defs.get(active_id)
	if node == null:
		return "研究なし"
	var ratio := clampf(active_progress / node.work_needed, 0.0, 1.0)
	return "%s %.0f%%" % [node.name, ratio * 100.0]


func get_bonuses_for_type(type_id: AIProject.Type) -> Dictionary:
	var acc := 0.0
	var safe := 0.0
	var spd := 0.0
	var names: PackedStringArray = []

	for id in unlocked.keys():
		var node: ResearchDefs.NodeInfo = _defs.get(id)
		if node == null:
			continue
		if type_id not in node.boosts:
			continue
		acc += node.accuracy_bonus
		safe += node.safety_bonus
		spd += node.speed_bonus
		names.append(node.name)

	return {
		"accuracy": acc,
		"safety": safe,
		"speed": spd,
		"names": names,
	}


func get_tree_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	for node in ResearchDefs.get_all():
		if node.starts_unlocked and node.cost <= 0.0:
			continue
		var status := _status_label(node.id)
		lines.append("%s | %s | $%.0f" % [status, node.name, node.cost])
	return lines


func get_status_label(id: String) -> String:
	return _status_label(id)


func _status_label(id: String) -> String:
	if is_unlocked(id):
		return "✓"
	if active_id == id:
		var node: ResearchDefs.NodeInfo = _defs[id]
		var ratio := clampf(active_progress / node.work_needed, 0.0, 1.0)
		return "研究中%.0f%%" % (ratio * 100.0)
	if can_start(id):
		return "開始可"
	return "ロック"
