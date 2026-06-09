class_name AIProject
extends RefCounted
## Simulated AI product in development or launched.

enum Type { LLM, VISION, RECOMMEND }
enum Phase { DATA, TRAIN, EVAL, DEPLOY, LAUNCHED }

const TYPE_NAMES := {
	Type.LLM: "大規模言語モデル",
	Type.VISION: "画像認識",
	Type.RECOMMEND: "推薦エンジン",
}

const PHASE_NAMES := {
	Phase.DATA: "データ収集",
	Phase.TRAIN: "学習",
	Phase.EVAL: "評価",
	Phase.DEPLOY: "デプロイ",
	Phase.LAUNCHED: "商用稼働中",
}

const PHASE_WORK := {
	Phase.DATA: 100.0,
	Phase.TRAIN: 180.0,
	Phase.EVAL: 80.0,
	Phase.DEPLOY: 60.0,
}

var project_name: String = ""
var type: Type = Type.LLM
var phase: Phase = Phase.DATA
var phase_progress: float = 0.0

var accuracy: float = 0.0
var safety: float = 0.0
var inference_speed: float = 0.0
var daily_revenue: float = 0.0
var controversy: float = 0.0


static func create(type_id: Type, index: int) -> AIProject:
	var p := AIProject.new()
	p.type = type_id
	p.project_name = "%s v0.%d" % [TYPE_NAMES[type_id], index]
	return p


func get_type_name() -> String:
	return TYPE_NAMES.get(type, "不明")


func get_phase_name() -> String:
	return PHASE_NAMES.get(phase, "不明")


func get_phase_ratio() -> float:
	if phase == Phase.LAUNCHED:
		return 1.0
	var need: float = PHASE_WORK.get(phase, 100.0)
	return clampf(phase_progress / need, 0.0, 1.0)


func apply_work(amount: float) -> bool:
	if phase == Phase.LAUNCHED:
		return false
	phase_progress += amount
	var need: float = PHASE_WORK.get(phase, 100.0)
	if phase_progress < need:
		return false
	phase_progress = 0.0
	_advance_phase()
	return true


func _advance_phase() -> void:
	match phase:
		Phase.DATA:
			phase = Phase.TRAIN
		Phase.TRAIN:
			phase = Phase.EVAL
		Phase.EVAL:
			phase = Phase.DEPLOY
		Phase.DEPLOY:
			_finalize_stats()
			phase = Phase.LAUNCHED


func _finalize_stats() -> void:
	var base := randf_range(55.0, 75.0)
	accuracy = clampf(base + randf_range(-8.0, 12.0) - controversy * 0.3, 30.0, 98.0)
	safety = clampf(randf_range(50.0, 80.0) - controversy * 0.5, 20.0, 99.0)
	inference_speed = clampf(randf_range(40.0, 90.0), 10.0, 100.0)
	daily_revenue = _calc_revenue()


func _calc_revenue() -> float:
	var quality := accuracy * 0.5 + safety * 0.3 + inference_speed * 0.2
	match type:
		Type.LLM:
			return quality * 120.0
		Type.VISION:
			return quality * 90.0
		Type.RECOMMEND:
			return quality * 70.0
	return quality * 80.0


func add_controversy(amount: float) -> void:
	controversy = clampf(controversy + amount, 0.0, 100.0)
	if phase == Phase.LAUNCHED:
		safety = clampf(safety - amount * 0.4, 10.0, 99.0)
		daily_revenue = _calc_revenue()


func get_summary() -> String:
	if phase != Phase.LAUNCHED:
		return "%s [%s] %s %.0f%%" % [
			project_name, get_type_name(), get_phase_name(), get_phase_ratio() * 100.0
		]
	return "%s | 精度%.0f 安全%.0f 収益$%.0f/日" % [
		project_name, accuracy, safety, daily_revenue
	]
