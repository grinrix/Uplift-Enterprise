extends Camera3D
@export var max_rotation_degrees: float = 40.0 
@export var smooth_speed: float = 5.0 
var interaction_distance = 20.0 
@onready var generator_node = get_tree().root.find_child("Generator", true, false)

# zegar
@onready var clock = $Clock
var shift_time_left: float = 270.0 
var shift_active: bool = true

func _process(delta):
	var viewport_width = get_viewport().get_visible_rect().size.x
	var mouse_x = get_viewport().get_mouse_position().x
	var mouse_percent = clamp(mouse_x / viewport_width, 0.0, 1.0)
	var target_y = lerp(max_rotation_degrees, -max_rotation_degrees, mouse_percent)
	rotation_degrees.y = lerp(rotation_degrees.y, target_y, delta * smooth_speed)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		check_hold_interaction(delta)
	# zegar
	if shift_active:
		shift_time_left -= delta
		var minutes = floor(shift_time_left / 60)
		var seconds = int(shift_time_left) % 60
		clock.text = "%02d:%02d" % [minutes, seconds]

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#print(">>> KLIKNIĘCIE MYSZKĄ WYKRYTE <<<") # debug
		check_interaction()

func check_interaction():
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var origin = project_ray_origin(mouse_pos)
	var end = origin + project_ray_normal(mouse_pos) * 20.0 
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_object = result.collider
		var hit_pos = result.position
		# monitor z minigrami
		if hit_object.name == "MonitorInteractive":
			var monitor_sprite = hit_object.get_parent()
			if monitor_sprite.has_method("interact_at_position"):
				monitor_sprite.interact_at_position(hit_pos)
				
		# zmiania trybu
		elif hit_object.name == "SwitchArea":
			if owner.has_method("on_switch_clicked"):
				owner.on_switch_clicked()

func check_hold_interaction(delta):
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var origin = project_ray_origin(mouse_pos)
	var end = origin + project_ray_normal(mouse_pos) * interaction_distance
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_obj = result.collider
		if hit_obj.name == "ChargeArea":
			if generator_node:
				# ładowanie generatora
				generator_node.charge(delta)
