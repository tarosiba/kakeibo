extends Node
## Company simulation: funds, staff, GPUs, fake AI projects, random events.

signal state_changed
signal log_added(message: String)

const START_MONEY := 120_000.0
const DAILY_OVERHEAD_PER_EMPLOYEE := 400.0
const DAILY_GPU_POWER_COST := 150.0
const HIRE_COST := 9_000.0
const GPU_COST := 18_000.0
const PROJECT_START_COST := 22_000.0

var day: int = 1
var money: float = START_MONEY
var reputation: float = 50.0
var gpu_count: int = 2
var employee_count: int = 3

var active_project: AIProject = null
var launched_products: Array[AIProject] = []
var _project_counter: int = 1
var _log: PackedStringArray = []


func _ready() -> void:
	_add_log("AIスタートアップ設立。資金と人材を管理して製品を世に出そう。")


func get_daily_burn() -> float:
	return employee_count * DAILY_OVERHEAD_PER_EMPLOYEE + gpu_count * DAILY_GPU_POWER_COST


func get_work_per_day() -> float:
	if active_project == null:
		return 0.0
	return employee_count * 8.0 + gpu_count * 12.0


func get_daily_revenue() -> float:
	var total := 0.0
	for product in launched_products:
		total += product.daily_revenue
	return total * Market.get_revenue_multiplier()


func get_base_daily_revenue() -> float:
	var total := 0.0
	for product in launched_products:
		total += product.daily_revenue
	return total


func can_afford(cost: float) -> bool:
	return money >= cost


func hire_employee() -> bool:
	if not can_afford(HIRE_COST):
		_add_log("資金不足: 採用できません。")
		return false
	money -= HIRE_COST
	employee_count += 1
	reputation += 1.0
	_add_log("研究者を採用（計%d名）。" % employee_count)
	state_changed.emit()
	return true


func buy_gpu() -> bool:
	if not can_afford(GPU_COST):
		_add_log("資金不足: GPUを購入できません。")
		return false
	money -= GPU_COST
	gpu_count += 1
	_add_log("GPUを追加（計%d台）。" % gpu_count)
	state_changed.emit()
	return true


func start_project(type_id: AIProject.Type) -> bool:
	if active_project != null:
		_add_log("進行中プロジェクトがあります。完了または中止してから開始してください。")
		return false
	if not can_afford(PROJECT_START_COST):
		_add_log("資金不足: 新規プロジェクトを開始できません。")
		return false
	money -= PROJECT_START_COST
	active_project = AIProject.create(type_id, _project_counter)
	_project_counter += 1
	_add_log("新規開発開始: %s" % active_project.project_name)
	state_changed.emit()
	return true


func cancel_project() -> void:
	if active_project == null:
		return
	_add_log("プロジェクト中止: %s" % active_project.project_name)
	active_project = null
	reputation = clampf(reputation - 3.0, 0.0, 100.0)
	state_changed.emit()


func advance_day() -> void:
	var burn := get_daily_burn()
	var revenue := get_daily_revenue()
	money += revenue - burn
	day += 1

	Research.advance_day(employee_count)
	Market.advance_day()

	if active_project != null:
		var finished_phase := active_project.apply_work(get_work_per_day())
		if finished_phase:
			_on_phase_completed()

	_maybe_trigger_event()

	if money < -20_000.0:
		_add_log("資金が尽きました。ゲームオーバー（デモ終了）。")
		money = 0.0

	state_changed.emit()


func _on_phase_completed() -> void:
	if active_project == null:
		return
	if active_project.phase == AIProject.Phase.LAUNCHED:
		launched_products.append(active_project)
		reputation = clampf(reputation + 8.0, 0.0, 100.0)
		Market.on_player_launch(active_project)
		_add_log("ローンチ成功! %s" % active_project.get_summary())
		active_project = null
	else:
		_add_log("フェーズ完了 → %s" % active_project.get_phase_name())


func _maybe_trigger_event() -> void:
	if randf() > 0.22:
		return

	var roll := randi() % 6
	match roll:
		0:
			var bonus := randf_range(30_000.0, 80_000.0)
			money += bonus
			_add_log("VCから資金調達 +$%.0f" % bonus)
		1:
			reputation = clampf(reputation - randf_range(4.0, 10.0), 0.0, 100.0)
			Market.apply_competitor_pressure(randf_range(0.8, 2.5))
			_add_log("競合が同等モデルを公開。評判とシェアが低下。")
		2:
			if active_project != null:
				active_project.add_controversy(randf_range(8.0, 20.0))
				_add_log("学習データの偏りが指摘された（安全性リスク上昇）。")
			else:
				reputation = clampf(reputation - 2.0, 0.0, 100.0)
				_add_log("業界全体でAI規制の議論が活発化。")
		3:
			money -= randf_range(5_000.0, 15_000.0)
			_add_log("クラウドGPUの請求が想定より高かった。")
		4:
			reputation = clampf(reputation + randf_range(3.0, 8.0), 0.0, 100.0)
			_add_log("技術ブログで好評。採用と評判が改善。")
		5:
			if active_project != null and active_project.phase == AIProject.Phase.TRAIN:
				active_project.phase_progress += 25.0
				_add_log("ハイパーパラメータ調整が功を奏し、学習が加速。")


func get_launched_llm_products() -> Array[AIProject]:
	var out: Array[AIProject] = []
	for product in launched_products:
		if product.type == AIProject.Type.LLM:
			out.append(product)
	return out


func get_log_text() -> String:
	return "\n".join(_log)


func add_log(message: String) -> void:
	_add_log(message)


func _add_log(message: String) -> void:
	_log.append("Day %d: %s" % [day, message])
	if _log.size() > 40:
		_log.remove_at(0)
	log_added.emit(message)
