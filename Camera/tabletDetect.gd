extends Area2D

@onready var anim = $"../panel"
@onready var app_ui = $"../MinigameManager"
@onready var camera = get_parent()

var is_open = false

func _ready():
	if not mouse_entered.is_connected(toggle_laptop):
		mouse_entered.connect(toggle_laptop)
	
	if not anim.animation_finished.is_connected(on_anim_done):
		anim.animation_finished.connect(on_anim_done)

	anim.visible = false
	anim.frame = 0
	app_ui.visible = false

func toggle_laptop():
	if anim.is_playing():
		return

	if is_open:
		is_open = false
		app_ui.visible = false 
		anim.play_backwards("default")
		
		if camera:
			camera.is_locked = false
		
	else:
		is_open = true
		anim.visible = true
		anim.play("default")
		
		if camera:
			await get_tree().create_timer(0.5).timeout
			camera.is_locked = true

func on_anim_done():
	if is_open:
		await get_tree().create_timer(0.1).timeout
		if is_open: 
			app_ui.visible = true
	else:
		anim.visible = false
