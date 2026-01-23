extends Control

@onready var title_label = $TitleLabel
@onready var score_label = $ScoreLabel
@onready var main_button = $MainButton

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Pokaż myszkę!
	
	# Pobieramy dane z Globala
	var config = Global.days_config.get(Global.current_day, Global.days_config[1])
	var target = config["target_score"]
	
	# Sprawdzamy czy to Game Over czy Wygrana
	if Global.is_game_over:
		setup_game_over()
	else:
		setup_day_complete(target)

func setup_game_over():
	title_label.text = "GAME OVER"
	title_label.modulate = Color.RED
	score_label.text = "Reason: " + Global.game_over_reason
	main_button.text = "Main Menu"
	main_button.pressed.connect(_on_menu_pressed)

func setup_day_complete(target):
	title_label.text = "DAYSHIFT'S OVER! - DAY " + str(Global.current_day)
	title_label.modulate = Color.GREEN
	score_label.text = "Score: " + str(Global.score) + " / Required: " + str(target) + "\nOcena: " + Global.get_grade()
	
	if Global.current_day >= 5:
		main_button.text = "Main Menu:"
		main_button.pressed.connect(_on_menu_pressed)
	else:
		main_button.text = "Start New Shift " + str(Global.current_day + 1)
		main_button.pressed.connect(_on_next_day_pressed)

func _on_next_day_pressed():
	# Przechodzimy do kolejnego dnia
	Global.current_day += 1
	Global.reset_stats() # Musimy zresetować punkty na nowy dzień!
	get_tree().change_scene_to_file("res://SecurityRoom3D.tscn")

func _on_menu_pressed():
	Global.current_day = 1
	Global.reset_stats()
	get_tree().change_scene_to_file("res://MainMenu.tscn")
	
	
