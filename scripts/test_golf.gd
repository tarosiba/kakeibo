extends SceneTree

func _init() -> void:
	var game := GolfGame.new()
	_assert(game.strokes == 0, "starts at zero strokes")
	_assert(game.remaining_meters() == Course.LENGTH_METERS, "full hole remaining")
	_assert(game.power_label() == "ふつう", "default power is normal")
	var result := game.take_shot()
	_assert(not result.is_empty(), "shot returns data")
	_assert(game.strokes == 1, "one stroke recorded")
	_assert(game.distance_meters > 0.0, "ball moved forward")
	game.take_shot()
	_assert(game.strokes == 2, "second stroke recorded")
	print("All golf logic checks passed.")
	quit()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("Assertion failed: %s" % message)
		quit(1)
