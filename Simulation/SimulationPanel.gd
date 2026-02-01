extends Control

# referencje do ui
@onready var floor_inputs = [
	find_child("Input0", true, false), find_child("Input1", true, false),
	find_child("Input2", true, false), find_child("Input3", true, false),
	find_child("Input4", true, false), find_child("Input5", true, false)
]
@onready var Button_all_20 = find_child("ButtonAll20", true, false)
@onready var Button_all_0 = find_child("ButtonAll0", true, false)
@onready var Button_random = find_child("ButtonRandom", true, false)
@onready var input_from = find_child("FromInput", true, false)
@onready var input_to = find_child("ToInput", true, false)
@onready var Button_spawn = find_child("ButtonSpawn", true, false)
@onready var input_mass_amount = find_child("MassAmountInput", true, false)
@onready var Button_mass_spawn = find_child("ButtonMassSpawn", true, false)
@onready var Button_reset = find_child("ButtonReset", true, false)

var game_manager = null

func _ready():
	await get_tree().process_frame
	# szukamy managera
	game_manager = get_tree().root.find_child("GameManager", true, false)
	var clock = find_child("Clock", true, false)
	if clock: clock.visible = false
	if game_manager:
		# print("połączono z gamemanager")
		game_manager.is_simulation_mode = true
		game_manager.clear_all_passengers()
		game_manager.floor_difficulties = [0, 0, 0, 0, 0, 0]
		refresh_ui_from_manager()
		
		# podłączenie sygnałów dla pięter
		for i in range(6):
			var input = floor_inputs[i]
			if input:
				var parent = input.get_parent() 
				var Button_minus = parent.find_child("ButtonMinus" + str(i), true, false)
				var Button_plus = parent.find_child("ButtonPlus" + str(i), true, false)
				
				if Button_minus: Button_minus.pressed.connect(_change_difficulty.bind(i, -1))
				if Button_plus: Button_plus.pressed.connect(_change_difficulty.bind(i, 1))
				
				# obsługa ręcznego wpisywania tekstu trudności
				if not input.text_changed.is_connected(_on_text_difficulty_changed):
					input.text_changed.connect(_on_text_difficulty_changed.bind(i))

		# podłączenie limitów dla spawnera
		if input_from:
			input_from.text_changed.connect(func(new_text): sanitize_input(input_from, 5))
		if input_to:
			input_to.text_changed.connect(func(new_text): sanitize_input(input_to, 5))
		if input_mass_amount:
			input_mass_amount.text_changed.connect(func(new_text): sanitize_input(input_mass_amount, 9999))

		if Button_all_20: Button_all_20.pressed.connect(_set_all_difficulties.bind(20))
		if Button_all_0: Button_all_0.pressed.connect(_set_all_difficulties.bind(0))
		if Button_random: Button_random.pressed.connect(_set_random_difficulties)
		if Button_reset: Button_reset.pressed.connect(_on_reset)
		if Button_spawn: Button_spawn.pressed.connect(_on_single_spawn)
		if Button_mass_spawn: Button_mass_spawn.pressed.connect(_on_mass_spawn)
		
	else:
		print("brak gamemanager")

# funkcja czyszcząca input
func sanitize_input(line_edit: LineEdit, max_val: int):
	var text = line_edit.text
	if text == "": return # pozwala na puste pole podczas edytowania

	# usuwa wszystko co nie jest cyfrą
	var filtered_text = ""
	for char in text:
		if char.is_valid_int():
			filtered_text += char
	
	# sprawdzanie limitu
	if filtered_text != "":
		var final_val = int(filtered_text)
		if final_val > max_val:
			final_val = max_val # limit 
			filtered_text = str(final_val)
	else:
		filtered_text = ""

	# zaktualizuje tekst tylko jeśli coś zmieniło
	if line_edit.text != filtered_text:
		var old_caret = line_edit.caret_column
		line_edit.text = filtered_text
		line_edit.caret_column = min(old_caret, filtered_text.length())

func refresh_ui_from_manager():
	if not game_manager: return
	for i in range(6):
		if i < game_manager.floor_difficulties.size():
			var val = game_manager.floor_difficulties[i]
			if floor_inputs[i]:
				floor_inputs[i].text = str(val)

func _change_difficulty(floor_idx, amount):
	# wartość pobierana z ui
	var txt = floor_inputs[floor_idx].text
	var current_val = int(txt) if txt != "" else 0 # zabezpieczenie na wypadek pustego pola
	
	var new_val = clamp(current_val + amount, 0, 20)
	_update_floor_data(floor_idx, new_val)

func _on_text_difficulty_changed(new_text, floor_idx):
	var input_box = floor_inputs[floor_idx]
	
	# limit 20
	sanitize_input(input_box, 20)
	
	# pobiera bezpieczną wartość i wysyła do managera
	if input_box.text != "":
		var val = int(input_box.text)
		if game_manager:
			game_manager.set_floor_difficulty(floor_idx, val)

func _update_floor_data(idx, val):
	if floor_inputs[idx]:
		floor_inputs[idx].text = str(val)
		floor_inputs[idx].caret_column = floor_inputs[idx].text.length() 
		
	if game_manager:
		game_manager.set_floor_difficulty(idx, val)

# przyciski globalne
func _set_all_difficulties(value):
	for i in range(6):
		_update_floor_data(i, value)

func _set_random_difficulties():
	for i in range(6):
		var rand_val = randi() % 21 # 0-20
		_update_floor_data(i, rand_val)

# logika pasażerów
func _on_reset():
	if game_manager:
		game_manager.clear_all_passengers()
		Global.statusPassangersCount = 0
		Global.statusTotalWaitTime = 0
		Global.statusMaxWaitTime = 0
		game_manager.floor_difficulties = [0, 0, 0, 0, 0, 0]

func _on_single_spawn():
	if game_manager and input_from and input_to:
		var txt_f = input_from.text
		var txt_t = input_to.text
		
		# zabezpieczenie przed pustym tekstem
		var f = int(txt_f) if txt_f != "" else 0
		var t = int(txt_t) if txt_t != "" else 1
		
		# walidacja pięter 0-5
		f = clamp(f, 0, 5)
		t = clamp(t, 0, 5)
		
		game_manager.force_spawn_passenger(f, t)

func _on_mass_spawn():
	if not game_manager:
		print("gamemanager nie podłączony")
		return
		
	if input_mass_amount.text == "": return
	
	var amount = int(input_mass_amount.text)
	print("mass spawn: ", amount)
	
	for i in range(amount):
		game_manager.force_spawn_passenger(-1, -1)
