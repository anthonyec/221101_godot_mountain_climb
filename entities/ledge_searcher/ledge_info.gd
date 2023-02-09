class_name LedgeInfo extends RefCounted

enum Error {
	NONE,
	NO_WALL_HIT,
	NO_FLOOR_HIT,
	BAD_FLOOR_ANGLE
}

# Why the ledge was not found.
@export var error: Error = Error.NONE

# Position of the edge.
@export var position: Vector3

# Direction of the edge facing outwards. It's a flattened version of the 
# floor normal.
@export var normal: Vector3

# Direction the edge flows facing right.
@export var direction: Vector3

# Direction of the wall facing outwards.
@export var wall_normal: Vector3

func has_error() -> bool:
	return error != Error.NONE

func get_error_message() -> String:
	return Error.keys()[error]
