extends Node3D

# Room dimensions (number of tiles)
# This is what we should replace with the user input, 
# walls could be a const 4 though, higher looks kinda weird
# and isn't needed by the program

var length : int = int(Generate.room_x)  
var width : int =  int(Generate.room_z)  
var height : int = 4

var user_objects = Generate.user_objects
var placed_objects : Array = []  # Store references to placed MeshInstance3D objects

var mesh_library : Dictionary = {}  # To store meshes by name
var grid_size : float = 1  # Size of each grid cell, currently works best at 1, 
							# This is something I want to adjust, see later in placement

@onready var gridmap : GridMap = $GridMap  # Reference to the GridMap child

func _ready():
	# Load the mesh library from the MeshLibraryScene
	load_mesh_library()
	
	#place floors and walls
	generate_room()

	# Place all objects based on user input
	# This is a temporary function, likely to 
	# be replaced with either the random placement 
	# which I haven't figured out the bounding box stuff for yet
	# or the AI placement depending on how we do it
	place_objects_based_on_input()

# Load meshes into the library
func load_mesh_library():
	var library_instance = $MeshLibrarySource
	for child in library_instance.get_children():
		if child is MeshInstance3D:
			mesh_library[child.name] = child.mesh

	# Optional, remove the library instance from the scene as we just need the meshes
	library_instance.queue_free()

func place_object(object_name: String, grid_pos: Vector3, scale: Vector3):
	if not mesh_library.has(object_name):
		print("Object name not found in library!")
		return
	
	# Snap position to the grid and check if it's valid
	grid_pos = snap_to_grid(grid_pos)
	
	# If the position is not valid, do not place the object
	if not valid_position(grid_pos, scale):
		return
	
	# Create a new MeshInstance3D
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh_library[object_name]
	
	# Apply the scale
	mesh_instance.scale = scale
	
	# Set the position
	mesh_instance.position = grid_pos
	
	# Add the object to the scene
	add_child(mesh_instance)
	
	# Compute and store the transformed AABB
	var transformed_aabb = get_scaled_aabb(mesh_instance)
	placed_objects.append({"instance": mesh_instance, "aabb": transformed_aabb})


# Function to place objects randomly
func place_objects_based_on_input():
	var total_objects_placed = 0

	# Loop through all objects to place
	for object_name in user_objects.keys():
		var object_data = user_objects[object_name]
		var count = object_data[0]["count"]
		var sizes = object_data[0]["sizes"]

		# Place each object based on the count and sizes
		for i in range(count):
			var object_size = sizes[i % sizes.size()]  # Cycle through sizes if more objects than sizes
			var success = false
			
			# Try to place the object randomly until it is placed or we run out of attempts
			for attempt in range(100):  # Try 100 times (you can adjust this limit)
				# Generate a random position within the bounds of the room, considering the object size
				var random_x = randf_range(1, length * grid_size - object_size.x * grid_size)
				var random_z = randf_range(1, width * grid_size - object_size.z * grid_size)

				# Generate the grid position
				var object_position = Vector3(random_x, grid_size*2, random_z)  			
				# Try to place the object at this position
				if valid_position(object_position, object_size):
					place_object(object_name, object_position, object_size)
					total_objects_placed += 1
					success = true
					break  # Break the loop if the object is successfully placed

			# If we couldn't place the object, print a message (optional)
			if not success:
				print("Failed to place object:", object_name)

# Function to check if an object can be placed at a given position
func valid_position(grid_pos : Vector3, scale : Vector3) -> bool:
	# Check if the object is inside the bounds of the room
	if grid_pos.x < 1 or grid_pos.x + scale.x * grid_size > length * grid_size:
		return false	
	if grid_pos.z < 1 or grid_pos.z + scale.z * grid_size > width * grid_size:
		return false
	
	
	# Compute the test AABB for the object being placed
	var test_aabb = AABB(grid_pos, scale * grid_size)
	
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


# Function to snap a position to the grid
func snap_to_grid(grid_pos : Vector3) -> Vector3:
	# This function rounds the position to the nearest grid position
	# We scale it by grid_size for the snapping to the grid.
	return Vector3(round(grid_pos.x / grid_size) * grid_size, grid_pos.y, round(grid_pos.z / grid_size) * grid_size)


# MeshLibrary indices
var floor_index : int = 0  # Floor tile index
var wall_index : int = 1   # Wall tile index


# Function to generate the room (floor + walls)
func generate_room():
	# place tiles in length X width and
	# place walls around the perimeter (edges)
	for x in range(length + 2):  # Adding 2 to each allows us to creating a boxed perimeter around floor
		for z in range(width + 2): 
			if is_edge(x, z):  # Check if it's an edge position
				for y in range(height):
					var wall_position = Vector3i(x, y, z)  # Set height (y) of the cell
					gridmap.set_cell_item(wall_position, wall_index)  # Place the wall 
			else:
				var floor_position = Vector3i(x, 0, z) # Set x and z of the cell
				gridmap.set_cell_item(floor_position, floor_index)  # Place floor tiles 

# Check if the position is on the edge of the grid (+1 accounts for the extended dimensions)
func is_edge(x: int, z: int) -> bool:
	return x == 0 or x == length+1 or z == 0 or z == width+1
