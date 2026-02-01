extends AnimatedSprite2D

var colors = [Color(0.975, 0.109, 0.282, 1.0),
			  Color(0.526, 0.945, 0.46, 1.0),
			  Color(0.291, 0.0, 0.905, 1.0),
			  Color(0.583, 0.106, 1.0, 1.0),
			  Color(0.869, 0.325, 0.0, 1.0),
			  ]
# idle
func _ready():
	modulate = colors[randi() % colors.size()]
