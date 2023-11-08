extends CharacterBody3D

@export var SPEED = 5
@export var SENSITIVITY = 0.02

@onready var head = $Head
@onready var camera = $Head/Camera

var movement_velocity: Vector3
var gravity := 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(_delta):
	handle_move()
	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-50), deg_to_rad(70))
		
	
func handle_move():
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var direction = (head.transform.basis * Vector3(input.x, 0 , input.y)).normalized()
	
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
