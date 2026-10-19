extends Node2D

var plantilla_pared = preload("res://pared.tscn")

# ==========================================
# CONFIGURACIÓN Y VARIABLES DEL JUEGO
# ==========================================
var nivel_actual = 1
var nivel_final = 25          # Al terminar este nivel se acaba la Alpha
var nivel_corazones = 11      # Desde este nivel se activan corazones y bloques rojos
var nivel_oscuridad = 16      # Desde este nivel todo está oscuro y hace falta la linterna
var nivel_memoria = 21        # Niveles 21 a 25: al tomar la linterna se ve el mapa 3 s y hay que memorizarlo
var tamaño_bloque = 64
var columnas = 18
var filas = 10

var jugador: CharacterBody2D
var puerta: Area2D
var texto_nivel: Label
var capa_interfaz: CanvasLayer
var menu_capa: CanvasLayer      # menú principal (se borra al elegir dispositivo)
var menu_caja: VBoxContainer    # contenido del menú (cambia entre pantallas)

# Velocidad del personaje según el dispositivo elegido en el menú
# (igual en PC y teléfono: más lento en los niveles 11 a 15 y 21 a 25, donde se pierde fácil)
var velocidad_normal = 300.0
var velocidad_lenta = 220.0
var nivel_lento_desde = 11
var nivel_lento_hasta = 15
var nivel_lento2_desde = 21
var nivel_lento2_hasta = 25
var velocidad_jugador = 300.0

# Corazones
var corazones_max = 3
var corazones = 3
var corazones_visuales: Array = []
var contenedor_corazones: Node2D
var tiempo_invulnerable = 0.0   # segundos de invencibilidad que quedan
var reiniciando = false         # evita recibir daño mientras se reinicia el nivel
var frames_gracia = 0           # pasos de física sin daño tras generar un nivel
var texto_invencible: Label
var texto_warning: Label
var tiene_dorado = false        # true cuando recoges el corazón dorado del nivel 10
var hay_secreto = false         # true si el nivel actual tiene el bloque traspasable
var celda_secreta = Vector2i.ZERO
var ultimo_toque_arriba = -10000  # milisegundos de la última pulsación de flecha arriba

# Oscuridad y linterna
var oscuridad: CanvasModulate
var luz_jugador: PointLight2D
var tiene_linterna = false

# Niveles de memoria (21 a 25)
var tiempo_memoria = 3.0        # segundos que se ve el mapa al tomar la linterna
var tiempo_revelado = 0.0       # segundos de visibilidad que quedan
var texto_memoria: Label

# Logros (se guardan en el dispositivo, así que no se pierden al cerrar el juego)
const ARCHIVO_LOGROS = "user://logros.cfg"
var logro_end = false           # logro "¿End?": terminar la Alpha
var logro_gold = false          # logro "Gold": conseguir el corazón dorado

# Controles táctiles: true = solo se ven en teléfonos; false = se ven siempre (útil para probar)
var botones_solo_en_movil = false

# Guarda las alturas del camino del nivel anterior para que el nuevo sea distinto
var ultimo_camino: Array = []

func _ready():
	randomize()
	cargar_logros()

	# Pantalla adaptable: el juego (1152 x 640) se escala a PC y teléfonos
	var ventana = get_window()
	ventana.content_scale_size = Vector2i(columnas * tamaño_bloque, filas * tamaño_bloque)
	ventana.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	ventana.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	# En teléfonos: pantalla horizontal (en PC no hace nada)
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

	# Filtro de oscuridad (blanco = sin efecto; negro = todo oscuro)
	oscuridad = CanvasModulate.new()
	oscuridad.color = Color(1, 1, 1)
	add_child(oscuridad)

	capa_interfaz = CanvasLayer.new()
	add_child(capa_interfaz)

	texto_nivel = Label.new()
	texto_nivel.text = "NIVEL: " + str(nivel_actual)
	texto_nivel.position = Vector2(25, 25)
	texto_nivel.scale = Vector2(2, 2)
	texto_nivel.modulate = Color(0, 0.6, 1)
	capa_interfaz.add_child(texto_nivel)

	# Contador de invencibilidad (arriba, al centro)
	texto_invencible = Label.new()
	texto_invencible.position = Vector2(430, 25)
	texto_invencible.scale = Vector2(2, 2)
	texto_invencible.modulate = Color(1, 0.9, 0.2)
	texto_invencible.visible = false
	capa_interfaz.add_child(texto_invencible)

	# Cartel de advertencia (nivel 10) y mensajes cortos
	texto_warning = Label.new()
	texto_warning.text = "WARNING"
	texto_warning.position = Vector2(480, 25)
	texto_warning.scale = Vector2(2.5, 2.5)
	texto_warning.modulate = Color(1, 0.8, 0)
	texto_warning.visible = false
	capa_interfaz.add_child(texto_warning)

	# Cuenta regresiva para memorizar el mapa (niveles 21 a 25)
	texto_memoria = Label.new()
	texto_memoria.position = Vector2(380, 85)
	texto_memoria.scale = Vector2(2.5, 2.5)
	texto_memoria.modulate = Color(1, 0.9, 0.2)
	texto_memoria.visible = false
	capa_interfaz.add_child(texto_memoria)

	crear_controles_tactiles()
	crear_corazones_interfaz()
	crear_puerta_meta()
	generar_mapa_procedural()

	# Título de la ventana en PC y menú principal
	get_window().title = "The Blue Door"
	crear_menu_principal()


# ==========================================
# CONTROLES TÁCTILES (flechas en pantalla para teléfonos)
# ==========================================
# El teclado (flechas) sigue funcionando en PC.
func crear_controles_tactiles():
	var centro = Vector2(1017, 505)  # abajo a la derecha
	var separacion = 75
	crear_boton_tactil("ui_up", centro + Vector2(0, -separacion), 0)
	crear_boton_tactil("ui_down", centro + Vector2(0, separacion), 180)
	crear_boton_tactil("ui_left", centro + Vector2(-separacion, 0), -90)
	crear_boton_tactil("ui_right", centro + Vector2(separacion, 0), 90)


func crear_boton_tactil(accion: String, pos: Vector2, rotacion: float):
	var lado = 70
	var boton = TouchScreenButton.new()
	boton.position = pos
	boton.action = accion
	boton.passby_press = true  # permite deslizar el dedo de un botón a otro
	if botones_solo_en_movil:
		boton.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY

	var forma = RectangleShape2D.new()
	forma.size = Vector2(lado, lado)
	boton.shape = forma

	var fondo = ColorRect.new()
	fondo.size = Vector2(lado, lado)
	fondo.position = Vector2(-lado / 2, -lado / 2)
	fondo.color = Color(0, 0, 0, 0.9)  # fondo negro
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var flecha = Polygon2D.new()
	flecha.polygon = PackedVector2Array([Vector2(0, -20), Vector2(20, 12), Vector2(-20, 12)])
	flecha.rotation_degrees = rotacion
	flecha.color = Color(1, 1, 1, 0.9)

	boton.add_child(fondo)
	boton.add_child(flecha)

	# Se ilumina al presionarlo
	boton.pressed.connect(func():
		fondo.color = Color(0.3, 0.3, 0.3, 0.95)
		if accion == "ui_up":
			registrar_toque_arriba()
	)
	boton.released.connect(func():
		fondo.color = Color(0, 0, 0, 0.9)
	)

	boton.add_to_group("botones_tactiles")
	capa_interfaz.add_child(boton)


# ==========================================
# MENÚ PRINCIPAL
# ==========================================
# El juego queda en pausa detrás del menú hasta que se pulsa JUGAR.
func crear_menu_principal():
	get_tree().paused = true

	menu_capa = CanvasLayer.new()
	menu_capa.layer = 100  # por encima de todo lo demás
	menu_capa.process_mode = Node.PROCESS_MODE_ALWAYS  # sigue funcionando en pausa
	add_child(menu_capa)

	# Fondo negro que cubre toda la pantalla
	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 1)
	menu_capa.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro = CenterContainer.new()
	menu_capa.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var caja = VBoxContainer.new()
	menu_caja = caja
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 20)
	centro.add_child(caja)

	mostrar_pantalla_principal()


# Pantalla principal: título y una fila con LOGROS (izquierda), JUGAR (centro) y MODS (derecha)
func mostrar_pantalla_principal():
	limpiar_menu()

	# Puerta azul decorativa
	var puerta_deco = ColorRect.new()
	puerta_deco.color = Color(0, 0.6, 1)
	puerta_deco.custom_minimum_size = Vector2(60, 100)
	puerta_deco.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_caja.add_child(puerta_deco)

	crear_etiqueta_menu("THE BLUE DOOR", 72, Color(0, 0.6, 1))
	crear_etiqueta_menu("ALPHA 1.0", 24, Color(0.6, 0.6, 0.6))

	var fila = HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 30)
	menu_caja.add_child(fila)

	var boton_logros = crear_boton_en(fila, "LOGROS", 220, 70, 30)
	boton_logros.pressed.connect(_on_logros_pulsado)

	var boton_jugar = crear_boton_en(fila, "JUGAR", 280, 80, 40)
	boton_jugar.pressed.connect(_on_jugar_pulsado)

	var boton_mods = crear_boton_en(fila, "MODS", 220, 70, 30)
	boton_mods.pressed.connect(_on_mods_pulsado)

	# SALIR: debajo de JUGAR, un poco más pequeño
	var boton_salir = crear_boton_en(menu_caja, "SALIR", 200, 60, 28)
	boton_salir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boton_salir.pressed.connect(_on_salir_pulsado)

	boton_jugar.grab_focus.call_deferred()  # en PC se puede pulsar con Enter


# Cierra el juego (en PC cierra la ventana, en teléfono vuelve al sistema)
func _on_salir_pulsado():
	get_tree().quit()


# Quita lo que hay en el menú para mostrar otra pantalla
func limpiar_menu():
	for hijo in menu_caja.get_children():
		menu_caja.remove_child(hijo)
		hijo.queue_free()


func crear_etiqueta_menu(texto: String, tamano: int, color: Color) -> Label:
	var etiqueta = Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.modulate = color
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_caja.add_child(etiqueta)
	return etiqueta


func crear_boton_en(padre: Node, texto: String, ancho: int, alto: int, fuente: int) -> Button:
	var boton = Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(ancho, alto)
	boton.add_theme_font_size_override("font_size", fuente)
	padre.add_child(boton)
	return boton


# MODS: por ahora está vacío
func _on_mods_pulsado():
	limpiar_menu()
	crear_etiqueta_menu("MODS", 64, Color(0, 0.6, 1))
	crear_etiqueta_menu("Nothing here...", 36, Color(0.6, 0.6, 0.6))
	var volver = crear_boton_menu("VOLVER")
	volver.pressed.connect(mostrar_pantalla_principal)
	volver.grab_focus.call_deferred()


# LOGROS: 3 espacios. Los que no se han descubierto muestran "..."
# Logro 1: "¿End?" (terminar la Alpha). Logro 2: "Gold" (conseguir el corazón dorado).
func _on_logros_pulsado():
	limpiar_menu()
	crear_etiqueta_menu("LOGROS", 64, Color(0, 0.6, 1))

	if logro_end:
		crear_etiqueta_menu("¿End?", 44, Color(1, 0.84, 0))
		crear_etiqueta_menu("Finish the Alpha", 22, Color(0.6, 0.6, 0.6))
	else:
		crear_etiqueta_menu("...", 44, Color(0.6, 0.6, 0.6))

	if logro_gold:
		crear_etiqueta_menu("Gold", 44, Color(1, 0.84, 0))
		crear_etiqueta_menu("Heart of gold!", 22, Color(0.6, 0.6, 0.6))
	else:
		crear_etiqueta_menu("...", 44, Color(0.6, 0.6, 0.6))

	crear_etiqueta_menu("...", 44, Color(0.6, 0.6, 0.6))

	var volver = crear_boton_menu("VOLVER")
	volver.pressed.connect(mostrar_pantalla_principal)
	volver.grab_focus.call_deferred()


func _on_jugar_pulsado():
	# Segunda pantalla del menú: ¿En qué juegas?
	for hijo in menu_caja.get_children():
		hijo.queue_free()

	var pregunta = Label.new()
	pregunta.text = "¿En qué juegas?"
	pregunta.add_theme_font_size_override("font_size", 56)
	pregunta.modulate = Color(0, 0.6, 1)
	pregunta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_caja.add_child(pregunta)

	var boton_pc = crear_boton_menu("PC")
	boton_pc.pressed.connect(_elegir_dispositivo.bind("pc"))

	var boton_telefono = crear_boton_menu("TELÉFONO")
	boton_telefono.pressed.connect(_elegir_dispositivo.bind("telefono"))

	boton_pc.grab_focus.call_deferred()


func crear_boton_menu(texto: String) -> Button:
	var boton = Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(320, 80)
	boton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boton.add_theme_font_size_override("font_size", 40)
	menu_caja.add_child(boton)
	return boton


# Velocidad según el nivel: 220 del 11 al 15 y del 21 al 25, 300 en el resto (en PC y teléfono)
func actualizar_velocidad():
	var tramo_lento_1 = nivel_actual >= nivel_lento_desde and nivel_actual <= nivel_lento_hasta
	var tramo_lento_2 = nivel_actual >= nivel_lento2_desde and nivel_actual <= nivel_lento2_hasta
	if tramo_lento_1 or tramo_lento_2:
		velocidad_jugador = velocidad_lenta
	else:
		velocidad_jugador = velocidad_normal
	if jugador:
		jugador.set("velocidad", velocidad_jugador)


# El dispositivo solo decide si se muestran los botones táctiles
func _elegir_dispositivo(dispositivo: String):
	# Los botones táctiles solo se ven en la versión de teléfono
	for boton in get_tree().get_nodes_in_group("botones_tactiles"):
		boton.visible = dispositivo == "telefono"

	menu_capa.queue_free()
	get_tree().paused = false


# ==========================================
# CORAZONES (solo activos desde el nivel 11)
# ==========================================
func crear_corazones_interfaz():
	contenedor_corazones = Node2D.new()
	capa_interfaz.add_child(contenedor_corazones)
	# 3 corazones rojos + 1 dorado oculto hasta que lo consigas en el nivel 10
	for i in range(4):
		var corazon = crear_corazon(Vector2(45 + i * 45, 105))
		contenedor_corazones.add_child(corazon)
		corazones_visuales.append(corazon)
	corazones_visuales[3].visible = false
	contenedor_corazones.visible = false


func crear_corazon(centro: Vector2) -> Polygon2D:
	var p = Polygon2D.new()
	var puntos = PackedVector2Array()
	for i in range(40):
		var t = TAU * i / 40.0
		var x = 16 * pow(sin(t), 3)
		var y = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))
		puntos.append(Vector2(x, y) * 1.2)
	p.polygon = puntos
	p.position = centro
	p.color = Color(1, 0.1, 0.1)
	return p


func actualizar_corazones():
	for i in range(corazones_max):
		if i < corazones:
			if i == 3:
				corazones_visuales[i].color = Color(1, 0.84, 0)  # corazón dorado
			else:
				corazones_visuales[i].color = Color(1, 0.1, 0.1)
		else:
			corazones_visuales[i].color = Color(0.25, 0.25, 0.25)


func _physics_process(delta):
	# Niveles 21 a 25: durante unos segundos se ve todo el mapa para memorizarlo
	if tiempo_revelado > 0:
		tiempo_revelado -= delta
		if tiempo_revelado <= 0:
			oscuridad.color = Color(0, 0, 0)  # vuelve la oscuridad
			texto_memoria.visible = false
		else:
			texto_memoria.text = "¡MEMORIZA!  %.1f" % tiempo_revelado

	# Cuenta regresiva de invencibilidad + parpadeo del personaje
	if tiempo_invulnerable > 0:
		tiempo_invulnerable -= delta
		if tiempo_invulnerable <= 0:
			terminar_invencibilidad()
		else:
			texto_invencible.text = "INVENCIBLE: %.1f" % tiempo_invulnerable
			if jugador:
				var visible_ahora = int(tiempo_invulnerable * 8) % 2 == 0
				jugador.modulate = Color(1, 1, 1, 1.0 if visible_ahora else 0.2)

	# Tras generar un nivel esperamos unos pasos de física antes de revisar daño
	if frames_gracia > 0:
		frames_gracia -= 1
		return

	# Solo desde el nivel 11: revisamos si el jugador toca un bloque rojo
	if nivel_actual < nivel_corazones or jugador == null or tiempo_invulnerable > 0 or reiniciando:
		return
	for rojo in get_tree().get_nodes_in_group("rojos"):
		if rojo.is_queued_for_deletion():
			continue
		if jugador in rojo.get_overlapping_bodies():
			recibir_dano()
			return


func recibir_dano():
	corazones -= 1
	actualizar_corazones()

	if corazones <= 0:
		# Sin corazones: vuelves al nivel 11 (o al 21 si estabas en los niveles de memoria)
		# con corazones nuevos y un mapa nuevo.
		# "reiniciando" bloquea el daño hasta que el jugador reaparezca.
		if nivel_actual >= nivel_memoria:
			nivel_actual = nivel_memoria
		else:
			nivel_actual = nivel_corazones
		texto_nivel.text = "NIVEL: " + str(nivel_actual)
		reiniciando = true
		terminar_invencibilidad()
		generar_mapa_procedural.call_deferred()
		return

	# 3 segundos de invencibilidad con contador y parpadeo
	tiempo_invulnerable = 3.0
	texto_invencible.visible = true


func terminar_invencibilidad():
	tiempo_invulnerable = 0.0
	texto_invencible.visible = false
	if jugador:
		jugador.modulate = Color(1, 1, 1, 1)


# Mensaje corto arriba en pantalla (2 segundos)
func mostrar_mensaje(texto: String, color: Color, x: float):
	texto_warning.text = texto
	texto_warning.position = Vector2(x, 25)
	texto_warning.modulate = color
	texto_warning.visible = true
	await get_tree().create_timer(2.0).timeout
	if texto_warning.text == texto:
		texto_warning.text = "WARNING"
		texto_warning.position = Vector2(480, 25)
		texto_warning.modulate = Color(1, 0.8, 0)
		texto_warning.visible = nivel_actual == 10


# ==========================================
# GENERADOR DE CAMINO PREHECHO (distinto en cada nivel)
# ==========================================
# Devuelve un Array con la altura (fila) del camino en cada columna.
func generar_alturas() -> Array:
	var alturas = []
	var intentos = 0
	while true:
		alturas = []
		for x in range(columnas - 1):  # columnas 0..16
			alturas.append(5)
		for x in range(2, columnas - 2):  # columnas 2..15 aleatorias
			alturas[x] = randi_range(1, filas - 2)
		intentos += 1
		# Cuenta los giros: el camino nunca debe ser recto
		var cambios = 0
		for x in range(1, columnas - 1):
			if alturas[x] != alturas[x - 1]:
				cambios += 1
		# Debe tener giros y ser diferente al camino del nivel anterior
		if cambios >= 5 and alturas != ultimo_camino:
			break
		if intentos > 200:
			break
	return alturas


# Agrega una celda al camino (guardando también el orden de recorrido)
func agregar_camino(camino: Dictionary, orden: Array, pos: Vector2i):
	if not camino.has(pos):
		camino[pos] = true
		orden.append(pos)


func generar_mapa_procedural():
	# Limpiamos todo lo del nivel anterior
	for pared in get_tree().get_nodes_in_group("paredes"):
		pared.queue_free()
	for rojo in get_tree().get_nodes_in_group("rojos"):
		rojo.queue_free()
	for dorado in get_tree().get_nodes_in_group("dorados"):
		dorado.queue_free()
	for negro in get_tree().get_nodes_in_group("negros"):
		negro.queue_free()
	for linterna in get_tree().get_nodes_in_group("linternas"):
		linterna.queue_free()
	hay_secreto = false

	# Nuevo nivel / reaparición: sin invencibilidad pendiente y daño activado de nuevo
	var venia_de_muerte = reiniciando
	reiniciando = false
	frames_gracia = 5
	terminar_invencibilidad()
	if venia_de_muerte:
		# Reaparición: corazones completos y 3 s de invencibilidad
		corazones = corazones_max
		actualizar_corazones()
		tiempo_invulnerable = 3.0
		texto_invencible.visible = true

	var es_oscuro = nivel_actual >= nivel_oscuridad
	var es_memoria = nivel_actual >= nivel_memoria

	# Al entrar a los niveles de memoria (21) los corazones se reinician
	if nivel_actual == nivel_memoria:
		corazones = corazones_max
		actualizar_corazones()

	# En cada nivel oscuro hay que volver a encontrar la linterna
	tiene_linterna = false
	tiempo_revelado = 0.0
	texto_memoria.visible = false
	oscuridad.color = Color(0, 0, 0) if es_oscuro else Color(1, 1, 1)

	# Los corazones solo se ven desde el nivel 11
	contenedor_corazones.visible = nivel_actual >= nivel_corazones

	# El cartel WARNING solo se ve en el nivel 10
	texto_warning.visible = nivel_actual == 10

	# Matriz virtual (0 = libre, 1 = pared normal, 2 = bloque rojo,
	# 3 = pared traspasable, 4 = bloque negro)
	var mapa_virtual = []
	for x in range(columnas):
		var fila_virtual = []
		for y in range(filas):
			fila_virtual.append(0)
		mapa_virtual.append(fila_virtual)

	var camino_prehecho = {}
	var camino_orden = []

	# Camino recto en los niveles 10, 15, 20 y 25 (la puerta siempre está abierta)
	var camino_recto = nivel_actual >= 10 and nivel_actual % 5 == 0
	if camino_recto:
		var ultima_col = columnas - 1
		for x in range(ultima_col + 1):
			agregar_camino(camino_prehecho, camino_orden, Vector2i(x, 5))
	else:
		# Camino serpenteante, distinto al del nivel anterior
		var alturas = generar_alturas()
		ultimo_camino = alturas.duplicate()

		agregar_camino(camino_prehecho, camino_orden, Vector2i(0, 5))
		for x in range(1, columnas - 1):  # columnas 1..16
			var y_ini = alturas[x - 1]
			var y_fin = alturas[x]
			var paso = 1 if y_fin >= y_ini else -1
			var y = y_ini
			while true:
				agregar_camino(camino_prehecho, camino_orden, Vector2i(x, y))
				if y == y_fin:
					break
				y += paso
		agregar_camino(camino_prehecho, camino_orden, Vector2i(columnas - 1, 5))

	# Niveles con rojos (11 al 15 y 21 al 25): tramos estrechos totalmente rodeados de rojo
	var con_rojos = nivel_actual >= nivel_corazones and (not es_oscuro or es_memoria)
	var forzadas_rojas = {}
	if con_rojos and not camino_recto:
		var cantidad_tramos = min(2 + (nivel_actual - nivel_corazones), 6)  # 11 -> 2 ... 14 -> 5, máximo 6
		for t in range(cantidad_tramos):
			var largo = randi_range(4, 6)
			var inicio = randi_range(3, max(3, camino_orden.size() - largo - 3))
			var fin = min(inicio + largo, camino_orden.size() - 3)
			for i in range(inicio, fin):
				var c = camino_orden[i]
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var v = Vector2i(c.x + dx, c.y + dy)
						if not camino_prehecho.has(v):
							forzadas_rojas[v] = true

	# Probabilidad de que una celda pegada al camino sea roja
	var prob_rojo_cerca = 0.45
	if es_memoria:
		prob_rojo_cerca = 0.6
	if nivel_actual == 15 or nivel_actual == 25:
		prob_rojo_cerca = 0.85

	# Relleno de la pantalla (el camino siempre queda libre)
	var densidad_random = min(0.55 + (nivel_actual * 0.02), 0.75)
	for x in range(columnas):
		for y in range(filas):
			var pos = Vector2i(x, y)
			if camino_prehecho.has(pos):
				continue

			# Rojos lejos del inicio y de la puerta
			var rojo_permitido = x >= 3 and x <= columnas - 3

			var pegada_al_camino = false
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if camino_prehecho.has(Vector2i(x + dx, y + dy)):
						pegada_al_camino = true

			if es_oscuro and not es_memoria:
				# Camino de 1 celda de ancho: no hay forma de rodear los bloques negros
				if pegada_al_camino or randf() < densidad_random:
					mapa_virtual[x][y] = 1
			elif con_rojos:
				if pegada_al_camino:
					# Alrededor del camino no queda espacio libre: solo rojo o pared
					if rojo_permitido and (forzadas_rojas.has(pos) or randf() < prob_rojo_cerca):
						mapa_virtual[x][y] = 2
					else:
						mapa_virtual[x][y] = 1
				elif randf() < densidad_random:
					# Resto de la pantalla: mezcla de paredes normales y rojos
					if rojo_permitido and randf() < 0.25:
						mapa_virtual[x][y] = 2
					else:
						mapa_virtual[x][y] = 1
			else:
				if randf() < densidad_random:
					mapa_virtual[x][y] = 1

	# NIVEL 10: bloque traspasable (parece pared normal) que esconde un pasillo
	# hacia el corazón dorado
	if nivel_actual == 10 and not tiene_dorado:
		var sx = randi_range(4, 13)
		var pasillo = [Vector2i(sx, 4), Vector2i(sx, 3), Vector2i(sx, 2), Vector2i(sx, 1)]
		# Rodeamos el pasillo con paredes sólidas para que la única entrada sea el bloque traspasable
		for c in pasillo:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var v = Vector2i(c.x + dx, c.y + dy)
					if v.x < 0 or v.x >= columnas or v.y < 0 or v.y >= filas:
						continue
					if pasillo.has(v) or camino_prehecho.has(v):
						continue
					mapa_virtual[v.x][v.y] = 1
		for c in pasillo:
			mapa_virtual[c.x][c.y] = 0
		mapa_virtual[sx][4] = 3  # 3 = pared traspasable
		crear_corazon_dorado(Vector2i(sx, 1))
		hay_secreto = true
		celda_secreta = Vector2i(sx, 4)

	# NIVELES OSCUROS: linterna en el camino y bloques negros que tapan el camino
	# más adelante (solo se pueden pasar con la linterna)
	if es_oscuro:
		var idx_linterna = clampi(int(camino_orden.size() * 0.3), 4, camino_orden.size() - 8)
		crear_linterna(camino_orden[idx_linterna])

		var cantidad_negros = 3 if camino_recto else min(2 + (nivel_actual - nivel_oscuridad), 5)  # 16 -> 2 ... máximo 5
		var disponibles = range(idx_linterna + 3, camino_orden.size() - 3)
		disponibles.shuffle()
		for i in range(min(cantidad_negros, disponibles.size())):
			var c = camino_orden[disponibles[i]]
			mapa_virtual[c.x][c.y] = 4

	# Pintamos paredes, bloques rojos y bloques negros
	for x in range(columnas):
		for y in range(filas):
			if mapa_virtual[x][y] == 1:
				colocar_pared(x, y)
			elif mapa_virtual[x][y] == 2:
				colocar_bloque_rojo(x, y)
			elif mapa_virtual[x][y] == 3:
				colocar_pared(x, y, true)
			elif mapa_virtual[x][y] == 4:
				crear_bloque_negro(x, y)

	# Reposicionamos al jugador
	if jugador:
		jugador.position = Vector2(96, 5 * tamaño_bloque + 32)
	else:
		crear_jugador_auxiliar()

	actualizar_luz()
	actualizar_velocidad()


# ==========================================
# FUNCIONES DE CREACIÓN DE ELEMENTOS
# ==========================================
func colocar_pared(x, y, traspasable = false):
	var nueva_pared = plantilla_pared.instantiate()
	nueva_pared.add_to_group("paredes")
	nueva_pared.position = Vector2(x * tamaño_bloque, y * tamaño_bloque)
	if traspasable:
		# Se ve igual que una pared, pero sin colisión: el jugador la atraviesa
		if nueva_pared is CollisionObject2D:
			nueva_pared.collision_layer = 0
			nueva_pared.collision_mask = 0
		for hijo in nueva_pared.get_children():
			if hijo is CollisionShape2D:
				hijo.set_deferred("disabled", true)
	add_child(nueva_pared)


# Doble pulsación de flecha arriba (en menos de 0.5 s) en el nivel 10:
# el bloque traspasable empieza a brillar
func _input(event):
	# Teclado (PC). En teléfonos lo registra el botón táctil de arriba.
	if event is InputEventKey and event.is_action_pressed("ui_up") and not event.is_echo():
		registrar_toque_arriba()


func registrar_toque_arriba():
	var ahora = Time.get_ticks_msec()
	if ahora - ultimo_toque_arriba <= 500:
		revelar_secreto()
		ultimo_toque_arriba = -10000
	else:
		ultimo_toque_arriba = ahora


func revelar_secreto():
	if nivel_actual != 10 or not hay_secreto or tiene_dorado:
		return
	# Si ya está brillando, no creamos otro
	for brillo in get_tree().get_nodes_in_group("brillos"):
		if is_instance_valid(brillo) and not brillo.is_queued_for_deletion():
			return

	var brillo = ColorRect.new()
	brillo.add_to_group("brillos")
	brillo.add_to_group("dorados")  # se borra junto con el nivel
	brillo.size = Vector2(tamaño_bloque, tamaño_bloque)
	brillo.position = Vector2(celda_secreta.x * tamaño_bloque, celda_secreta.y * tamaño_bloque)
	brillo.color = Color(1, 0.9, 0.2, 0.55)
	brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(brillo)

	# Pulso brillante continuo
	var tween = brillo.create_tween().set_loops()
	tween.tween_property(brillo, "modulate:a", 0.25, 0.4)
	tween.tween_property(brillo, "modulate:a", 1.0, 0.4)


func crear_corazon_dorado(celda: Vector2i):
	var area = Area2D.new()
	area.add_to_group("dorados")
	area.position = Vector2((celda.x + 0.5) * tamaño_bloque, (celda.y + 0.5) * tamaño_bloque)

	var corazon = crear_corazon(Vector2.ZERO)
	corazon.color = Color(1, 0.84, 0)
	corazon.scale = Vector2(1.3, 1.3)

	var colision = CollisionShape2D.new()
	var forma = CircleShape2D.new()
	forma.radius = 26
	colision.shape = forma

	area.add_child(corazon)
	area.add_child(colision)
	area.body_entered.connect(_on_dorado_tocado.bind(area))
	add_child(area)


func _on_dorado_tocado(body, area):
	if body != jugador or tiene_dorado:
		return
	tiene_dorado = true
	corazones_max = 4
	corazones = 4
	corazones_visuales[3].visible = true
	actualizar_corazones()
	area.queue_free()

	# Logro "Gold": se guarda en el dispositivo
	var primera_vez = not logro_gold
	logro_gold = true
	guardar_logros()

	if primera_vez:
		mostrar_mensaje("GOLDEN HEART!  ACHIEVEMENT: Gold", Color(1, 0.84, 0), 250)
	else:
		mostrar_mensaje("GOLDEN HEART!", Color(1, 0.84, 0), 400)


func colocar_bloque_rojo(x, y):
	var area = Area2D.new()
	area.add_to_group("rojos")
	area.position = Vector2(x * tamaño_bloque, y * tamaño_bloque)

	var grafico = ColorRect.new()
	grafico.size = Vector2(tamaño_bloque, tamaño_bloque)
	grafico.color = Color(0.9, 0.05, 0.05)

	var colision = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(tamaño_bloque, tamaño_bloque)
	colision.shape = forma
	colision.position = Vector2(tamaño_bloque / 2, tamaño_bloque / 2)

	area.add_child(grafico)
	area.add_child(colision)
	add_child(area)


# ==========================================
# OSCURIDAD: LUZ, LINTERNA Y BLOQUES NEGROS
# ==========================================
func crear_textura_luz() -> GradientTexture2D:
	var gradiente = Gradient.new()
	gradiente.set_color(0, Color(1, 1, 1, 1))
	gradiente.set_color(1, Color(1, 1, 1, 0))
	var textura = GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	textura.width = 512
	textura.height = 512
	return textura


# Luz pequeña sin linterna, luz grande con linterna (solo en niveles oscuros)
func actualizar_luz():
	if luz_jugador == null:
		return
	luz_jugador.enabled = nivel_actual >= nivel_oscuridad
	# En los niveles de memoria (21 a 25) la luz siempre es pequeña: hay que recordar el mapa
	if tiene_linterna and nivel_actual < nivel_memoria:
		luz_jugador.texture_scale = 1.1
	else:
		luz_jugador.texture_scale = 0.35


func crear_linterna(celda: Vector2i):
	var area = Area2D.new()
	area.add_to_group("linternas")
	area.position = Vector2((celda.x + 0.5) * tamaño_bloque, (celda.y + 0.5) * tamaño_bloque)

	var grafico = ColorRect.new()
	grafico.size = Vector2(20, 28)
	grafico.position = Vector2(-10, -14)
	grafico.color = Color(1, 0.95, 0.4)

	# Brillo suave para poder verla de lejos en la oscuridad
	var brillo = PointLight2D.new()
	brillo.texture = crear_textura_luz()
	brillo.texture_scale = 0.18
	brillo.energy = 1.5
	brillo.color = Color(1, 0.95, 0.5)

	var colision = CollisionShape2D.new()
	var forma = CircleShape2D.new()
	forma.radius = 24
	colision.shape = forma

	area.add_child(grafico)
	area.add_child(brillo)
	area.add_child(colision)
	area.body_entered.connect(_on_linterna_tomada.bind(area))
	add_child(area)


func _on_linterna_tomada(body, area):
	if body != jugador or tiene_linterna:
		return
	tiene_linterna = true
	area.queue_free()

	# Con la linterna los bloques negros dejan de bloquearte (y se ven apenas)
	for negro in get_tree().get_nodes_in_group("negros"):
		negro.set_deferred("collision_layer", 0)
		negro.set_deferred("collision_mask", 0)
		for hijo in negro.get_children():
			if hijo is ColorRect:
				hijo.color = Color(0.18, 0.18, 0.22)

	actualizar_luz()

	if nivel_actual >= nivel_memoria:
		# Niveles 21 a 25: se ve todo el mapa durante unos segundos para memorizarlo
		tiempo_revelado = tiempo_memoria
		oscuridad.color = Color(1, 1, 1)
		texto_memoria.visible = true
	else:
		mostrar_mensaje("¡LINTERNA ENCONTRADA!", Color(1, 1, 0.6), 340)


func crear_bloque_negro(x, y):
	var cuerpo = StaticBody2D.new()
	cuerpo.add_to_group("negros")
	cuerpo.position = Vector2(x * tamaño_bloque, y * tamaño_bloque)

	# Negro sobre fondo negro: no se ve, pero bloquea el paso
	var grafico = ColorRect.new()
	grafico.size = Vector2(tamaño_bloque, tamaño_bloque)
	grafico.color = Color(0, 0, 0)

	var colision = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(tamaño_bloque, tamaño_bloque)
	colision.shape = forma
	colision.position = Vector2(tamaño_bloque / 2, tamaño_bloque / 2)

	cuerpo.add_child(grafico)
	cuerpo.add_child(colision)
	add_child(cuerpo)


func crear_puerta_meta():
	puerta = Area2D.new()
	puerta.name = "PuertaMeta"

	var grafico = ColorRect.new()
	grafico.size = Vector2(32, 64)
	grafico.color = Color(0, 0.6, 1)

	var colision = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(32, 64)
	colision.shape = forma

	puerta.add_child(grafico)
	puerta.add_child(colision)
	puerta.position = Vector2((columnas - 1) * tamaño_bloque, 5 * tamaño_bloque)

	puerta.body_entered.connect(_on_puerta_tocada)
	add_child(puerta)


# ==========================================
# LÓGICA DE PROGRESIÓN DE NIVELES
# ==========================================
func _on_puerta_tocada(body):
	if body == jugador:
		# En los niveles oscuros la puerta solo sirve con la linterna
		if nivel_actual >= nivel_oscuridad and not tiene_linterna:
			mostrar_mensaje("NECESITAS LA LINTERNA", Color(1, 0.3, 0.3), 330)
			return
		# La puerta del último nivel termina la Alpha
		if nivel_actual >= nivel_final:
			terminar_alpha.call_deferred()
			return
		nivel_actual += 1
		texto_nivel.text = "NIVEL: " + str(nivel_actual)
		# Diferido para no modificar la física dentro de la señal
		generar_mapa_procedural.call_deferred()


# ==========================================
# FINAL DE LA ALPHA Y LOGROS
# ==========================================
# Al abrir el juego se lee el archivo guardado en el dispositivo
# para saber qué logros ya se consiguieron antes.
func cargar_logros():
	var archivo = ConfigFile.new()
	if archivo.load(ARCHIVO_LOGROS) == OK:
		logro_end = archivo.get_value("logros", "end", false)
		logro_gold = archivo.get_value("logros", "gold", false)


func guardar_logros():
	var archivo = ConfigFile.new()
	archivo.set_value("logros", "end", logro_end)
	archivo.set_value("logros", "gold", logro_gold)
	archivo.save(ARCHIVO_LOGROS)


# Pantalla final: "You finished the Alpha!" + logro ¿End?
func terminar_alpha():
	var primera_vez = not logro_end
	logro_end = true
	guardar_logros()

	get_tree().paused = true

	var capa_fin = CanvasLayer.new()
	capa_fin.layer = 100
	capa_fin.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(capa_fin)

	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 1)
	capa_fin.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro = CenterContainer.new()
	capa_fin.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var caja = VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 20)
	centro.add_child(caja)

	var puerta_deco = ColorRect.new()
	puerta_deco.color = Color(0, 0.6, 1)
	puerta_deco.custom_minimum_size = Vector2(60, 100)
	puerta_deco.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(puerta_deco)

	var titulo = Label.new()
	titulo.text = "YOU FINISHED THE ALPHA!"
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.modulate = Color(0, 0.6, 1)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)

	var aviso = Label.new()
	aviso.text = "ACHIEVEMENT UNLOCKED!" if primera_vez else "ACHIEVEMENT"
	aviso.add_theme_font_size_override("font_size", 26)
	aviso.modulate = Color(0.6, 0.6, 0.6)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(aviso)

	var nombre_logro = Label.new()
	nombre_logro.text = "¿End?"
	nombre_logro.add_theme_font_size_override("font_size", 52)
	nombre_logro.modulate = Color(1, 0.84, 0)
	nombre_logro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(nombre_logro)

	var boton_menu = Button.new()
	boton_menu.text = "MENU"
	boton_menu.custom_minimum_size = Vector2(280, 80)
	boton_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boton_menu.add_theme_font_size_override("font_size", 40)
	boton_menu.pressed.connect(_volver_al_menu)
	caja.add_child(boton_menu)
	boton_menu.grab_focus.call_deferred()


# Reinicia el juego desde el menú principal
func _volver_al_menu():
	get_tree().paused = false
	get_tree().reload_current_scene()


# ==========================================
# LÍMITES PERIMETRALES DE LA PANTALLA
# ==========================================
func _enter_tree():
	var ancho = 18 * 64
	var alto = 10 * 64
	crear_barrera_invisible(Vector2(ancho / 2, 0), Vector2(ancho, 10))
	crear_barrera_invisible(Vector2(ancho / 2, alto), Vector2(ancho, 10))
	crear_barrera_invisible(Vector2(0, alto / 2), Vector2(10, alto))
	crear_barrera_invisible(Vector2(ancho, alto / 2), Vector2(10, alto))


func crear_barrera_invisible(pos, tam):
	var b = StaticBody2D.new()
	var c = CollisionShape2D.new()
	var f = RectangleShape2D.new()
	f.size = tam
	c.shape = f
	b.add_child(c)
	b.position = pos
	add_child(b)


# ==========================================
# CREACIÓN Y MOVIMIENTO DEL JUGADOR
# ==========================================
func crear_jugador_auxiliar():
	jugador = CharacterBody2D.new()
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg")
	sprite.scale = Vector2(0.4, 0.4)

	var colision = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(50, 50)
	colision.shape = forma

	# Luz que acompaña al jugador en los niveles oscuros
	luz_jugador = PointLight2D.new()
	luz_jugador.texture = crear_textura_luz()
	luz_jugador.texture_scale = 0.35
	luz_jugador.energy = 1.3
	luz_jugador.enabled = false

	jugador.add_child(sprite)
	jugador.add_child(colision)
	jugador.add_child(luz_jugador)
	jugador.position = Vector2(96, 5 * 64 + 32)

	var script_jugador = GDScript.new()
	script_jugador.source_code = """
extends CharacterBody2D

var velocidad = 300.0

func _physics_process(delta):
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1

	velocity = dir.normalized() * velocidad
	move_and_slide()
"""
	script_jugador.reload()
	jugador.set_script(script_jugador)
	jugador.set("velocidad", velocidad_jugador)
	add_child(jugador)
