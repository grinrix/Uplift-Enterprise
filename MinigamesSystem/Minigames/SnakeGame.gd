extends Control

signal finished(success: bool)

@export var snake_scene: PackedScene

const CELL_SIZE = 50
const GRID_SIZE = Vector2(15, 9) # 750x500
var OFFSET = Vector2.ZERO    # centrowanie

var score = 0
var snake_body = []  # pozycje logiczne
var snake_parts = [] # obiekty wizualne
var direction = Vector2.RIGHT
var next_dir = Vector2.RIGHT
var food_pos = Vector2.ZERO
var timer = Timer.new()

func _ready():
	# obliczamy wymiary siatki w pikselach
	var grid_px_width = GRID_SIZE.x * CELL_SIZE
	var grid_px_height = GRID_SIZE.y * CELL_SIZE
	
	# Pobieramy wymiary i pozycję bg
	var bg = $bg
	var bg_size = Vector2.ZERO
	var bg_top_left = Vector2.ZERO
	
	if bg.texture:
		# Sprite bierze rozmiar z tekstury * skala
		bg_size = bg.texture.get_size() * bg.scale
		
		# Sprawdzamy czy Sprite jest wyśrodkowany (Centered)
		if bg.centered:
			bg_top_left = bg.position - (bg_size / 2.0)
		else:
			bg_top_left = bg.position
	else:
		print("BŁĄD: Sprite 'bg' nie ma ustawionej tekstury!")
		return
	
	# margines sprite'a
	var margin_x = (bg_size.x - grid_px_width) / 2
	var margin_y = (bg_size.y - grid_px_height) / 2
	
	# punkt startowy rysowania
	OFFSET = bg_top_left + Vector2(margin_x, margin_y)
	# timer ruchu
	add_child(timer)
	timer.wait_time = 0.25
	timer.timeout.connect(_move_step)
	
	# buttons
	if has_node("Controls"):
		$Controls/ButtonUp.pressed.connect(func(): change_dir(Vector2.UP))
		$Controls/ButtonDown.pressed.connect(func(): change_dir(Vector2.DOWN))
		$Controls/ButtonLeft.pressed.connect(func(): change_dir(Vector2.LEFT))
		$Controls/ButtonRight.pressed.connect(func(): change_dir(Vector2.RIGHT))
	
	start_game()

func start_game():
	score = 0
	direction = Vector2.RIGHT
	next_dir = Vector2.RIGHT
	update_ui("APPEL: 0/5")
	
	# sprzątanie
	for part in snake_parts: part.queue_free()
	snake_parts.clear()
	snake_body = [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)]
	
	# tworzenie startowego węża
	for pos in snake_body:
		create_visual_part(pos)
		
	spawn_food()
	timer.start()

func create_visual_part(grid_pos):
	var part = snake_scene.instantiate()
	part.size = Vector2(CELL_SIZE, CELL_SIZE)
	part.position = OFFSET + (grid_pos * CELL_SIZE)
	add_child(part)
	snake_parts.append(part) # dodajemy na koniec listy wizualnej

func spawn_food():
	var valid = false
	while not valid:
		food_pos = Vector2(randi() % int(GRID_SIZE.x), randi() % int(GRID_SIZE.y))
		valid = not food_pos in snake_body
	
	var food = $Food
	food.size = Vector2(CELL_SIZE, CELL_SIZE)
	food.position = OFFSET + (food_pos * CELL_SIZE)
	food.visible = true

func change_dir(new_dir):
	# nie ma zawracania
	if new_dir + direction != Vector2.ZERO:
		next_dir = new_dir

func _move_step():
	direction = next_dir
	var head = snake_body[0] + direction
	
	# kolizja ze ścianą lub ogonem
	if not Rect2(Vector2.ZERO, GRID_SIZE).has_point(head) or head in snake_body:
		end_game(false)
		return

	snake_body.push_front(head) # dodaj nową głowę
	
	if head == food_pos:
		# zjadł i rośnie
		score += 1
		create_visual_part(head) # tworzymy nowy segment
		
		# nowy segment musi być głową
		var new_head_visual = snake_parts.pop_back()
		new_head_visual.position = OFFSET + (head * CELL_SIZE)
		snake_parts.push_front(new_head_visual)
		
		update_ui("APPEL: " + str(score) + "/5")
		if score >= 5: end_game(true)
		else: spawn_food()
	else:
		# oOgon staje się głową
		snake_body.pop_back()
		
		var tail = snake_parts.pop_back()
		tail.position = OFFSET + (head * CELL_SIZE)
		snake_parts.push_front(tail)

func end_game(win):
	timer.stop()
	update_ui("WINNER!" if win else "FAILURE!")
	await get_tree().create_timer(1.0).timeout
	finished.emit(win)

func update_ui(text):
	if has_node("HUD/ScoreLabel"):
		$HUD/ScoreLabel.text = text
