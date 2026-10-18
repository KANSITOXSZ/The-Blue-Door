extends Sprite2D

# Esta es la velocidad a la que se moverá el robot
var velocidad = 400

func _process(delta):
	# Creamos una variable para guardar hacia dónde quiere ir el jugador
	var direccion = Vector2.ZERO
	
	# Detectamos si se presionan las flechas del teclado o las letras WASD
	if Input.is_action_pressed("ui_right"):
		direccion.x += 1
	if Input.is_action_pressed("ui_left"):
		direccion.x -= 1
	if Input.is_action_pressed("ui_down"):
		direccion.y += 1
	if Input.is_action_pressed("ui_up"):
		direccion.y -= 1
		
	# Si el jugador está presionando alguna tecla, movemos al personaje
	position += direccion.normalized() * velocidad * delta
