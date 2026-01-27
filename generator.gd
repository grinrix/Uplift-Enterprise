extends TextureProgressBar

# Konfiguracja energii
var drain_rate: float = 2.0
var charge_rate: float = 25.0
var has_power: bool = true

# NOWOŚĆ: Przegrzewanie
var temperature: float = 0.0
var max_temp: float = 100.0
var heat_up_speed: float = 40.0 # Jak szybko rośnie temperatura
var cool_down_speed: float = 15.0 # Jak szybko stygnie

# Blokada minigry
var minigame_active: bool = false 

signal power_status_changed(is_active)

func _process(delta):
	# Obliczamy mnożnik zużycia
	var usage_multiplier = 1.0
	
	if minigame_active:
		usage_multiplier = 1.5 # 1.5x szybciej podczas minigry!
	
	# 1. Spadek energii (Teraz spada ZAWSZE, a szybciej w minigrze)
	value -= (drain_rate * usage_multiplier) * delta
	
	# 2. Awaria zasilania (bateria padła)
	if value <= 0 and has_power:
		has_power = false
		power_status_changed.emit(false)
		modulate = Color(0.3, 0.3, 0.3) # Ciemny kolor (brak prądu)
		Global.game_over("Generator padł (Brak Energii)!")
		
	elif value > 0 and not has_power:
		has_power = true
		power_status_changed.emit(true)
		modulate = Color.WHITE

	# 3. Chłodzenie (tylko gdy gracz NIE ładuje ręcznie)
	# (Zakładam, że charge() jest wywoływane z zewnątrz, więc tu tylko stygnięcie)
	if temperature > 0:
		temperature -= cool_down_speed * delta
		
	# 4. Wizualizacja przegrzania
	var heat_ratio = temperature / max_temp
	if has_power:
		self_modulate = Color(1.0, 1.0 - heat_ratio, 1.0 - heat_ratio)

# Funkcja ładowania (wywoływana z kamery przez przytrzymanie myszki)
func charge(delta_time):
	if not minigame_active and has_power:
		# Ładujemy baterię
		value += charge_rate * delta_time
		
		# NOWOŚĆ: Zwiększamy temperaturę
		temperature += heat_up_speed * delta_time
		
		# Sprawdzamy czy wybuchł
		if temperature >= max_temp:
			Global.game_over("GENERATOR WYBUCHŁ! (Przegrzanie)")
