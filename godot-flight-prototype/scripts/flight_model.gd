class_name FlightModel
extends RefCounted
## Simplified Cessna-like flight model for arcade FS4 feel.

const GRAVITY := 9.81
const STALL_SPEED := 28.0
const MAX_SPEED := 95.0
const GROUND_ALT := 0.0

var position := Vector3(0.0, 420.0, -1800.0)
var velocity := Vector3(0.0, 0.0, 62.0)
var pitch := 0.0
var roll := 0.0
var heading := 0.0
var throttle := 0.62
var on_ground := false
var crashed := false
var flight_time := 0.0

var airspeed_kts: float:
	get:
		return velocity.length() * 1.94384

var altitude_ft: float:
	get:
		return position.y * 3.28084

var vertical_speed_fpm: float:
	get:
		return velocity.y * 196.85


func reset() -> void:
	position = Vector3(0.0, 420.0, -1800.0)
	velocity = Vector3(0.0, 0.0, 62.0)
	pitch = -2.0
	roll = 0.0
	heading = 0.0
	throttle = 0.62
	on_ground = false
	crashed = false
	flight_time = 0.0


func apply_controls(
	pitch_input: float,
	roll_input: float,
	yaw_input: float,
	throttle_input: float,
	braking: bool,
	delta: float
) -> void:
	if crashed:
		return

	throttle = clampf(throttle + throttle_input * delta * 0.35, 0.0, 1.0)
	if braking and on_ground:
		velocity *= 1.0 - minf(delta * 2.5, 1.0)

	var target_pitch_rate := pitch_input * 28.0
	var target_roll_rate := roll_input * 52.0
	var target_yaw_rate := yaw_input * 18.0 + roll * 0.08

	pitch = lerpf(pitch, pitch + target_pitch_rate * delta, 0.22)
	roll = lerpf(roll, roll + target_roll_rate * delta, 0.18)
	heading = fposmod(heading + target_yaw_rate * delta, 360.0)

	pitch = clampf(pitch, -24.0, 24.0)
	roll = clampf(roll, -55.0, 55.0)

	var lift_factor := clampf((airspeed_kts - STALL_SPEED) / 40.0, -0.4, 1.2)
	var thrust := throttle * 26.0
	var drag := velocity.length() * 0.018 + airspeed_kts * 0.04
	var lift := lift_factor * 11.0 - pitch * 0.08

	var forward := _forward_vector()
	var right := forward.cross(Vector3.UP).normalized()
	var up := right.cross(forward).normalized()

	var accel := forward * thrust
	accel += up * lift
	accel.y -= GRAVITY * 0.55
	accel -= velocity.normalized() * drag

	velocity += accel * delta
	position += velocity * delta
	flight_time += delta

	_handle_ground_contact()


func _handle_ground_contact() -> void:
	on_ground = position.y <= GROUND_ALT + 2.5
	if position.y < GROUND_ALT:
		position.y = GROUND_ALT
		if velocity.y < -12.0:
			crashed = true
			velocity = Vector3.ZERO
		else:
			velocity.y = 0.0
			if airspeed_kts < 4.0:
				velocity = Vector3.ZERO


func _forward_vector() -> Vector3:
	var pitch_rad := deg_to_rad(pitch)
	var heading_rad := deg_to_rad(heading)
	var roll_rad := deg_to_rad(roll)

	var base := Vector3(
		sin(heading_rad),
		-sin(pitch_rad),
		-cos(heading_rad)
	).normalized()

	var right := base.cross(Vector3.UP).normalized()
	var up := right.cross(base).normalized()
	return base.rotated(right, roll_rad).normalized()
