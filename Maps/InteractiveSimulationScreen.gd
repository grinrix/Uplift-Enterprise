extends Sprite3D

@onready var viewport = get_node("../Hardware/SimulationViewport") 

func interact_at_position(world_position: Vector3):
	var local_pos = to_local(world_position)
	if not texture: return
		
	var tex_size = texture.get_size()
	var sprite_width = tex_size.x * pixel_size
	var sprite_height = tex_size.y * pixel_size
	
	var x_percent = (local_pos.x + (sprite_width / 2.0)) / sprite_width
	var y_percent = 0.5 - (local_pos.y / sprite_height)
	
	var mouse_x = x_percent * tex_size.x
	var mouse_y = y_percent * tex_size.y
	
	if x_percent < 0 or x_percent > 1 or y_percent < 0 or y_percent > 1:
		return
		
	send_input_event(Vector2(mouse_x, mouse_y))

func send_input_event(pos: Vector2):
	if not viewport: return
	
	var evt_down = InputEventMouseButton.new()
	evt_down.button_index = MOUSE_BUTTON_LEFT
	evt_down.pressed = true
	evt_down.position = pos
	viewport.push_input(evt_down)
	
	await get_tree().process_frame
	
	var evt_up = InputEventMouseButton.new()
	evt_up.button_index = MOUSE_BUTTON_LEFT
	evt_up.pressed = false
	evt_up.position = pos
	viewport.push_input(evt_up)
