extends Node3D

# Zmienne globalne, żeby mieć do nich dostęp
var is_dynamic_mode = false
@onready var bg_rect = $Hardware/SwitchViewport/StatusBackground
@onready var mode_label = $Hardware/SwitchViewport/ModeSwitch # Etykieta przycisku
@onready var elevator = find_child("Elevator", true, false)
@onready var switch_viewport = $Hardware/SwitchViewport
@onready var switch_sprite = $SwitchMode

func _ready():
	await get_tree().process_frame
	switch_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	switch_sprite.texture = switch_viewport.get_texture()
	
	# tryb windy
	bg_rect.color = Color.RED
	mode_label.text = "Mode: Heuristic"
	
	# generator i minigry
	var generator = find_child("Generator", true, false)
	var minigame_manager = find_child("MinigameManager", true, false)
	
	if elevator and generator:
		generator.power_status_changed.connect(elevator.set_power_state)
	if minigame_manager:
		minigame_manager.minigame_started.connect(func(): generator.minigame_active = true)
		minigame_manager.minigame_ended.connect(func(success): generator.minigame_active = false)

# klikanie trybu
func on_switch_clicked():
	is_dynamic_mode = !is_dynamic_mode
	mode_label.button_pressed = is_dynamic_mode
	
	if is_dynamic_mode:
		bg_rect.color = Color.GREEN
		mode_label.text = "Mode: Dynamic"
		if elevator: elevator.set_mode(true)
	else:
		bg_rect.color = Color.RED
		mode_label.text = "Mode: Heuristic"
		if elevator: elevator.set_mode(false)
