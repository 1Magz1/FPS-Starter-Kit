extends Node3D

enum WEAPONS {
	Pistol,
	Shotgun
}

@onready var weapon_list = $".".get_children()
var current_weapon: Node3D = null
var current_index := 0

func _ready():
	var parent = get_tree().get_root().get_children()[0]
	var emitter = parent.get_node("Player")
	
	emitter.player_hotkey.connect(set_current_weapon)
	
	set_current_weapon(current_index)

func next_weapon():
	current_index = posmod(current_index + 1, weapon_list.size())
	set_current_weapon(current_index)

func prev_weapon():
	current_index = posmod(current_index - 1, weapon_list.size())
	set_current_weapon(current_index)

func set_current_weapon(index: int):
	disable_all()
	current_weapon = weapon_list[index]
	current_weapon.show()

func disable_all():
	for weapon in weapon_list:
		weapon.hide()
