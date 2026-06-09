extends Control

@onready var money_label: Label = $Margin/Root/Header/MoneyLabel
@onready var rep_label: Label = $Margin/Root/Header/RepLabel
@onready var day_label: Label = $Margin/Root/Header/DayLabel
@onready var staff_label: Label = $Margin/Root/Stats/StaffLabel
@onready var gpu_label: Label = $Margin/Root/Stats/GpuLabel
@onready var burn_label: Label = $Margin/Root/Stats/BurnLabel
@onready var revenue_label: Label = $Margin/Root/Stats/RevenueLabel
@onready var project_label: Label = $Margin/Root/ProjectPanel/ProjectLabel
@onready var progress_bar: ProgressBar = $Margin/Root/ProjectPanel/ProgressBar
@onready var focus_row: HBoxContainer = $Margin/Root/ProjectPanel/FocusRow
@onready var focus_label: Label = $Margin/Root/ProjectPanel/FocusLabel
@onready var focus_safety_btn: Button = $Margin/Root/ProjectPanel/FocusRow/FocusSafetyBtn
@onready var focus_balanced_btn: Button = $Margin/Root/ProjectPanel/FocusRow/FocusBalancedBtn
@onready var focus_accuracy_btn: Button = $Margin/Root/ProjectPanel/FocusRow/FocusAccuracyBtn
@onready var research_status_label: Label = $Margin/Root/ResearchRow/ResearchStatusLabel
@onready var products_list: ItemList = $Margin/Root/ProductsPanel/ProductsList
@onready var log_label: RichTextLabel = $Margin/Root/LogPanel/LogLabel

@onready var next_day_btn: Button = $Margin/Root/Actions/NextDayBtn
@onready var hire_btn: Button = $Margin/Root/Actions/HireBtn
@onready var gpu_btn: Button = $Margin/Root/Actions/GpuBtn
@onready var llm_btn: Button = $Margin/Root/Actions/LlmBtn
@onready var vision_btn: Button = $Margin/Root/Actions/VisionBtn
@onready var recommend_btn: Button = $Margin/Root/Actions/RecommendBtn
@onready var cancel_btn: Button = $Margin/Root/Actions/CancelBtn
@onready var demo_btn: Button = $Margin/Root/Actions/DemoBtn
@onready var chat_demo: CanvasLayer = $ChatDemo
@onready var research_panel: CanvasLayer = $ResearchPanel
@onready var research_btn: Button = $Margin/Root/ResearchRow/ResearchBtn


func _ready() -> void:
	LlmClient.reset_session()
	Game.state_changed.connect(_refresh_ui)
	Game.log_added.connect(func(_m): _refresh_log())
	Research.research_changed.connect(_refresh_ui)
	_connect_buttons()
	_refresh_ui()


func _connect_buttons() -> void:
	next_day_btn.pressed.connect(Game.advance_day)
	hire_btn.pressed.connect(Game.hire_employee)
	gpu_btn.pressed.connect(Game.buy_gpu)
	llm_btn.pressed.connect(func(): Game.start_project(AIProject.Type.LLM))
	vision_btn.pressed.connect(func(): Game.start_project(AIProject.Type.VISION))
	recommend_btn.pressed.connect(func(): Game.start_project(AIProject.Type.RECOMMEND))
	cancel_btn.pressed.connect(Game.cancel_project)
	demo_btn.pressed.connect(_open_chat_demo)
	research_btn.pressed.connect(func(): research_panel.open_panel())
	focus_safety_btn.pressed.connect(func(): _set_focus(AIProject.DevFocus.SAFETY))
	focus_balanced_btn.pressed.connect(func(): _set_focus(AIProject.DevFocus.BALANCED))
	focus_accuracy_btn.pressed.connect(func(): _set_focus(AIProject.DevFocus.ACCURACY))


func _set_focus(focus: AIProject.DevFocus) -> void:
	if Game.active_project == null:
		return
	Game.active_project.set_dev_focus(focus)
	Game.add_log("開発方針を変更: %s" % Game.active_project.get_focus_name())
	_refresh_ui()


func _open_chat_demo() -> void:
	var llm_products := Game.get_launched_llm_products()
	if llm_products.is_empty():
		return
	chat_demo.open_demo(llm_products)


func _refresh_ui() -> void:
	money_label.text = "資金: $%.0f" % Game.money
	rep_label.text = "評判: %.0f" % Game.reputation
	day_label.text = "Day %d" % Game.day
	staff_label.text = "研究者: %d名" % Game.employee_count
	gpu_label.text = "GPU: %d台" % Game.gpu_count
	burn_label.text = "日次コスト: $%.0f" % Game.get_daily_burn()
	revenue_label.text = "日次収益: $%.0f" % Game.get_daily_revenue()

	if Game.active_project == null:
		project_label.text = "進行中プロジェクト: なし"
		progress_bar.value = 0.0
		cancel_btn.disabled = true
		focus_label.visible = false
		focus_row.visible = false
	else:
		var p := Game.active_project
		project_label.text = "進行中: %s" % p.get_summary()
		progress_bar.value = p.get_phase_ratio() * 100.0
		cancel_btn.disabled = false

	var can_focus := p.can_adjust_focus()
	focus_label.visible = can_focus
	focus_row.visible = can_focus
	focus_safety_btn.visible = can_focus
	focus_balanced_btn.visible = can_focus
	focus_accuracy_btn.visible = can_focus
	focus_safety_btn.disabled = not can_focus
	focus_balanced_btn.disabled = not can_focus
	focus_accuracy_btn.disabled = not can_focus
	if can_focus:
		focus_label.text = "開発方針（学習/評価中）: %s" % p.get_focus_name()

	research_status_label.text = "研究: %s" % Research.get_active_label()

	products_list.clear()
	for product in Game.launched_products:
		products_list.add_item(product.get_summary())

	demo_btn.disabled = Game.get_launched_llm_products().is_empty()

	_refresh_log()


func _refresh_log() -> void:
	log_label.text = Game.get_log_text()
	log_label.scroll_to_line(log_label.get_line_count())
