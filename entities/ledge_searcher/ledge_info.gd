class_name LedgeInfo extends RefCounted

enum Error {
	NONE,
	NO_WALL_HIT,
	NO_FLOOR_HIT,
	NO_HAND_SPACE,
	BAD_FLOOR_ANGLE,
	BAD_WALL_ANGLE
}

# Why the ledge was not found.
var error: LedgeInfo.Error = LedgeInfo.Error.NONE

# Position of the edge.
var position: Vector3

# Direction of the edge facing outwards. It's a flattened version of the 
# floor normal.
var normal: Vector3

# Direction the edge flows facing right.
var direction: Vector3

# Direction of the wall facing outwards.
var wall_normal: Vector3
var floor_normal: Vector3

func has_error() -> bool:
	return error != Error.NONE

func get_error_message() -> String:
	return Error.keys()[error]
