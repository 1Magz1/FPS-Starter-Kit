extends CharacterBody3D

@export var RUN_SPEED = 5
@export var WOLK_SPEED = 3
@export var CROUCH_SPEED = 2
@export var SENSITIVITY = 0.005
@export var JUMP_VELOCITY = 4.5
@export var DOUBLE_JUMP_TRESHOLD = 0.65
@export var DOUBLE_JUMP_ACC = 1.3

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera

enum MovementState {
	Idle,
	Walk,
	Run,
	Crouch
}
const action_list = {
	'WALK': 'action_walk',
	'CROUCH': 'action_crouch',
	'JUMP': 'action_jump',
}
const movement_list = {
	'LEFT': 'move_left',
	'RIGHT': 'move_right',
	'FORWARD': 'move_forward',
	'BACK': 'move_back'
}
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var input_movement = Vector2.ZERO
var current_movement_state = MovementState.Idle
var is_walk_btn_pressed = false
var is_crouch_btn_pressed = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	toogle_switch(action_list.WALK)
	toogle_switch(action_list.CROUCH)
	set_movement_state()
	handle_jump(delta)
	handle_movement()
	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(80))

func handle_movement():
	var input := Input.get_vector(
		movement_list.LEFT,
		movement_list.RIGHT,
		movement_list.FORWARD,
		movement_list.BACK)
	var direction = (head.transform.basis * Vector3(input.x, 0 , input.y)).normalized()
	var current_speed = 0
	
	match current_movement_state:
		MovementState.Idle:
			current_speed = 0
		MovementState.Walk:
			current_speed = WOLK_SPEED
		MovementState.Run:
			current_speed = RUN_SPEED
		MovementState.Crouch:
			current_speed = CROUCH_SPEED
	
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

func handle_jump(delta):
	if Input.is_action_just_pressed(action_list.JUMP) and is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_just_pressed(action_list.JUMP) and velocity.y >= JUMP_VELOCITY * DOUBLE_JUMP_TRESHOLD:
		velocity.y = JUMP_VELOCITY * DOUBLE_JUMP_ACC
	elif not is_on_floor():
		velocity.y -= JUMP_VELOCITY * delta

func set_movement_state():
	input_movement = Input.get_vector(
		movement_list.LEFT,
		movement_list.RIGHT,
		movement_list.FORWARD,
		movement_list.BACK)
	var is_idle = input_movement == Vector2.ZERO
	
	if is_idle:
		current_movement_state = MovementState.Idle
	elif is_walk_btn_pressed and !is_idle:
		current_movement_state = MovementState.Walk
	elif is_crouch_btn_pressed and !is_idle:
		current_movement_state = MovementState.Crouch
	elif !is_walk_btn_pressed and !is_idle:
		current_movement_state = MovementState.Run

func toogle_switch(action_name: StringName):
	if Input.is_action_just_pressed(action_name) and action_name == action_list.WALK:
		is_walk_btn_pressed = !is_walk_btn_pressed
	elif Input.is_action_just_pressed(action_name) and action_name == action_list.CROUCH:
		is_crouch_btn_pressed = !is_crouch_btn_pressed
