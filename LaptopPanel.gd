extends Control
var is_open = false
var screen_height = 0.0
@onready var slide_tween: Tween

func _ready():
	screen_height = get_viewport_rect().size.y
	# laptop jest ustawiony pod ekranem na start
	position.y = screen_height
func _process(delta):
	var mouse_y = get_viewport().get_mouse_position().y
	var threshold = screen_height - 50
	# Otwieranie
	if mouse_y > threshold and not is_open:
		open_laptop()
	# Zamykanie
	elif mouse_y < (screen_height - 400) and is_open: 
		close_laptop()
func open_laptop():
	is_open = true
	if slide_tween: slide_tween.kill()
	slide_tween = create_tween()
	# Wyjeżdża do góry (na pozycję 0)
	slide_tween.tween_property(self, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC)
func close_laptop():
	is_open = false
	if slide_tween: slide_tween.kill()
	slide_tween = create_tween()
	# Chowa się pod ekran
	slide_tween.tween_property(self, "position:y", screen_height, 0.5).set_trans(Tween.TRANS_CUBIC)
