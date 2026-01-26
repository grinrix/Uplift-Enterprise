extends TextureProgressBar
# konfiguracja energii
var drain_rate: float = 2
var charge_rate: float = 25
var has_power: bool = true

# przegrzewanie
var temperature: float = 0
var max_temp: float = 100.0
var heat_up_speed: float = 40 # jak szybko rośnie temperatura
var cool_down_speed: float = 15 # jak szybko stygnie
# blokada minigry
var minigame_active: bool = false 

signal power_status_changed(is_active)

func _process(delta):
	var usage_multiplier = 1.0
	
	if minigame_active:
		usage_multiplier = 1.5 # 1.5x szybciej podczas minigry!@!!!!!!
	
	# spadek energii
	value -= (drain_rate * usage_multiplier) * delta
	
	# awaria
	if value <= 0 and has_power:
		has_power = false
		power_status_changed.emit(false)
		modulate = Color(0.3, 0.3, 0.3)
		Global.game_over("Generator padł (Brak Energii)!")
		
	elif value > 0 and not has_power:
		has_power = true
		power_status_changed.emit(true)
		modulate = Color.WHITE

	# chłodzenie
	if temperature > 0:
		temperature -= cool_down_speed * delta
	#vizualizacja tego
	var heat_ratio = temperature / max_temp
	if has_power:
		self_modulate = Color(1.0, 1.0 - heat_ratio, 1.0 - heat_ratio)

# ładowanie
func charge(delta_time):
	if not minigame_active and has_power:
		value += charge_rate * delta_time
		# zwiększamy temperaturę
		temperature += heat_up_speed * delta_time
		# przegrzany
		if temperature >= max_temp:
			Global.game_over("GENERATOR WYBUCHŁ! (Przegrzanie)")
