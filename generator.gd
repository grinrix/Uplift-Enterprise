extends TextureProgressBar

# konfiguracja
var drain_rate: float = 2.0   # jak szybko spada energia
var charge_rate: float = 20.0 # jak szybko rośnie przy ładowaniu
var has_power: bool = true

# blokada gdy jest minigra
var minigame_active: bool = false 

signal power_status_changed(is_active)

func _process(delta):
	value -= drain_rate * delta
		
	if value <= 0 and has_power:
		has_power = false
		power_status_changed.emit(false)
		modulate = Color.RED
		print("Awaria zasilania!")
		
	elif value > 0 and not has_power:
		has_power = true
		power_status_changed.emit(true)
		modulate = Color.GREEN

# ładowanie
func charge(delta_time):
	if not minigame_active:
		value += charge_rate * delta_time
