extends Node3D

func _ready():
	var parent = get_tree().get_root().get_children()[0]
	var emitter = parent.get_node("Player")
	emitter.player_shoot.connect(shoot)

func shoot():
	if(visible):
		print("shoot")
