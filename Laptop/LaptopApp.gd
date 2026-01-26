extends Control

# UI References
@onready var mail_container = $TabContainer/Mail/PocztaLista
@onready var shop_container = $TabContainer/Shop/SklepLista
@onready var terminal_input = $TabContainer/Terminal/CmdInput
@onready var terminal_label = $TabContainer/Terminal/Label
@onready var Stuff = $TabContainer/STUFF

var master_task_list = [
	{
		"type": "choice",
		"title": "Awaria #302", 
		"desc": "Winda nie winduje.", 
		"options": [
			{"text": "Spadaj (0 pkt)", "score": 0, "mistake": true}, 
			{"text": "Zwinduj (100 pkt)", "score": 100, "mistake": false}
		]
	},
	{
		"type": "choice",
		"title": "Spam", 
		"desc": "bla bla blah", 
		"options": [
			{"text": "Nie (10 pkt)", "score": 10, "mistake": false}, 
			{"text": "TAK!!!! (-50 pkt)", "score": -50, "mistake": true}
		]
	},
	# WPISYWANIE KODU
	{
		"type": "input",
		"title": "Napisz 4421",
		"desc": "No napisz byczku.",
		"correct_answer": "4421",
		"score": 150
	},
	{
		"type": "input",
		"title": "MATH",
		"desc": "36 + 31 = ???",
		"correct_answer": "67",
		"score": 150
	}
]

# SKLEP
var shop_items = [
	{"name": "Tyskie", "cost": 300, "type": "cooling", "desc": "Jest moc"},
	{"name": "Wojanek", "cost": 500, "type": "battery", "desc": "PIJ WOJANKA"}
]

# TERMINAL
var current_code = ""

func _ready():
	generate_mails()
	generate_shop()
	generate_new_code()
	$TabContainer/Terminal/CmdButton.pressed.connect(_on_terminal_submit)

# MAILE
func generate_mails():
	for child in mail_container.get_children():
		child.queue_free()
		
	var shuffled = master_task_list.duplicate()
	shuffled.shuffle()
	
	# generujemy 3 losowe maile
	for task in shuffled.slice(0, 3):
		var lbl = Label.new()
		lbl.text = "SUBJECT: " + task["title"] + "\n" + task["desc"]
		# Kolor czcionki czarny dla czytelności na jasnym tle
		lbl.add_theme_color_override("font_color", Color.BLACK) 
		mail_container.add_child(lbl)
		
		# logika wyboru
		if task["type"] == "choice":
			for opt in task["options"]:
				var btn = Button.new()
				btn.text = opt["text"]
				btn.pressed.connect(func(): _resolve_mail_choice(btn, opt, task))
				mail_container.add_child(btn)
		
		# logika wypisywania
		elif task["type"] == "input":
			var input_box = LineEdit.new()
			input_box.placeholder_text = "Type here..."
			mail_container.add_child(input_box)
			
			var send_btn = Button.new()
			send_btn.text = "Send"
			send_btn.pressed.connect(func(): _resolve_mail_input(send_btn, input_box, task))
			mail_container.add_child(send_btn)
			
		mail_container.add_child(HSeparator.new())

# orzyciski
func _resolve_mail_choice(btn, opt, task):
	Global.add_score(opt["score"])
	if opt["mistake"]: Global.add_mistake("Wrong choice: " + task["title"])
	btn.disabled = true
	btn.text += " [OK]"

# pisanie kodu
func _resolve_mail_input(btn, input_field, task):
	var player_text = input_field.text.strip_edges() # usuwamy spacje
	
	# ignorujemy wielkość liter
	if player_text.to_upper() == task["correct_answer"].to_upper():
		Global.add_score(task["score"])
		btn.text = "CORRECT"
		btn.modulate = Color.GREEN
		Global.add_score(50) # bonus
	else:
		Global.add_mistake("WRONG: " + task["title"])
		btn.text = "INCORRECT"
		btn.modulate = Color.RED
		
	btn.disabled = true
	input_field.editable = false

func generate_shop():
	var header = Label.new()
	header.text = "UPGRADES:"
	shop_container.add_child(header)
	for item in shop_items:
		var btn = Button.new()
		btn.text = item["name"] + " (" + str(item["cost"]) + " pkt)\n" + item["desc"]
		btn.pressed.connect(func(): _buy_item(btn, item))
		shop_container.add_child(btn)
		shop_container.add_child(HSeparator.new())

func _buy_item(btn, item):
	if Global.score >= item["cost"]:
		Global.score -= item["cost"]
		btn.disabled = true
		btn.text = "BOUGHT"
		apply_upgrade(item["type"])
	else:
		btn.text = "NO FUNDS"
		await get_tree().create_timer(1.0).timeout
		btn.text = item["name"] + " (" + str(item["cost"]) + " pkt)\n" + item["desc"]

func apply_upgrade(type):
	var generator = get_tree().root.find_child("Generator", true, false)
	if type == "cooling" and generator: generator.cool_down_speed *= 2.0
	elif type == "battery" and generator: generator.drain_rate *= 0.7
	elif type == "speed": Global.add_score(100)

func generate_new_code():
	var rng = RandomNumberGenerator.new()
	var num = rng.randi_range(1000, 9999)
	current_code = str(num)
	terminal_label.text = "ERROR!\nTYPE: " + current_code
	terminal_input.text = ""

func _on_terminal_submit():
	if terminal_input.text == current_code:
		Global.add_score(300)
		terminal_label.text = "SYSTEM RESET..."
		terminal_input.text = ""
		await get_tree().create_timer(5.0).timeout
		generate_new_code()
	else:
		Global.add_mistake("INCORRECT")
		terminal_input.text = "WRONG!"
