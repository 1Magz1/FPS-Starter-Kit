extends CharacterBody3D

@export var SPEED = 5
@export var SENSITIVITY = 0.005
@export var JUMP_VELOCITY = 4.5
@export var DOUBLE_JUMP_TRESHOLD = 0.65
@export var DOUBLE_JUMP_ACC = 1.3

@onready var head = $Head
@onready var camera = $Head/Camera

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	handle_jump(delta)
	handle_movement()
	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(80))

func handle_movement():
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var direction = (head.transform.basis * Vector3(input.x, 0 , input.y)).normalized()
	
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

func handle_jump(delta):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_just_pressed("jump") and velocity.y >= JUMP_VELOCITY * DOUBLE_JUMP_TRESHOLD:
		velocity.y = JUMP_VELOCITY * DOUBLE_JUMP_ACC
	elif not is_on_floor():
		velocity.y -= JUMP_VELOCITY * delta
