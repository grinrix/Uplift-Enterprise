extends Node2D

signal minigame_started
signal minigame_ended(success: bool)

# lista minigier
var minigames_list = [
	"res://MinigamesSystem/Minigames/CalibrationGame.tscn" 
]

var current_minigame_node = null

# startuje minigrę w podanym kontenerze (tablet)
func start_minigame(target_container):
	if minigames_list.is_empty(): return
	
	print("MINIGAME MANAGER: Start gry w tablecie")
	emit_signal("minigame_started")
	
	var random_path = minigames_list.pick_random()
	var game_scene = load(random_path)
	
	current_minigame_node = game_scene.instantiate()
	
	# dodajemy do kontenera w tablecie
	target_container.add_child(current_minigame_node)
	
	# dopasowanie rozmiaru
	if current_minigame_node is Control:
		current_minigame_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# podłączamy sygnał końca
	if current_minigame_node.has_signal("finished"):
		current_minigame_node.finished.connect(_on_minigame_finished)

func _on_minigame_finished(success: bool):
	print("MINIGAME MANAGER: Koniec gry, wynik: ", success)
	emit_signal("minigame_ended", success)
	
	if current_minigame_node:
		current_minigame_node.queue_free()
		current_minigame_node = null
