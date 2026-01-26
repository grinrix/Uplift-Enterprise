extends Control

@onready var label_passengers = $VBoxContainer/LabelPassengers
@onready var label_avg_wait = $VBoxContainer/LabelAvgWait
@onready var label_max_wait = $VBoxContainer/LabelMaxWait

func _process(_delta):
	update_stats()

func update_stats():
	
	label_passengers.text = "Pasażerowie: %d" % Global.statusPassangersCount

	if Global.statusPassangersCount > 0:
		var avg_wait = Global.statusTotalWaitTime / Global.statusPassangersCount
		label_avg_wait.text = "Średni czas oczekiwania: %.2f s" % avg_wait
	else:
		label_avg_wait.text = "Średni czas oczekiwania: 0 s"

	label_max_wait.text = "Maks. czas oczekiwania: %.2f s" % Global.statusMaxWaitTime
