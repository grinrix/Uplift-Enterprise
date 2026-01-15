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

# idle
func _ready():
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
			button_pressed.emit(start_floor, self)
			
		State.ENTERING:
			_finish_boarding()
			
		State.LEAVING:
			queue_free()


func start_boarding(elevator_node):
	if current_state != State.WAITING: return
	current_state = State.ENTERING
	var elevator_center_x = elevator_node.position.x + 40.0
	var offset = randf_range(-15, 100)
	walk_to(elevator_center_x + offset)

func _finish_boarding():
	current_state = State.IN_ELEVATOR
	var elevator = get_tree().root.find_child("Elevator", true, false)
	
	if elevator:
		reparent(elevator)
		position.y = 0
		print("Pasażer w środku!")
		boarded.emit()
		sprite.flip_h = true 

func leave_elevator():
	if current_state != State.IN_ELEVATOR: return
	current_state = State.LEAVING
	
	var game_map = get_tree().root.find_child("GameMap", true, false)
	if game_map:
		reparent(game_map)
		
	# Wychodzi w lewo poza ekran
	walk_to(-100.0) 
	print("Pasażer wychodzi...")
