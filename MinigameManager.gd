extends Node2D

signal minigame_started
signal minigame_ended(success: bool)

# lista minigier
var minigames_list = [
	"res://Minigames/CalibrationGame.tscn" 
]

@onready var spawn_timer = $SpawnTimer
var current_minigame_node = null

func _ready():
	# BYŁO: spawn_timer.wait_time = randf_range(10.0, 20.0)
	
	# ZMIEŃ NA:
	spawn_timer.wait_time = 1.0 # Tylko 1 sekunda na testy!
	
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_timer_timeout)
	spawn_timer.start()

func _on_timer_timeout():
	spawn_random_minigame()

func spawn_random_minigame():
	if minigames_list.is_empty(): return
	
	print("!!! AWARIA SYSTEMU - MINIGRA START !!!")
	emit_signal("minigame_started")
	
	var random_path = minigames_list.pick_random()
	var game_scene = load(random_path)
	
	current_minigame_node = game_scene.instantiate()
	add_child(current_minigame_node)
	
	# --- POPRAWKA: Ręczne ustawienie rozmiaru ---
	if current_minigame_node is Control:
		# Pobieramy rozmiar Viewporta (czyli 640x480)
		var viewport_size = get_viewport_rect().size
		
		# Wymuszamy ten rozmiar na minigrze
		current_minigame_node.size = viewport_size
		current_minigame_node.position = Vector2(0, 0)
	# ---------------------------------------------
	
	if current_minigame_node.has_signal("finished"):
		current_minigame_node.finished.connect(_on_minigame_finished)
	

func _on_minigame_finished(success: bool):
	print("Minigra zakończona. Sukces: ", success)
	emit_signal("minigame_ended", success)
	
	# usuwamy minigrę
	if current_minigame_node:
		current_minigame_node.queue_free()
		current_minigame_node = null
	
	# resetujemy timer
	spawn_timer.wait_time = randf_range(10.0, 20.0)
	spawn_timer.start()
