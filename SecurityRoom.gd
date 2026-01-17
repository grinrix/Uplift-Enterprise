extends Node2D

@onready var camera = $Camera2D
@onready var background = $Background

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
	
	
	

func _process(delta):
	var mouse_x = get_viewport().get_mouse_position().x
	var screen_w = get_viewport_rect().size.x
	var mouse_percentage = clamp(mouse_x / screen_w, 0.0, 1.0)
	var target_x = mouse_percentage * max_camera_x
	camera.position.x = lerp(camera.position.x, target_x, delta * 2.0)
