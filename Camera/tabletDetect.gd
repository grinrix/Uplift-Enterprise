extends Area2D

@onready var anim = $"../panel"       # Animacja
#@onready var app_ui = $"../LaptopApp" # Ekran
@onready var camera = get_parent()    # POBIERAMY KAMERĘ (RODZICA)

var is_open = false

func _ready():
	if not mouse_entered.is_connected(toggle_laptop):
		mouse_entered.connect(toggle_laptop)
	
	#if not anim.animation_finished.is_connected(on_anim_done):
		#anim.animation_finished.connect(on_anim_done)

	anim.visible = false
	anim.frame = 0
	#app_ui.visible = false

func toggle_laptop():
	# Zabezpieczenie przed klikaniem w trakcie ruchu
	if anim.is_playing():
		return

	if is_open:
		# --- ZAMYKANIE ---
		is_open = false
		
		# 1. Ukrywamy UI
		#app_ui.visible = false
		
		# 2. Start animacji w dół
		anim.play_backwards("default")
		
		# 3. ODBLOKOWUJEMY KAMERĘ (Można się ruszać)
		if camera:
			camera.is_locked = false
		
	else:
		# --- OTWIERANIE ---
		is_open = true
		
		# 1. Pokaż obudowę i start w górę
		anim.visible = true
		anim.play("default")
		
		# 2. ZABLOKUJ KAMERĘ (Stop ruchu)
		if camera:
			camera.is_locked = true

#func on_anim_done():
	#if is_open:
		#app_ui.visible = true
	#else:
		#anim.visible = false
