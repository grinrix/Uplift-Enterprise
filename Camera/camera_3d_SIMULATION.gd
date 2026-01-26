extends Camera3D

@export var max_rotation_degrees: float = 40.0 
@export var smooth_speed: float = 5.0 
var interaction_distance = 20.0 


func _process(delta):
		var viewport_width = get_viewport().get_visible_rect().size.x
		var mouse_x = get_viewport().get_mouse_position().x
		
		# obliczamy pozycję myszki jako procent ekranu (0.0 do 1.0)
		var mouse_percent = clamp(mouse_x / viewport_width, 0.0, 1.0)
		
		# mapujemy to na kąt obrotu (od +40 do -40)
		var target_y = lerp(max_rotation_degrees, -max_rotation_degrees, mouse_percent)
		
		# płynny obrót
		rotation_degrees.y = lerp(rotation_degrees.y, target_y, delta * smooth_speed)
		

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
				
		if hit_object.name == "SimInteractive":
			var monitor_sprite = hit_object.get_parent()
			if monitor_sprite.has_method("interact_at_position"):
				monitor_sprite.interact_at_position(hit_pos)
				
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
