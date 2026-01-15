extends Sprite3D

@onready var viewport = get_node("../Hardware/MinigamesViewport")

func interact_at_position(world_position: Vector3):
	var local_pos = to_local(world_position)
	if not texture:
		print("błąd: monitor nie ma tekstury!")
		return
		
	# wymiary
	var tex_size = texture.get_size()
	var sprite_width = tex_size.x * pixel_size
	var sprite_height = tex_size.y * pixel_size
	var x_percent = (local_pos.x + (sprite_width / 2.0)) / sprite_width
	
	# y działa na odwrót w 2D i 3D
	var y_percent = 0.5 - (local_pos.y / sprite_height)
	
	# procent na piksele
	var mouse_x = x_percent * tex_size.x
	var mouse_y = y_percent * tex_size.y
	
	# zabezpieczenie przed klikaniem poza ekranem
	if x_percent < -0.05 or x_percent > 1.05 or y_percent < -0.05 or y_percent > 1.05:
		return
	send_input_event(Vector2(mouse_x, mouse_y))

func send_input_event(pos: Vector2):
	if not viewport: return
	
	# symulacja kliknięcia
	var click_down = InputEventMouseButton.new()
	click_down.button_index = MOUSE_BUTTON_LEFT
	click_down.pressed = true
	click_down.position = pos
	viewport.push_input(click_down)

	await get_tree().process_frame
	
	var click_up = InputEventMouseButton.new()
	click_up.button_index = MOUSE_BUTTON_LEFT
	click_up.pressed = false
	click_up.position = pos
	viewport.push_input(click_up)
