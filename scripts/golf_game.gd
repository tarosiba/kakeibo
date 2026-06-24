class_name GolfGame
extends RefCounted

signal state_changed
signal shot_resolved(message: String)
signal hole_completed(strokes: int)

enum State { AIMING, FLYING, DONE }
enum AimSlot { LEFT = -1, CENTER = 0, RIGHT = 1 }
enum PowerLevel { WEAK = 0, NORMAL = 1, STRONG = 2 }

const POWER_FACTORS := [0.42, 0.70, 0.93]
const POWER_LABELS := ["ゆるく", "ふつう", "強く"]
const AIM_LABELS := ["左", "まっすぐ", "右"]
const AIM_DEGREES := [-8.0, 0.0, 8.0]

var distance_meters: float = 0.0
var lateral_meters: float = 0.0
var strokes: int = 0
var club_index: int = 0
var aim_slot: int = AimSlot.CENTER
var power_level: int = PowerLevel.NORMAL
var wind_note: String = "少し弱く飛びます"
var state: State = State.AIMING
var last_message: String = ""
var hint_message: String = ""

var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()
	reset_hole()

func reset_hole() -> void:
	distance_meters = 0.0
	lateral_meters = 0.0
	strokes = 0
	aim_slot = AimSlot.CENTER
	power_level = PowerLevel.NORMAL
	state = State.AIMING
	_auto_select_club()
	last_message = "白い旗までボールを運ぼう！"
	hint_message = "① 強さを選ぶ ②「打つ！」を押す（左右はそのままでOK）"

func remaining_meters() -> float:
	return maxf(Course.LENGTH_METERS - distance_meters, 0.0)

func current_lie() -> String:
	return Course.terrain_at(distance_meters, lateral_meters)

func current_club() -> Dictionary:
	return Clubs.get_club(club_index)

func aim_label() -> String:
	return AIM_LABELS[aim_slot + 1]

func power_label() -> String:
	return POWER_LABELS[power_level]

func adjust_aim(delta: int) -> void:
	if state != State.AIMING:
		return
	aim_slot = clampi(aim_slot + delta, AimSlot.LEFT, AimSlot.RIGHT)
	hint_message = "向き: %s — まっすぐで大丈夫ならそのまま打てます" % aim_label()
	_emit()

func cycle_power(delta: int) -> void:
	if state != State.AIMING:
		return
	power_level = clampi(power_level + delta, PowerLevel.WEAK, PowerLevel.STRONG)
	hint_message = "強さ: %s（だいたい %dm 飛ぶ）" % [power_label(), int(estimate_shot_distance())]
	_emit()

func estimate_shot_distance() -> float:
	var club := current_club()
	var lie_factor := Course.lie_penalty(current_lie())
	var power: float = POWER_FACTORS[power_level]
	return lerpf(float(club.min), float(club.max), power) * lie_factor

func take_shot() -> Dictionary:
	if state != State.AIMING:
		return {}
	state = State.FLYING
	strokes += 1

	var club := current_club()
	var lie := current_lie()
	if lie == "water":
		strokes += 1
		distance_meters = maxf(distance_meters - 3.0, 0.0)
		last_message = "池に入ってしまった… 1回分のペナルティ。もう一度！"
		hint_message = "左の池に注意。まっすぐが安全です。"
		state = State.AIMING
		_emit()
		return {"penalty": true}

	var lie_factor := Course.lie_penalty(lie)
	var power: float = POWER_FACTORS[power_level]
	var shot_distance := lerpf(float(club.min), float(club.max), power) * lie_factor
	shot_distance *= 0.96
	shot_distance = maxf(shot_distance, 2.0)

	var accuracy := float(club.accuracy)
	var spread := (1.0 - accuracy) * 8.0
	var aim_degrees: float = AIM_DEGREES[aim_slot + 1]
	var aim_rad := deg_to_rad(aim_degrees)
	var lateral_delta := tan(aim_rad) * shot_distance * 0.18
	lateral_delta += _rng.randf_range(-spread, spread)

	distance_meters = minf(distance_meters + shot_distance, Course.LENGTH_METERS + 5.0)
	lateral_meters += lateral_delta

	var landing_lie := Course.terrain_at(distance_meters, lateral_meters)
	var dist_to_pin := remaining_meters()
	last_message = "%sで %dm 進んだ！ 残り %dm" % [
		power_label(),
		int(shot_distance),
		int(dist_to_pin),
	]
	hint_message = "場所: %s — %s" % [
		Course.terrain_label(landing_lie),
		Course.terrain_hint(landing_lie),
	]

	if dist_to_pin <= Course.CUP_RADIUS_METERS and absf(lateral_meters) < 6.0:
		distance_meters = Course.LENGTH_METERS
		lateral_meters = 0.0
		state = State.DONE
		last_message = "カップイン！ %d回でゴールしました！" % strokes
		hint_message = "おめでとう！ Escキーでもう一度プレイできます。"
		hole_completed.emit(strokes)
	elif distance_meters >= Course.LENGTH_METERS - 1.0 and landing_lie == "green":
		state = State.AIMING
		club_index = Clubs.club_count() - 1
		last_message += " カップのすぐそば！"
		hint_message = "「カップへ転がす」を選んで、ゆるく打つのがおすすめ。"
	elif landing_lie == "water":
		strokes += 1
		distance_meters -= shot_distance * 0.3
		last_message = "池に入った… 1回分のペナルティ。もう一度！"
		hint_message = "左の池に注意。まっすぐが安全です。"
		state = State.AIMING
	else:
		state = State.AIMING
		_auto_select_club()
		if dist_to_pin < 40.0:
			hint_message = "もうすぐゴール！「カップへ転がす」がおすすめ。"

	shot_resolved.emit(last_message)
	_emit()
	return {
		"distance": shot_distance,
		"lateral": lateral_delta,
		"lie": landing_lie,
	}

func _auto_select_club() -> void:
	var remaining := remaining_meters()
	for i in range(Clubs.club_count()):
		var club := Clubs.get_club(i)
		if float(club.max) >= remaining * 0.75:
			club_index = i
			return
	club_index = Clubs.club_count() - 1

func _emit() -> void:
	state_changed.emit()
