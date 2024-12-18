extends Node3D

var length : int = int(Generate.room_x)
var width : int = int(Generate.room_z)
var height : int = 4

var room_centroid : Vector3 = Vector3(float(length)/2, float(width)/2, float(height)/2)

var user_objects = Generate.user_objects
var placed_objects : Array = []  # Store references to placed MeshInstance3D objects

var mesh_library : Dictionary = {}  # To store meshes by name

var floor_index : int = 0  # Floor tile index
var wall_index : int = 1   # Wall tile index

var reloads : int = 0

@onready var gridmap : GridMap = $GridMap  # Reference to the GridMap child


func _ready():
	load_mesh_library()
	
	#place floors and walls
	generate_room()
	
	attempt_object_placement()
	var query = FileAccess.open("res://query.txt", FileAccess.WRITE)
	var consult_output = FileAccess.open("res://consult_output.txt", FileAccess.READ)
	
	for object in placed_objects:
		
		print_object_to_file(object)
		print("now executing")
		# This is the error line. The Godot is not properly calling the python script.
		# Unsure of how to make OS.execute properly function in Godot, would have liked this
		# in the final project
		OS.execute("src/python/consult.py", []) 
		print("get executed")
		var consult_query_content = consult_output.get_as_text().strip_edges()  # Get content and strip extra spaces/newlines
		
		while consult_query_content == "0":
			print("didnt like your placement")
			if reloads < 100:
				reloads += 1
				print("about to restart")
				reset_placement()
				print("back to the beninging")
			else :
				print("The model couldn't accept your objects, they're placed randomly")
				break
	
	query.close
	consult_output.close
	

func print_object_to_file(object: Dictionary):
	var file = FileAccess.open("res://query.txt", FileAccess.WRITE)
	var mesh_instance = object["instance"]
	var transformed_aabb = get_scaled_aabb(mesh_instance)
	
	# Extract the centroid (position) and scale from the AABB
	var position = transformed_aabb.position
	var scale = transformed_aabb.size
	
	#All the multiplication is basically unit scaling 
	file.store_string(str(position.x * -20) + "\n")
	file.store_string(str(position.z * -20) + "\n")
	file.store_string(str(position.y * 1200) + "\n")
	
	file.store_string(str(scale.x * 250) + "\n")
	file.store_string(str(scale.z * 250) + "\n")
	file.store_string(str(scale.y * 250) + "\n")
	
	file.store_string("0\n")
	file.store_string("600\n")
	
	file.close()

# Load meshes into the library
func load_mesh_library():
	var library_instance = $MeshLibrarySource
	for child in library_instance.get_children():
		if child is MeshInstance3D:
			mesh_library[child.name] = child.mesh

	# Optional, remove the library instance from the scene as we just need the meshes
	library_instance.queue_free()


# Function to place objects randomly
func attempt_object_placement():
	# Loop through all objects to place
	for object_name in user_objects.keys():
		var object_data = user_objects[object_name]
		var count = object_data[0]["count"]
		var sizes = object_data[0]["sizes"]

		# Place each object based on the count and sizes
		for i in range(count):
			var object_size = sizes[i % sizes.size()]  # Cycle through sizes if more objects than sizes
			var success = false
			
			for attempt in range(100):  # Try 100 times
				var object_position = Vector3(randf_range((object_size.x / 2) + 1, length - (object_size.x / 2) + 1), 
				(object_size.y / 2) + 1, randf_range((object_size.z / 2) + 1, width - (object_size.z / 2) + 1))
				# The issue that shows up when placing a weirdly y scaled object comes from slight size differences in the base meshes
				
				if valid_position(object_position, object_size):
					place_object(object_name, object_position, object_size)
					success = true
					break  # Break the loop if the object is successfully placed
					
				if success:
					break  # Break the outer loop if placement was successful
					
			# If we couldn't place the object, print a message (optional)
			if not success:
				print("Failed to place object:", object_name)


func place_object(object_name: String, grid_pos: Vector3, scale: Vector3):
	if not mesh_library.has(object_name):
		print("Object name not found in library")
		return
		
	grid_pos = snap_to_grid(grid_pos)
	
	# If the position is not valid, do not place the object
	if not valid_position(grid_pos, scale):
		return
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh_library[object_name]
	
	mesh_instance.scale = scale
	
	mesh_instance.position = grid_pos
	
	# Add the object to the scene makes it visible
	add_child(mesh_instance)
	
	# Compute and store the transformed AABB (I dont think it is perfectly fit to the object)
	var transformed_aabb = get_scaled_aabb(mesh_instance)
	
	placed_objects.append({"instance": mesh_instance, "aabb": transformed_aabb})


# Function to check if an object can be placed at a given position
func valid_position(grid_pos : Vector3, scale : Vector3) -> bool:
	# Check if the object is inside the bounds of the room
	if grid_pos.x < 1 or grid_pos.x + scale.x > (length + 1) :
		return false	
	if grid_pos.z < 1 or grid_pos.z + scale.z  > (width + 1) :
		return false
	
	# Compute the test AABB for the object being placed
	var test_aabb = AABB(grid_pos, scale)
	
	# Check for overlap with other objects
	for object_data in placed_objects:
		if object_data["aabb"].intersects(test_aabb):
			return false
	
	return true


func get_scaled_aabb(object: MeshInstance3D) -> AABB:
	var local_aabb = object.get_aabb()  # Local AABB of the mesh
	# I don't really understand global transforms, but from what i have seen
	# it seems that the objects AABB doesn't get updated properly when scaled
	# unless you perform a transform. This could be wrong somewhere
	var global_position = object.global_transform.origin  # Global position of the object
	var scaled_size = local_aabb.size * object.scale  # Scale the size of the AABB
	
	return AABB(global_position, scaled_size)  # Return adjusted AABB


func snap_to_grid(grid_pos : Vector3) -> Vector3:
	# This function rounds the position to the nearest grid position
	# We scale it by grid_size for the snapping to the grid.
	return Vector3(grid_pos.x, grid_pos.y, grid_pos.z)


func reset_placement():
	for object_data in placed_objects:
		object_data["instance"].queue_free()  # Remove object from scene
		
	placed_objects.clear()

	attempt_object_placement()

# Function to generate the room (floor + walls)
func generate_room():
	# place tiles in length X width and
	# place walls around the perimeter (edges)
	for x in range(length + 2):  # Adding 2 to each allows us to creating a boxed perimeter around floor
		for z in range(width + 2): 
			if is_edge(x, z): 
				for y in range(height):
					var wall_position = Vector3i(x, y, z)
					gridmap.set_cell_item(wall_position, wall_index)
			else:
				var floor_position = Vector3i(x, 0, z) # Set x and z of the cell
				gridmap.set_cell_item(floor_position, floor_index)  # Place floor tiles 


# Check if the position is on the edge of the grid (+1 accounts for the extended dimensions)
func is_edge(x: int, z: int) -> bool:
	return x == 0 or x == length+1 or z == 0 or z == width+1
