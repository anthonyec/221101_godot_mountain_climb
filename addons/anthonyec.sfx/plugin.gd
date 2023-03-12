@tool
extends EditorPlugin

const SETTINGS_PROPERTY = "addons/sfx/sounds"

func _enter_tree() -> void:
	add_autoload_singleton("SFX", "res://addons/anthonyec.sfx/sfx.gd")
	
	ProjectSettings.set_setting(SETTINGS_PROPERTY, "")
	ProjectSettings.set_initial_value(SETTINGS_PROPERTY, "")
	
	ProjectSettings.add_property_info({
		"name": SETTINGS_PROPERTY,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"hint_string": ""
	})

func _exit_tree() -> void:
	remove_autoload_singleton("SFX")
	
	if ProjectSettings.get_setting("addons/sfx/sounds", null):
		ProjectSettings.clear(SETTINGS_PROPERTY)
