extends CharacterBody3D

@export var RUN_SPEED := 5
@export var WOLK_SPEED := 3
@export var CROUCH_SPEED := 2
@export var SENSITIVITY := 0.005
@export var JUMP_VELOCITY := 4.5
@export var JUMP_AMOUNT := 2
@export var JUMP_TRESHOLD := 0.65
@export var JUMP_ACC := 1.3
@export var PAD_SENSITIVITY := 0.3

@onready var player: CharacterBody3D = $"."
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera
@onready var idle_collision: CollisionShape3D = $IdleCollision
@onready var crouch_collision: CollisionShape3D = $CrouchCollision
@onready var ray_cast: RayCast3D = $RayCast

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
	'SHOOT': 'action_shoot',
	'PREV_WEAPON': 'action_prev_weapon',
	'NEXT_WEAPON': 'action_next_weapon',
}
const movement_list = {
	'LEFT': 'move_left',
	'RIGHT': 'move_right',
	'FORWARD': 'move_forward',
	'BACK': 'move_backward'
}
const weapon_hotkeys = {
	49: 0,
	50: 1
}

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var input_movement := Vector2.ZERO
var direction := Vector3.ZERO
var current_movement_state: MovementState = MovementState.Idle
var current_jump_amount := 0
var is_walk_btn_pressed := false
var is_crouch_btn_pressed := false
var timer := Timer.new()
var current_player_switch_signal := 'player_switch_prev_weapon'

const lerp_speed := 10.0

const emit_signal_list = {
	'SHOOT': 'player_shoot',
	'HOTKEY': 'player_shoot',
	'PREV': 'player_switch_prev_weapon',
	'NEXT': 'player_switch_next_weapon'
}
signal player_shoot
signal player_hotkey
signal player_switch_next_weapon
signal player_switch_prev_weapon

func _ready():
	setup_timer()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	toogle_switch(action_list.WALK)
	toogle_switch(action_list.CROUCH)
	set_movement_state()
	handler_jump(delta)
	handler_movement(delta)
	move_and_slide()

func _unhandled_input(event):
	camera_move(event)
	handler_hotkeys(event)
	action_switch_weapon(event)
	action_shoot()

func toogle_switch(action_name: StringName):
	var is_pressed = Input.is_action_just_pressed(action_name)
	var is_walk = action_name == action_list.WALK
	var is_crouch = action_name == action_list.CROUCH
	
	if is_pressed and is_walk:
		is_walk_btn_pressed = !is_walk_btn_pressed
	elif is_pressed and is_crouch:
		if ray_cast.is_colliding():
			is_crouch_btn_pressed = is_crouch_btn_pressed
		else:
			is_crouch_btn_pressed = !is_crouch_btn_pressed

func set_movement_state():
	input_movement = Input.get_vector(
		movement_list.LEFT,
		movement_list.RIGHT,
		movement_list.FORWARD,
		movement_list.BACK)
	var is_idle = input_movement == Vector2.ZERO
	
	if is_crouch_btn_pressed:
		current_movement_state = MovementState.Crouch
	elif is_walk_btn_pressed and !is_idle:
		current_movement_state = MovementState.Walk
	elif !is_walk_btn_pressed and !is_idle:
		current_movement_state = MovementState.Run
	elif is_idle:
		current_movement_state = MovementState.Idle

func handler_jump(delta):
	var is_pressed = Input.is_action_just_pressed(action_list.JUMP)
	
	if is_pressed and is_on_floor():
		velocity.y = JUMP_VELOCITY
		current_jump_amount += 1
	elif is_pressed and current_jump_amount < JUMP_AMOUNT:
		velocity.y = JUMP_VELOCITY * JUMP_ACC * current_jump_amount
		current_jump_amount += 1
	elif !is_on_floor():
		velocity.y -= JUMP_VELOCITY * delta * 2
	elif is_on_floor():
		current_jump_amount = 0

func handler_movement(delta):
	var move_transform = (player.transform.basis * Vector3(input_movement.x, 0 , input_movement.y)).normalized()
	direction = lerp(direction, move_transform, delta * lerp_speed)
	
	velocity.x = direction.x * get_current_speed()
	velocity.z = direction.z * get_current_speed()
	
	if current_movement_state == MovementState.Crouch:
		head.position.y = lerp(head.position.y, 1.3, delta * lerp_speed)
		idle_collision.disabled = true
		crouch_collision.disabled = false
	else:
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		idle_collision.disabled = false
		crouch_collision.disabled = true

func get_current_speed()-> int:
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
	return current_speed

func camera_move(event):
	if event is InputEventMouseMotion:
		player.rotate_y(-event.relative.x * SENSITIVITY)
		
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))

func handler_hotkeys(event):
	if event is InputEventKey and event.pressed and event.keycode in weapon_hotkeys:
		emit_signal(emit_signal_list.HOTKEY, weapon_hotkeys[event.keycode])

func action_shoot():
	if Input.is_action_just_pressed(action_list.SHOOT):
		emit_signal(emit_signal_list.SHOOT)

func setup_timer():
	add_child(timer)
	timer.wait_time = 0.08
	timer.one_shot = true
	timer.connect("timeout", _on_timer_timeout)

func _on_timer_timeout():
	emit_signal(current_player_switch_signal)

func action_switch_weapon(event):
	# For macbook
	if event is InputEventPanGesture:
		if event.delta.y > PAD_SENSITIVITY:
			current_player_switch_signal = emit_signal_list.NEXT
			timer.start()
		elif event.delta.y < -PAD_SENSITIVITY:
			current_player_switch_signal = emit_signal_list.PREV
			timer.start()
	# For PC
	else:
		if Input.is_action_just_pressed(action_list.NEXT_WEAPON):
			emit_signal(emit_signal_list.NEXT)
		elif Input.is_action_just_pressed(action_list.PREV_WEAPON):
			emit_signal(emit_signal_list.PREV)
