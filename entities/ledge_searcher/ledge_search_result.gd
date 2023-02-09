class_name LedgeSearchResult extends RefCounted

@export var error: LedgeInfo.Error = LedgeInfo.Error.NONE
@export var points: Array[Vector3]

# The last successfully found ledge.
var last_ledge_info: LedgeInfo
