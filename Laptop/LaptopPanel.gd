extends Control

var is_open: bool = false
var is_animating: bool = false
var screen_height: float = 0.0
var can_toggle: bool = true 
var top_zone_height: float = 50.0 

@onready var slide_tween: Tween

func _ready():
	screen_height = get_viewport_rect().size.y
	position.y = -screen_height 
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size

func _process(delta):
	var mouse_y = get_viewport().get_mouse_position().y
	if mouse_y < top_zone_height:
		if can_toggle and not is_animating:
			toggle_laptop()
			can_toggle = false 
	else:
		can_toggle = true

func toggle_laptop():
	if is_open:
		close_laptop()
	else:
		open_laptop()

func open_laptop():
	is_animating = true
	if slide_tween: slide_tween.kill()
	slide_tween = create_tween()
	
	# zjeżdza w dół na sródek
	slide_tween.tween_property(self, "position:y", 720.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	await slide_tween.finished
	is_open = true
	is_animating = false
	print("laptop otwarty")

func close_laptop():
	is_animating = true
	if slide_tween: slide_tween.kill()
	slide_tween = create_tween()
	
	# wraca do góry
	slide_tween.tween_property(self, "position:y", -screen_height, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await slide_tween.finished
	is_open = false
	is_animating = false
	print("laptop zamknięty")
