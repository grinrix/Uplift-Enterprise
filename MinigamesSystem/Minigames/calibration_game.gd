extends Control

signal finished(success: bool)

# parametry
var clicks_needed: int = 10
var current_clicks: int = 0
var time_limit: float = 5.0

@onready var progress_bar = $ProgressBar
@onready var button = $Button
@onready var timer = $Timer

func _ready():
	progress_bar.max_value = clicks_needed
	progress_bar.value = 0
	
	# start czasu
	timer.wait_time = time_limit
	timer.one_shot = true
	timer.timeout.connect(_on_time_out)
	timer.start()
	
	# Podłączenie przycisku
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	current_clicks += 1
	progress_bar.value = current_clicks
	
	# sprawdzamy wygraną
	if current_clicks >= clicks_needed:
		print("Kalibracja udana!")
		finished.emit(true) # wygrana
		button.disabled = true 

func _on_time_out():
	print("Czas minął! Awaria!")
	finished.emit(false) # przegrana
