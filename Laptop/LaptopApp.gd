extends Control

# referencje
@onready var black_screen = $ColorRect
# musisz dodać ten node w scenie (zwykły Control)
@onready var minigame_container = $MinigameContainer 

@onready var game_manager = get_tree().root.find_child("GameManager", true, false)
@onready var minigame_manager = get_tree().root.find_child("MinigameManager", true, false)
@onready var tablet_detect = get_tree().root.find_child("TabletDetect", true, false)

var is_task_ready = false

func _ready():
	# startujemy z czarnym ekranem
	black_screen.visible = true
	
	if game_manager:
		game_manager.task_assigned.connect(_on_new_task)

func _process(delta):
	# jeśli tablet jest widoczny i mamy zadanie -> uruchom
	if is_visible_in_tree():
		if is_task_ready and minigame_container.get_child_count() == 0:
			start_task()

# szef wysłał zadanie
func _on_new_task():
	print("TABLET: Przyszło powiadomienie!")
	is_task_ready = true
	# tu możesz dodać dźwięk powiadomienia

# gracz otworzył tablet
func start_task():
	is_task_ready = false
	black_screen.visible = false
	
	if minigame_manager:
		# podłączamy wynik jednorazowo
		if not minigame_manager.minigame_ended.is_connected(_on_minigame_result):
			minigame_manager.minigame_ended.connect(_on_minigame_result)
			
		minigame_manager.start_minigame(minigame_container)

# wynik gry
func _on_minigame_result(success: bool):
	# odłączamy sygnał
	if minigame_manager.minigame_ended.is_connected(_on_minigame_result):
		minigame_manager.minigame_ended.disconnect(_on_minigame_result)
		
	# informujemy managera że koniec cyklu
	if game_manager:
		game_manager.complete_task_cycle()
		
	if success:
		# sukces -> zamykamy tablet
		close_tablet()
	else:
		# porażka -> strajk i czarny ekran
		Global.add_strike("Zawalona minigra")
		black_screen.visible = true
		close_tablet()

# funkcja zamykająca
func close_tablet():
	if tablet_detect:
		tablet_detect.toggle_laptop()
