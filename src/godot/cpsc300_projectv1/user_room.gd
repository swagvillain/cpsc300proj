extends Node3D

# Room dimensions (number of tiles)
# This is what we should replace with the user input, 
# walls could be a const 4 though, higher looks kinda weird
# and isn't needed by the program

var length : int = int(Generate.room_x)  
var width : int =  int(Generate.room_z)  
var height : int = 4

var user_objects = Generate.user_objects

var mesh_library : Dictionary = {}  # To store meshes by name
var grid_size : float = 2.0  # Size of each grid cell, currently works best at 2, 
							# This is something I want to adjust, see later in placement

# User input data: number of objects and their sizes
# The y variable in Vector3 can stay constant as 1
# doesn't really matter what the heights of the objects are

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

# Function to place objects """"based on user input"""" (trust me bro)
func place_objects_based_on_input():
	var position_offset = Vector3(2, 1, 2)  # Start position for placing objects
	for object_name in user_objects.keys():
		var object_data = user_objects[object_name]
		var count = object_data[0]["count"]
		var sizes = object_data[0]["sizes"]

		# Place each object based on the count and sizes
		# Either in here or in the place_object function is where the 
		# adjustments to how things are placed should happen... 
		for i in range(count):
			var object_size = sizes[i % sizes.size()]  # Cycle through sizes if more objects than sizes
			place_object(object_name, position_offset, object_size)
			
			# Increment the position for the next object (current lazy solution)
			position_offset.x += grid_size * 2  # This is where that grid size comes into play, I don't like it 

# Function to place an object at a grid position with a specific scale
func place_object(object_name : String, grid_pos : Vector3, scale : Vector3):
	if not mesh_library.has(object_name):
		print("Object name not found in library!")
		return
	
	# Create a new MeshInstance3D
	var mesh_instance = MeshInstance3D.new()
	# Assign the mesh from the library
	mesh_instance.mesh = mesh_library[object_name]  
	
	# Apply the scale
	mesh_instance.scale = scale
	
	# Snapping the position to the grid
	# Can't add the mesh directly to the grid map cell
	# because the set_cell_item method works on meshes currently
	# in the gridmaps mesh library, not any mesh (lmao, why are we using gridmap T_T)
	mesh_instance.position = snap_to_grid(grid_pos)
	
	# Adding the object to the scene makes it visible
	add_child(mesh_instance)

# Function to snap a position to the grid
func snap_to_grid(grid_pos : Vector3) -> Vector3:
	return grid_pos * grid_size # again see grid size here, just works for scaling

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
