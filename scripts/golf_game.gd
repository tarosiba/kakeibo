class_name GolfGame
extends RefCounted

signal state_changed
signal shot_resolved(message: String)
signal hole_completed(strokes: int)

enum State { AIMING, POWER, FLYING, DONE }

var distance_yards: float = 0.0
var lateral_yards: float = 0.0
var strokes: int = 0
var club_index: int = 0
var aim_degrees: float = 0.0
var wind_head: float = 5.0
var wind_cross: float = -1.5
var state: State = State.AIMING
var power_value: float = 0.0
var power_direction: int = 1
var last_message: String = "クラブと方向を選び、SHOTを押してください。"

var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()
	reset_hole()

func reset_hole() -> void:
	distance_yards = 0.0
	lateral_yards = 0.0
	strokes = 0
	club_index = 0
	aim_degrees = 0.0
	state = State.AIMING
	power_value = 0.0
	power_direction = 1
	last_message = "No.17 — ティーショットの準備。"

func remaining_yards() -> float:
	return maxf(Course.LENGTH_YARDS - distance_yards, 0.0)

func current_lie() -> String:
	return Course.terrain_at(distance_yards, lateral_yards)

func cycle_club(delta: int) -> void:
	if state != State.AIMING:
		return
	club_index = (club_index + delta) % Clubs.club_count()
	if club_index < 0:
		club_index += Clubs.club_count()
	_emit()

func adjust_aim(delta: float) -> void:
	if state != State.AIMING:
		return
	aim_degrees = clampf(aim_degrees + delta, -18.0, 18.0)
	_emit()

func begin_power_gauge() -> void:
	if state != State.AIMING:
		return
	state = State.POWER
	power_value = 0.0
	power_direction = 1
	_emit()

func update_power(delta: float) -> void:
	if state != State.POWER:
		return
	power_value += float(power_direction) * delta * 1.35
	if power_value >= 1.0:
		power_value = 1.0
		power_direction = -1
	elif power_value <= 0.0:
		power_value = 0.0
		power_direction = 1
	_emit()

func confirm_shot() -> Dictionary:
	if state != State.POWER:
		return {}
	state = State.FLYING
	strokes += 1
	var club := Clubs.get_club(club_index)
	var lie := current_lie()
	if lie == "water":
		last_message = "ウォーターハザード！ ペナルティ打数。"
		strokes += 1
		distance_yards = maxf(distance_yards - 4.0, 0.0)
		state = State.AIMING
		_emit()
		return {"penalty": true}

	var lie_factor := Course.lie_penalty(lie)
	var power := 0.35 + power_value * 0.65
	var base_dist := lerpf(float(club.min), float(club.max), power) * lie_factor
	var elev_start := Course.elevation_at(distance_yards / float(Course.LENGTH_YARDS))
	var elev_end := Course.elevation_at(
		clampf((distance_yards + base_dist) / float(Course.LENGTH_YARDS), 0.0, 1.0)
	)
	var elev_delta := elev_end - elev_start
	base_dist -= elev_delta * 2.2
	base_dist -= wind_head * 1.4
	base_dist = maxf(base_dist, 3.0)

	var accuracy := float(club.accuracy)
	var spread := (1.0 - accuracy) * 24.0
	var aim_rad := deg_to_rad(aim_degrees)
	var lateral_delta := tan(aim_rad) * base_dist * 0.22
	lateral_delta += wind_cross * 1.1
	lateral_delta += _rng.randf_range(-spread, spread)

	distance_yards = minf(distance_yards + base_dist, float(Course.LENGTH_YARDS) + 6.0)
	lateral_yards += lateral_delta

	var landing_lie := Course.terrain_at(distance_yards, lateral_yards)
	var dist_to_pin := remaining_yards()
	last_message = "%s %.0fy — %s（残り %.0fy）" % [club.label, base_dist, _lie_label(landing_lie), dist_to_pin]

	if dist_to_pin <= Course.CUP_RADIUS_YARDS and absf(lateral_yards) < 8.0:
		distance_yards = float(Course.LENGTH_YARDS)
		lateral_yards = 0.0
		state = State.DONE
		last_message = "カップイン！ %d打でホールアウト。" % strokes
		hole_completed.emit(strokes)
	elif distance_yards >= float(Course.LENGTH_YARDS) - 1.0 and landing_lie == "green":
		state = State.AIMING
		club_index = Clubs.club_count() - 1
		last_message += " — グリーン上、パットしよう。"
	elif landing_lie == "water":
		strokes += 1
		distance_yards -= base_dist * 0.35
		last_message = "池に入った… ドロップして再打。"
		state = State.AIMING
	else:
		state = State.AIMING
		_auto_select_club()

	shot_resolved.emit(last_message)
	_emit()
	return {
		"distance": base_dist,
		"lateral": lateral_delta,
		"lie": landing_lie,
	}

func _auto_select_club() -> void:
	var remaining := remaining_yards()
	for i in range(Clubs.club_count()):
		var club := Clubs.get_club(i)
		if float(club.max) >= remaining * 0.72:
			club_index = i
			return
	club_index = Clubs.club_count() - 1

func _lie_label(lie: String) -> String:
	match lie:
		"fairway":
			return "フェアウェイ"
		"rough":
			return "ラフ"
		"bunker":
			return "バンカー"
		"green":
			return "グリーン"
		"water":
			return "池"
		"tee":
			return "ティー"
		_:
			return lie

func _emit() -> void:
	state_changed.emit()
