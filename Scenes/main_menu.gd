extends Control

func _ready():
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		var start = (event is InputEventKey and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER))
		var start_joy = (event is InputEventJoypadButton and (event.button_index == JOY_BUTTON_A or event.button_index == JOY_BUTTON_START))
		if start or start_joy:
			get_tree().change_scene_to_file("res://Scenes/World.tscn")
