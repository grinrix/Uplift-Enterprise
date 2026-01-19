extends Control
@onready var task_container = $VBoxContainer
# punkty za zadanie
var points_per_task: int = 150

func _ready():
	# łączymy checkboxy
	for child in task_container.get_children():
		if child is CheckBox:
			child.toggled.connect(_on_task_toggled.bind(child)) # bind by wiedzieć co jest kliknietę

func _on_task_toggled(button_pressed: bool, button_node: CheckBox):
	if button_pressed:
		print("Zadanie wykonane: ", button_node.text)
		button_node.disabled = true
		button_node.modulate = Color(0.0, 1.0, 0.0, 1.0)
		
		var gm = get_tree().root.find_child("GameManager", true, false)
		if gm:
			if "score_points" in gm:
				gm.score_points += points_per_task
			if "completed_tasks" in gm:
				gm.completed_tasks += 1
				
			print("Aktualne punkty: ", gm.score_points)
