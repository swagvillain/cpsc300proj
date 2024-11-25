extends Node3D

# Room dimensions (number of tiles)
# This is what we should replace with the user input, 
# walls could be a const 4 though, higher looks kinda weird
# and isn't needed by the program
var length : int = 30   
var width : int = 20   
var height : int = 4

# GridMap and MeshLibrary reference
@onready var gridmap = $GridMap

# MeshLibrary indices
var floor_index : int = 0  # Floor tile index
var wall_index : int = 1   # Wall tile index

# Wall height

func _ready():
	generate_room()

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
