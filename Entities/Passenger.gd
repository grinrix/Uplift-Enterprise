extends Node2D
@onready var sprite = $AnimatedSprite2D
@onready var label = $Label
signal button_pressed(floor_number, passenger_node)
signal boarded # sygnał że jest w środku

# dane:
var start_floor: int = 0
var target_floor: int = 0
var speed: float = randf_range(60, 110)
var target_x: float = 0
var is_walking: bool = false

# do statystyk
var spawnTime: int
var arrival_time: int = 0 # czas dotarcia pod drzwi
var waitDuration: float = 0.0 # ile faktycznie czekał na windę


# stan pasażera
enum State { WALKING_TO_DOOR, WAITING, ENTERING, IN_ELEVATOR, LEAVING }
var current_state = State.WALKING_TO_DOOR

var exit_target_x: float = -100

func setup_passenger(floor_from: int, floor_to: int):
	start_floor = floor_from
	target_floor = floor_to
	
	# zmiana napisu na górze
	if label:
		label.text = str(target_floor)
		
		if target_floor > start_floor:
			label.modulate = Color.GREEN # jedzie w górę
		else:
			label.modulate = Color.RED # jedzie w dół

var colors = [Color(0.975, 0.109, 0.282, 1.0),
			  Color(0.526, 0.945, 0.46, 1.0),
			  Color(0.291, 0.0, 0.905, 1.0),
			  Color(0.583, 0.106, 1.0, 1.0),
			  Color(0.869, 0.325, 0.0, 1.0),
			  Color(1.0, 1.0, 1.0, 1.0),
			  Color()]
# idle
func _ready():
	modulate = colors[randi() % colors.size()]
	spawnTime = Time.get_ticks_msec()
	if sprite:
		sprite.play("idle")

# walking
func _process(delta):
	if is_walking:
		position.x = move_toward(position.x, target_x, speed * delta)
		if is_equal_approx(position.x, target_x):
			position.x = target_x 
			stop_walking()


func walk_to(destination_x: float):
	target_x = destination_x
	is_walking = true
	
	if sprite:
		sprite.play("walking")
		# sprawdzamy gdzie ma iść (lewo czy prawo)
		if destination_x < position.x:
			sprite.flip_h = true # Idzie w lewo
		else:
			sprite.flip_h = false # Idzie w prawo

func stop_walking():
	is_walking = false
	if sprite:
		sprite.play("idle")
	match current_state:
		State.WALKING_TO_DOOR:
			current_state = State.WAITING
			# zaczyna liczyć czas oczekiwania (dotarł pod drzwi)
			arrival_time = Time.get_ticks_msec()
			button_pressed.emit(start_floor, self)
			
		State.ENTERING:
			_finish_boarding()
			
		State.LEAVING:
			queue_free()


func start_boarding(elevator_node):
	if current_state != State.WAITING: return
	
	# zmiana prędkości by statystyki były poprawne
	speed = 100
	
	current_state = State.ENTERING
	var elevator_center_x = elevator_node.position.x + 40
	var offset = randf_range(-15, 100)
	walk_to(elevator_center_x + offset)

func _finish_boarding():
	current_state = State.IN_ELEVATOR
	
	# obliczamy czas oczekiwania 
	var now = Time.get_ticks_msec()
	waitDuration = (now - arrival_time) / 1000
	
	var elevator = get_tree().root.find_child("Elevator", true, false)
	
	if elevator:
		reparent(elevator)
		position.y = 0
		print("Pasażer w środku! Czekał: ", waitDuration, "s")
		boarded.emit()
		sprite.flip_h = true 

func leave_elevator():
	if current_state != State.IN_ELEVATOR: return
	current_state = State.LEAVING
	
	# wysyłamy statystyki do globala
	Global.statusPassangersCount += 1
	Global.statusTotalWaitTime += waitDuration
	
	if waitDuration > Global.statusMaxWaitTime:
		Global.statusMaxWaitTime = waitDuration
		
	Global.add_score(50)
	
	var game_map = get_tree().root.find_child("GameMap", true, false)
	if game_map:
		var global_pos = global_position
		# musimy przepiąć pasażera z windy na mapę, żeby nie odjechał dalej
		if get_parent(): get_parent().remove_child(self)
		game_map.add_child(self)
		global_position = global_pos
		
	# wychodzi w lewo poza ekran
	walk_to(-200.0) 
	speed = randf_range(60, 110)
	print("Pasażer wychodzi...")

# funkcja pomocnicza
func on_enter_elevator():
	return waitDuration
