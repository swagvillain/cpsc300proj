extends Control

static var room_x : String
static var room_z : String
static var user_objects : Dictionary = {}

@onready var object_type_dropdown : OptionButton = $MarginContainer/Menu_Vertical/ObjectTypeDropdown
@onready var x_input : LineEdit = $MarginContainer/Menu_Vertical/HBoxContainer/objectx
@onready var z_input : LineEdit = $MarginContainer/Menu_Vertical/HBoxContainer/objectz
@onready var add_object_button : Button = $AddObject

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_generate_pressed() -> void:
	get_tree().change_scene_to_file("res://user_room.tscn")
	
func _on_add_object_pressed() -> void:
	# Get the selected object type from the dropdown
	var selected_type = object_type_dropdown.get_selected_id()

	# Get the corresponding object name
	var object_name = object_type_dropdown.get_item_text(selected_type)

	# Get the X and Z scaling from the LineEdits
	var x = float(x_input.text)
	var y = 1
	var z = float(z_input.text)

	# Turn the scaling into a vector for use in the dictionary
	var scale = Vector3(x, y, z)

	# Add the object to the global user_objects dictionary
	add_object(user_objects, object_name, scale)

	# Clear the inputs, here we could also give feedback to the user
	x_input.clear()
	z_input.clear()
	

# Method to add objects to the user_objects dictionary
func add_object(userobjects : Dictionary, object_name : String, scale : Vector3):
	if not user_objects.has(object_name):
		# If the object type doesn't exist yet, create it
		# I think clever use of .get_or_add could do this too but idk
		user_objects[object_name] = [
			{"count": 1, "sizes": [scale]}  # Initialize with the first object and its scale
		]
	else:
		# Add the object to the existing list
		var object_data = user_objects[object_name]
		var count = object_data[0]["count"]
		object_data[0]["count"] = count + 1  # Increment the count of the object type
		object_data[0]["sizes"].append(scale)  # Add the new size to the list of sizes

	
func _on_room_x_text_changed(new_text: String) -> void:
	room_x = new_text

func _on_room_z_text_changed(new_text: String) -> void:
	room_z = new_text
