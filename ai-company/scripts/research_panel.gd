extends CanvasLayer

signal closed

@onready var tree_list: ItemList = $Panel/Margin/VBox/TreeList
@onready var detail_label: Label = $Panel/Margin/VBox/DetailLabel
@onready var active_label: Label = $Panel/Margin/VBox/ActiveLabel
@onready var start_btn: Button = $Panel/Margin/VBox/ButtonRow/StartBtn
@onready var close_btn: Button = $Panel/Margin/VBox/ButtonRow/CloseBtn

var _ordered_ids: Array[String] = []


func _ready() -> void:
	visible = false
	Research.research_changed.connect(_refresh)
	tree_list.item_selected.connect(_on_item_selected)
	start_btn.pressed.connect(_on_start_pressed)
	close_btn.pressed.connect(_close)


func open_panel() -> void:
	_refresh()
	visible = true


func _close() -> void:
	visible = false
	closed.emit()


func _refresh() -> void:
	tree_list.clear()
	_ordered_ids.clear()

	for node in ResearchDefs.get_all():
		if node.starts_unlocked and node.cost <= 0.0:
			continue
		_ordered_ids.append(node.id)
		var line := "[%s] %s" % [Research.get_status_label(node.id), node.name]
		tree_list.add_item(line)

	active_label.text = "進行中: %s" % Research.get_active_label()
	_update_detail()


func _on_item_selected(index: int) -> void:
	_update_detail(index)


func _update_detail(index: int = -1) -> void:
	if index < 0:
		var selected := tree_list.get_selected_items()
		if not selected.is_empty():
			index = selected[0]
	if index < 0 or index >= _ordered_ids.size():
		detail_label.text = "技術を選択してください。"
		start_btn.disabled = true
		return

	var id := _ordered_ids[index]
	var node: ResearchDefs.NodeInfo = Research.get_node(id)
	if node == null:
		return

	var prereq_text := "なし"
	if not node.prerequisites.is_empty():
		var names: PackedStringArray = []
		for pid in node.prerequisites:
			var p: ResearchDefs.NodeInfo = Research.get_node(pid)
			names.append(p.name if p else pid)
		prereq_text = ", ".join(names)

	detail_label.text = "%s\n%s\n必要: %s | 費用 $%.0f | 研究量 %.0f\nボーナス 精度%+.0f 安全%+.0f 速度%+.0f" % [
		node.name,
		node.description,
		prereq_text,
		node.cost,
		node.work_needed,
		node.accuracy_bonus,
		node.safety_bonus,
		node.speed_bonus,
	]
	start_btn.disabled = not Research.can_start(id)


func _on_start_pressed() -> void:
	var selected := tree_list.get_selected_items()
	if selected.is_empty():
		return
	var id := _ordered_ids[selected[0]]
	var result: Dictionary = Research.start_research(id)
	if not result.ok:
		Game.add_log("研究開始失敗: %s" % result.reason)
	else:
		var node: ResearchDefs.NodeInfo = Research.get_node(id)
		Game.add_log("研究開始: %s" % node.name)
		Game.state_changed.emit()
	_refresh()
