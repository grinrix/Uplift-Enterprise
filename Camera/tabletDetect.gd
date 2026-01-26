extends Area2D

# Zmienne
var laptop_panel: Control
var tween: Tween
var is_open: bool = false
# Ustaw tutaj wysokość swojego ekranu w grze (zazwyczaj 720 lub 1080)
var screen_height: float = 720.0 

func _ready() -> void:
	# Podłączamy sygnał najechania myszką
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	
	# Szukamy panelu
	laptop_panel = get_tree().root.find_child("LaptopPanel", true, false)
	
	if laptop_panel:
		# Pobieramy faktyczną wysokość ekranu gry
		screen_height = get_viewport_rect().size.y
		# Ustawiamy panel w pozycji startowej (schowany na dole)
		# Dzięki temu nie musisz tego idealnie ustawiać w edytorze
		laptop_panel.position.y = screen_height
		print("TabletDetect: Panel znaleziony. Wysokość ekranu: ", screen_height)
	else:
		print("TabletDetect BŁĄD: Nie znaleziono LaptopPanel!")

func _on_mouse_entered() -> void:
	print("Myszka najechała na tablet!")
	if not is_open:
		move_laptop(true)

# Funkcja wykonująca ruch
func move_laptop(open: bool):
	if not laptop_panel: return
		
	is_open = open
	
	# Resetujemy poprzednią animację
	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if open:
		print("Animacja: Otwieranie...")
		# Jedzie do góry (pozycja Y = 0)
		tween.tween_property(laptop_panel, "position:y", 0.0, 0.6)
		
		# Logika w panelu (opcjonalne)
		if "is_open" in laptop_panel: laptop_panel.is_open = true
			
	else:
		print("Animacja: Zamykanie...")
		# Jedzie na dół (pozycja Y = 720)
		tween.tween_property(laptop_panel, "position:y", screen_height, 0.6)
		
		if "is_open" in laptop_panel: laptop_panel.is_open = false

# Zamykanie ESC
func _input(event):
	if is_open and event.is_action_pressed("ui_cancel"):
		move_laptop(false)
