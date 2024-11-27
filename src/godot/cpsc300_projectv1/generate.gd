extends Control

static var room_x : String
static var room_z : String
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_generate_pressed() -> void:
	get_tree().change_scene_to_file("res://user_room.tscn")

func _on_room_x_text_changed(new_text: String) -> void:
	room_x = new_text

func _on_room_z_text_changed(new_text: String) -> void:
	room_z = new_text
