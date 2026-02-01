extends ParallaxBackground

# prędkość przesuwania
@export var speed: float = 50
@export var direction: Vector2 = Vector2.LEFT

func _process(delta):
	scroll_offset += direction * speed * delta
