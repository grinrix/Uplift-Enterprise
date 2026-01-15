extends Node2D

@onready var camera = $Camera2D
@onready var background = $Background
@onready var clock = $Clock

# parametry
var sensitivity: float = 0.05
# granice
var max_camera_x: float = 0.0

# zegar
var shift_duration: float = 270.0 
var time_left: float = 270.0
var shift_active: bool = true

func _ready():
	# jak daleko można ruszyć kamerą
	var viewport_width = get_viewport_rect().size.x
	var bg_width = background.texture.get_width()
	max_camera_x = bg_width - viewport_width
	if max_camera_x < 0: max_camera_x = 0
	var elevator_node = $ElevetorCam/SubViewport/GameMap/Elevator
	$Generator.power_status_changed.connect(elevator_node.set_power_state)
	
	
	var minigame_manager = $Minigames/SubViewport/MinigameManager
	var generator = $Generator # (lub $PowerGenerator)
	
	# ŁĄCZYMY SYGNAŁY
	# Gdy gra startuje -> ustaw w generatorze minigame_active = true
	minigame_manager.minigame_started.connect(func(): generator.minigame_active = true)
	
	# Gdy gra się kończy -> ustaw w generatorze minigame_active = false
	# (ignorujemy wynik success/fail w kontekście blokady, odblokowujemy zawsze)
	minigame_manager.minigame_ended.connect(func(success): generator.minigame_active = false)
	
	# Tutaj w przyszłości obsłużymy też "Wylanie z pracy" jeśli success == false
	minigame_manager.minigame_ended.connect(_on_minigame_result)

func _on_minigame_result(success: bool):
	if not success:
		print("Gracz zawalił zadanie! Ostrzeżenie!")
		# Tu dodasz licznik błędów (np. 3 błędy = Game Over)

func _process(delta):
	var mouse_x = get_viewport().get_mouse_position().x
	var screen_w = get_viewport_rect().size.x
	var mouse_percentage = clamp(mouse_x / screen_w, 0.0, 1.0)
	var target_x = mouse_percentage * max_camera_x
	camera.position.x = lerp(camera.position.x, target_x, delta * 2.0)
	# zegar
	if shift_active:
		# odliczanie
		time_left -= delta
		# formatowanie czasu
		var minutes = floor(time_left / 60)
		var seconds = int(time_left) % 60
		clock.text = "%02d:%02d" % [minutes, seconds]
		# koniec zmiany
		if time_left <= 0:
			end_shift()

func end_shift():
	shift_active = false
	clock.text = "00:00"
	print("KONIEC ZMIANY! PODSUMOWANIE...")
	# TODO: KOLEJNE POZIOMY
