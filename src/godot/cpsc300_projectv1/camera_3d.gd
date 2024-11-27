
extends Camera3D

@export var acceleration = 25.0
@export var moveSpeed = 10.0
@export var mouseSpeed = 300.0

var velocity = Vector3.ZERO
var lookAngles = Vector2.ZERO
var initialized = false

func _ready():
	# Ensure mouse capture is set only once when the scene starts
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	lookAngles = Vector2(deg_to_rad(rotation.y), deg_to_rad(rotation.x))

func _process(delta):
	# Clamp the vertical rotation (pitch) to prevent flipping
	lookAngles.y = clamp(lookAngles.y, -PI / 2, PI / 2)

	# Apply rotation to the camera
	set_rotation(Vector3(lookAngles.y, lookAngles.x, 0))

	# Update movement direction
	var direction = updateDirection()
	if direction.length_squared() > 0:
		velocity += direction * acceleration * delta

	if velocity.length() > moveSpeed:
		velocity = velocity.normalized() * moveSpeed
		
	translate(velocity * delta)
		
func _input(event):
	# Mouse movement input for camera rotation
	if event is InputEventMouseMotion:
		lookAngles -= event.relative / mouseSpeed

func updateDirection():
	var dir = Vector3()
	if Input.is_action_pressed("move_forward"):
		dir += Vector3.FORWARD
	if Input.is_action_pressed("move_backward"):
		dir += Vector3.BACK
	if Input.is_action_pressed("move_left"):
		dir += Vector3.LEFT
	if Input.is_action_pressed("move_right"):
		dir += Vector3.RIGHT
	if Input.is_action_pressed("move_up"):
		dir += Vector3.UP
	if Input.is_action_pressed("move_down"):
		dir += Vector3.DOWN
	
	if dir == Vector3.ZERO:
		velocity = Vector3.ZERO
	
	return dir.normalized()
	
