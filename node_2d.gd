extends Node2D

var plantilla_pared = preload("res://pared.tscn")

# ==========================================
# CONFIGURACIÓN Y VARIABLES DEL JUEGO
# ==========================================
var nivel_actual = 1
var nivel_final = 40          # Al terminar este nivel se acaba la Alpha
var nivel_armas = 36          # Desde este nivel tienes la pistola (niveles 36 a 40)
var nivel_dash = 38           # Desde este nivel tienes el dash
var nivel_jefe = 40           # Nivel del slime gigante
var nivel_slime = 26          # Niveles 26 a 35: slimes y bloques fantasma
var nivel_fuego = 31          # Desde este nivel hay bloques de fuego en el camino del disparo
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
var logro_modder = false        # logro "Modder": instalar cualquier mod
var logro_hitbox = false        # logro "Hitbox master": pasar los niveles 11 a 15 sin perder corazones rojos
var dano_en_rojos = false       # true si perdiste un corazón rojo en los niveles 11 a 15
var nombre_bloqueado = false    # true cuando confirmas el nombre con el check (ya no se puede cambiar)
var boton_check: Button

# Consola de comandos (tecla Z) y modo debug
var logro_door = false          # logro "Door": hacer click en la puerta del menú principal

# Partida guardada y menú de pausa
const ARCHIVO_PARTIDA = "user://partida.cfg"
var dispositivo_actual = "pc"   # opción elegida en el menú (pc / telefono)
var partida_en_curso = false    # true mientras se juega (para guardar al salir o cerrar el juego)
var pausa_capa: CanvasLayer
var boton_pausa: Button         # botón de pausa "||" (solo en la opción de teléfono)
var consola_capa: CanvasLayer

# Slime (niveles 26 a 35): empuja contra un slime y suéltalo. Cuanto más tiempo cargues, más lejos sales disparado
var tiempo_slime = 3.0           # a los 3 s sale disparado solo (fuerza máxima)
var velocidad_impulso = 1000.0   # velocidad del disparo
var tiempos_impulso = [0.35, 0.6, 0.8]  # 1 s, 2 s y 3 s de carga = unos 350, 600 y 800 píxeles
var slime_actual: Node = null    # slime contra el que estás empujando
var slime_dir = Vector2.ZERO     # dirección en la que empujas
var slime_tiempo = 0.0           # segundos que llevas cargando
var impulsando = false           # true mientras sales disparado
var texto_slime: Label           # contador sobre el personaje
var texto_tutorial: Label        # mini tutorial del nivel 26

# Pistola, dash y jefe (niveles 36 a 40)
var logro_slimekiller = false    # logro "Slime killer": matar al slime gigante del nivel 40
var tiene_arma = false
var tiene_dash = false
var mirando = Vector2.RIGHT      # hacia dónde mira el personaje (dirección del disparo y del dash)
var arma_nodo: Node2D            # dibujo de la pistola pegada al personaje
var sprite_jugador: Sprite2D
var fuego_cd = 0.0               # espera entre disparos
var fuego_tactil = false         # botón F pulsado (teléfono)
var dash_cd = 0.0                # espera entre dashes
var dash_activo = 0.0            # segundos de invencibilidad que quedan del dash
var boton_dash: TouchScreenButton
var boton_fuego: TouchScreenButton
var script_proyectil: GDScript
var jefe: Area2D = null
var jefe_vivo = false
var jefe_vida_max = 40
var jefe_vida = 40
var jefe_tiempo = 0.0
var jefe_cd = 2.0
var jefe_barra_fondo: ColorRect
var jefe_barra: ColorRect
var jefe_nombre: Label
var tutorial_dash_tiempo = 0.0
var tutorial_dash_esquivadas = 0
var tutorial_dash_activo = false
var consola_aviso: Label
var debug_activo = false        # true: atraviesas paredes y los rojos no hacen daño
var texto_debug: Label

# Nombre de usuario (máximo 10 letras, se escribe en el menú arriba a la izquierda)
var nombre_usuario = ""
var campo_nombre: LineEdit

# Mods: "base" = juego sin mods. Los demás hay que instalarlos desde la pestaña MODS.
var mod_activo = "base"
var mods_instalados: Array = ["base"]
var pagina_mods = 0
var lista_mods = [
	{
		"id": "base", "letras": "BASE", "nombre": "Base",
		"desc": "The base game, no mods",
		"fondo": Color(0.85, 0.85, 0.85), "texto": Color(0, 0, 0),
	},
	{
		"id": "ilp", "letras": "ILP", "nombre": "I love pink",
		"desc": "White blocks turn pink :3, red blocks turn purple >:3 and slimes turn sky blue",
		"fondo": Color(1, 0.55, 0.75), "texto": Color(0.3, 0.05, 0.2),
	},
	{
		"id": "ily", "letras": "ILY", "nombre": "I love yellow",
		"desc": "White blocks turn yellow, red blocks turn orange and slimes turn lime",
		"fondo": Color(0.93, 0.85, 0.5), "texto": Color(0.3, 0.2, 0),
	},
	{
		"id": "ilg", "letras": "ILG", "nombre": "I love green",
		"desc": "White blocks turn dark green, red blocks turn light green and slimes turn teal",
		"fondo": Color(0.1, 0.4, 0.15), "texto": Color(0.85, 1, 0.85),
	},
	{
		"id": "ilb", "letras": "ILB", "nombre": "I love blue",
		"desc": "White blocks turn very dark blue, red blocks turn dark sky blue and slimes turn violet",
		"fondo": Color(0.02, 0.05, 0.2), "texto": Color(0.5, 0.7, 1),
	},
	{
		"id": "ils", "letras": "ILS", "nombre": "I LOVE SLIME",
		"desc": "White blocks use the green slime model, red blocks and shots use red slime models",
		"fondo": Color(0.25, 0.85, 0.3), "texto": Color(0.05, 0.2, 0.05),
	},
]

# Controles táctiles: true = solo se ven en teléfonos; false = se ven siempre (útil para probar)
var botones_solo_en_movil = false

# Guarda las alturas del camino del nivel anterior para que el nuevo sea distinto
var ultimo_camino: Array = []

func _ready():
	randomize()
	agregar_teclas_wasd()
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

	# Aviso fijo mientras el modo debug está activo (abajo a la izquierda)
	texto_debug = Label.new()
	texto_debug.text = "DEBUG"
	texto_debug.position = Vector2(25, 520)  # arriba de los botones F y D
	texto_debug.scale = Vector2(1.5, 1.5)
	texto_debug.modulate = Color(0.3, 1, 0.3)
	texto_debug.visible = false
	capa_interfaz.add_child(texto_debug)

	# Contador del slime (sigue al personaje) y texto del mini tutorial
	texto_slime = Label.new()
	texto_slime.scale = Vector2(2.5, 2.5)
	texto_slime.modulate = Color(0.4, 1, 0.4)
	texto_slime.visible = false
	capa_interfaz.add_child(texto_slime)

	texto_tutorial = Label.new()
	texto_tutorial.position = Vector2(200, 85)
	texto_tutorial.scale = Vector2(1.6, 1.6)
	texto_tutorial.modulate = Color(1, 1, 0.5)
	texto_tutorial.visible = false
	capa_interfaz.add_child(texto_tutorial)

	# Barra de vida del slime gigante (nivel 40)
	jefe_barra_fondo = ColorRect.new()
	jefe_barra_fondo.color = Color(0, 0, 0, 0.8)
	jefe_barra_fondo.position = Vector2(326, 70)
	jefe_barra_fondo.size = Vector2(500, 24)
	jefe_barra_fondo.visible = false
	capa_interfaz.add_child(jefe_barra_fondo)
	jefe_barra = ColorRect.new()
	jefe_barra.position = Vector2(329, 73)
	jefe_barra.size = Vector2(494, 18)
	jefe_barra.color = Color(0.3, 0.9, 0.3)
	jefe_barra.visible = false
	capa_interfaz.add_child(jefe_barra)
	jefe_nombre = Label.new()
	jefe_nombre.text = "BIG SLIME"
	jefe_nombre.position = Vector2(326, 96)
	jefe_nombre.modulate = Color(0.8, 1, 0.8)
	jefe_nombre.visible = false
	capa_interfaz.add_child(jefe_nombre)

	crear_boton_pausa()
	crear_botones_accion()
	crear_controles_tactiles()
	crear_corazones_interfaz()
	crear_puerta_meta()
	generar_mapa_procedural()

	# Título de la ventana en PC y menú principal
	get_window().title = "The Blue Door"
	crear_menu_principal()


# En PC el personaje se mueve con las flechas o con WASD
func agregar_teclas_wasd():
	var teclas = {"ui_up": KEY_W, "ui_down": KEY_S, "ui_left": KEY_A, "ui_right": KEY_D}
	for accion in teclas:
		var evento = InputEventKey.new()
		evento.physical_keycode = teclas[accion]
		if not InputMap.action_has_event(accion, evento):
			InputMap.action_add_event(accion, evento)


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

	# Nombre de usuario: arriba a la izquierda, máximo 10 letras
	campo_nombre = LineEdit.new()
	campo_nombre.placeholder_text = "Username"
	campo_nombre.max_length = 10
	campo_nombre.text = nombre_usuario
	campo_nombre.position = Vector2(20, 20)
	campo_nombre.custom_minimum_size = Vector2(240, 50)
	campo_nombre.add_theme_font_size_override("font_size", 26)
	campo_nombre.text_changed.connect(_on_nombre_cambiado)
	campo_nombre.text_submitted.connect(func(_t): campo_nombre.release_focus())
	campo_nombre.editable = not nombre_bloqueado  # con el check puesto ya no se puede cambiar
	menu_capa.add_child(campo_nombre)

	# Check verde: aparece cuando hay un nombre escrito. Al pulsarlo el nombre queda fijo.
	boton_check = Button.new()
	boton_check.custom_minimum_size = Vector2(50, 50)
	boton_check.position = Vector2(270, 20)
	boton_check.tooltip_text = "Confirm name (it can't be changed later)"
	var marca = Line2D.new()
	marca.points = PackedVector2Array([Vector2(12, 27), Vector2(21, 37), Vector2(39, 14)])
	marca.width = 6
	marca.default_color = Color(0.2, 0.9, 0.3)
	boton_check.add_child(marca)
	boton_check.pressed.connect(_on_check_pulsado)
	menu_capa.add_child(boton_check)

	mostrar_pantalla_principal()


func _on_nombre_cambiado(nuevo: String):
	nombre_usuario = nuevo.strip_edges().left(10)
	guardar_logros()
	actualizar_check()


# El check solo se ve si hay un nombre escrito y todavía no se confirmó
func actualizar_check():
	boton_check.visible = campo_nombre.visible and nombre_usuario != "" and not nombre_bloqueado


func _on_check_pulsado():
	if nombre_usuario == "":
		return
	nombre_bloqueado = true
	campo_nombre.text = nombre_usuario
	campo_nombre.editable = false
	campo_nombre.release_focus()
	guardar_logros()
	actualizar_check()


# Pantalla principal: título y una fila con LOGROS (izquierda), JUGAR (centro) y MODS (derecha)
func mostrar_pantalla_principal():
	limpiar_menu()

	# Puerta azul decorativa
	var puerta_deco = ColorRect.new()
	puerta_deco.color = Color(0, 0.6, 1)
	puerta_deco.custom_minimum_size = Vector2(60, 100)
	puerta_deco.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	puerta_deco.mouse_filter = Control.MOUSE_FILTER_STOP
	puerta_deco.gui_input.connect(_on_puerta_menu_click)  # logro "Door"
	menu_caja.add_child(puerta_deco)

	crear_etiqueta_menu("THE BLUE DOOR", 72, Color(0, 0.6, 1))
	crear_etiqueta_menu("ALPHA 2.0", 24, Color(0.6, 0.6, 0.6))

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

	campo_nombre.visible = true
	actualizar_check()
	boton_jugar.grab_focus.call_deferred()  # en PC se puede pulsar con Enter


# Click en la puerta azul del menú: logro "Door" (solo la primera vez)
func _on_puerta_menu_click(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if logro_door:
			return
		logro_door = true
		guardar_logros()
		var aviso = Label.new()
		aviso.text = "ACHIEVEMENT UNLOCKED: Door"
		aviso.add_theme_font_size_override("font_size", 28)
		aviso.modulate = Color(1, 0.84, 0)
		aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		aviso.position = Vector2(0, 585)
		aviso.size = Vector2(1152, 40)
		menu_capa.add_child(aviso)
		await get_tree().create_timer(2.5).timeout
		if is_instance_valid(aviso):
			aviso.queue_free()


# Cierra el juego (en PC cierra la ventana, en teléfono vuelve al sistema)
func _on_salir_pulsado():
	guardar_logros()  # se guarda el mod de la última vez
	get_tree().quit()


# Quita lo que hay en el menú para mostrar otra pantalla
func limpiar_menu():
	if campo_nombre:
		campo_nombre.visible = false  # el nombre solo se ve en la pantalla principal
		boton_check.visible = false
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


# MODS: lista con foto (letras), descripción y botón INSTALAR / USAR / ACTIVO
func _on_mods_pulsado(logro_nuevo = false, pagina = 0):
	pagina_mods = pagina
	limpiar_menu()
	menu_caja.add_theme_constant_override("separation", 6)
	crear_etiqueta_menu("MODS  %d/2" % (pagina_mods + 1), 52, Color(0, 0.6, 1))

	var inicio = pagina_mods * 5
	var fin = mini(inicio + 5, lista_mods.size())
	for i in range(inicio, fin):
		crear_fila_mod(lista_mods[i])

	if logro_nuevo:
		crear_etiqueta_menu("ACHIEVEMENT UNLOCKED: Modder", 26, Color(1, 0.84, 0))

	var fila_paginas = HBoxContainer.new()
	fila_paginas.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_paginas.add_theme_constant_override("separation", 20)
	menu_caja.add_child(fila_paginas)
	if pagina_mods > 0:
		var anterior = crear_boton_flecha(fila_paginas, false)
		anterior.pressed.connect(_on_mods_pulsado.bind(false, pagina_mods - 1))
	var volver = crear_boton_en(fila_paginas, "VOLVER", 240, 60, 30)
	volver.pressed.connect(_volver_de_mods)
	if pagina_mods < 1:
		var siguiente = crear_boton_flecha(fila_paginas, true)
		siguiente.pressed.connect(_on_mods_pulsado.bind(false, pagina_mods + 1))
	volver.grab_focus.call_deferred()


func _volver_de_mods():
	menu_caja.add_theme_constant_override("separation", 20)
	mostrar_pantalla_principal()


# Una fila de la lista de mods: [foto con letras]  nombre + descripción  [botón]
func crear_fila_mod(mod: Dictionary):
	var fila = HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 20)
	menu_caja.add_child(fila)

	# Foto del mod: un cuadro de color con sus letras
	var foto = ColorRect.new()
	foto.color = mod["fondo"]
	foto.custom_minimum_size = Vector2(66, 66)  # chica para que quepan 5 mods
	fila.add_child(foto)
	var letras = Label.new()
	letras.text = mod["letras"]
	letras.add_theme_font_size_override("font_size", 28 if mod["letras"].length() <= 3 else 22)
	letras.add_theme_color_override("font_color", mod["texto"])
	letras.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letras.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foto.add_child(letras)
	letras.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Nombre y descripción
	var textos = VBoxContainer.new()
	textos.custom_minimum_size = Vector2(560, 0)
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_child(textos)
	var nombre = Label.new()
	nombre.text = mod["nombre"]
	nombre.add_theme_font_size_override("font_size", 28)
	nombre.modulate = Color(1, 1, 1)
	textos.add_child(nombre)
	var desc = Label.new()
	desc.text = mod["desc"]
	desc.add_theme_font_size_override("font_size", 18)
	desc.modulate = Color(0.65, 0.65, 0.65)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(desc)

	# Botón según el estado del mod
	var boton = crear_boton_en(fila, "", 200, 54, 24)
	if mod["id"] == mod_activo:
		boton.text = "ACTIVO"
		boton.disabled = true
	elif mods_instalados.has(mod["id"]):
		boton.text = "USAR"
		boton.pressed.connect(_usar_mod.bind(mod["id"]))
	else:
		boton.text = "INSTALAR"
		boton.pressed.connect(_instalar_mod.bind(mod["id"]))


# Instalar un mod (el logro "Modder" se consigue con el primero que instales)
func _instalar_mod(id: String):
	if not mods_instalados.has(id):
		mods_instalados.append(id)
	var primera_vez = not logro_modder
	logro_modder = true
	guardar_logros()
	_on_mods_pulsado(primera_vez, pagina_mods)


func _usar_mod(id: String):
	mod_activo = id
	guardar_logros()
	_on_mods_pulsado(false, pagina_mods)


# Colores y caras de los bloques según el mod activo (null = juego base)
func obtener_skin(rojo: bool):
	match mod_activo:
		"ilp":
			if rojo:
				return {"color": Color(0.6, 0.2, 0.85), "cara": ">:3"}
			return {"color": Color(1, 0.55, 0.75), "cara": ":3"}
		"ily":
			if rojo:
				return {"color": Color(1, 0.55, 0.05), "cara": ""}
			return {"color": Color(0.93, 0.85, 0.5), "cara": ""}  # amarillo suave
		"ilg":
			if rojo:
				return {"color": Color(0.5, 0.8, 0.5), "cara": ""}  # verde claro suave
			return {"color": Color(0.1, 0.4, 0.15), "cara": ""}  # verde oscuro
		"ils":
			# ILS reutiliza el modelo habitual de slime: verde en bloques blancos y rojo en bloques rojos.
			if rojo:
				return {"color": Color(0.9, 0.05, 0.05), "cara": ""}
			return {"color": Color(0.25, 0.85, 0.3), "cara": ""}
		"ilb":
			if rojo:
				return {"color": Color(0.2, 0.5, 0.75), "cara": ""}  # celeste oscuro
			return {"color": Color(0.02, 0.04, 0.18), "cara": ""}  # azul muy oscuro
	return null


# Cubre un bloque con un cuadro de color (y una carita si el mod la tiene)
func poner_skin(bloque: Node, skin: Dictionary):
	var cubierta = ColorRect.new()
	cubierta.size = Vector2(tamaño_bloque, tamaño_bloque)
	cubierta.color = skin["color"]
	cubierta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloque.add_child(cubierta)

	if mod_activo == "ils":
		# Usa el mismo modelo visual de los slimes normales/enemigos, sin inventar otra textura.
		cubierta.color = Color(0, 0, 0, 0)
		agregar_modelo_slime(cubierta, Vector2(tamaño_bloque, tamaño_bloque), skin["color"])
	elif skin["cara"] != "":
		var cara = Label.new()
		cara.text = skin["cara"]
		cara.add_theme_font_size_override("font_size", 26)
		cara.add_theme_color_override("font_color", Color(0.25, 0.05, 0.2))
		cara.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cara.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cara.size = Vector2(tamaño_bloque, tamaño_bloque)
		cara.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cubierta.add_child(cara)


# LOGROS: 3 espacios. Los que no se han descubierto muestran "..."
# Logro 1: "¿End?" (terminar la Alpha). Logro 2: "Gold" (conseguir el corazón dorado).
func _on_logros_pulsado(pagina = 0):
	limpiar_menu()
	menu_caja.add_theme_constant_override("separation", 6)  # 4 logros: menos espacio para que quepan
	crear_etiqueta_menu("LOGROS  %d/2" % (pagina + 1), 52, Color(0, 0.6, 1))

	if pagina == 0:
		mostrar_logro(logro_end, "¿End?", "Finish the Alpha")
		mostrar_logro(logro_gold, "Gold", "Heart of gold!")
		mostrar_logro(logro_modder, "Modder", "Download a mod")
		mostrar_logro(logro_hitbox, "Hitbox master", "Clear levels 11-15 without taking damage")
	else:
		# Página 2: logros que todavía no existen en esta versión (siguen sin descubrir)
		mostrar_logro(logro_door, "Door", "Click the door in the menu")
		mostrar_logro(logro_slimekiller, "Slime killer", "Kill the big slime in level 40")
		for i in range(2):
			mostrar_logro(false, "", "")

	# Fila inferior: [flecha izquierda]  VOLVER  [flecha derecha]
	var fila = HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 20)
	menu_caja.add_child(fila)

	if pagina > 0:
		var anterior = crear_boton_flecha(fila, false)
		anterior.pressed.connect(_on_logros_pulsado.bind(pagina - 1))
	var volver = crear_boton_en(fila, "VOLVER", 240, 60, 36)
	volver.pressed.connect(_volver_de_mods)
	volver.grab_focus.call_deferred()
	if pagina < 1:
		var siguiente = crear_boton_flecha(fila, true)
		siguiente.pressed.connect(_on_logros_pulsado.bind(pagina + 1))


# Botón con una flecha dibujada (derecha o izquierda) para cambiar de página
func crear_boton_flecha(padre: Node, hacia_derecha: bool) -> Button:
	var boton = Button.new()
	boton.custom_minimum_size = Vector2(70, 60)
	var flecha = Polygon2D.new()
	var puntos = PackedVector2Array([Vector2(-10, -16), Vector2(14, 0), Vector2(-10, 16)])
	if not hacia_derecha:
		puntos = PackedVector2Array([Vector2(10, -16), Vector2(-14, 0), Vector2(10, 16)])
	flecha.polygon = puntos
	flecha.position = Vector2(35, 30)
	flecha.color = Color(1, 1, 1)
	boton.add_child(flecha)
	padre.add_child(boton)
	return boton


# Un logro en la lista: si no se ha conseguido muestra "..."
func mostrar_logro(conseguido: bool, nombre: String, descripcion: String):
	if conseguido:
		crear_etiqueta_menu(nombre, 38, Color(1, 0.84, 0))
		crear_etiqueta_menu(descripcion, 20, Color(0.6, 0.6, 0.6))
	else:
		crear_etiqueta_menu("...", 38, Color(0.6, 0.6, 0.6))


func _on_jugar_pulsado():
	# Segunda pantalla del menú: ¿En qué juegas?
	limpiar_menu()

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

	boton_pausa.visible = dispositivo == "telefono"
	dispositivo_actual = dispositivo

	# Si hay una partida guardada con este mismo dispositivo, se pregunta si quieres cargarla
	if existe_partida_guardada(dispositivo):
		preguntar_cargar_partida()
	else:
		iniciar_juego()


# Pregunta (en inglés) si se carga la partida guardada
func preguntar_cargar_partida():
	limpiar_menu()
	var archivo = ConfigFile.new()
	archivo.load(ARCHIVO_PARTIDA)
	var nivel_guardado = int(archivo.get_value("partida", "nivel", 1))

	crear_etiqueta_menu("Load save file?", 56, Color(0, 0.6, 1))
	crear_etiqueta_menu("Saved game: level %d" % nivel_guardado, 26, Color(0.6, 0.6, 0.6))

	var si = crear_boton_menu("YES")
	si.pressed.connect(_on_cargar_si)
	var no = crear_boton_menu("NO")
	no.pressed.connect(iniciar_juego)
	si.grab_focus.call_deferred()


func _on_cargar_si():
	cargar_partida()
	iniciar_juego()


# Cierra el menú y empieza a jugar
func iniciar_juego():
	menu_capa.queue_free()
	partida_en_curso = true
	# Regeneramos el nivel para que ya use el mod elegido (y el nivel cargado)
	generar_mapa_procedural()
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
	# Niveles 26 a 35: bloques slime
	if nivel_actual >= nivel_slime:
		procesar_slime(delta)

	# Niveles 36 a 40: pistola, dash y jefe
	if nivel_actual >= nivel_armas:
		procesar_armas(delta)

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
	# (mientras sales disparado por un slime vuelas por encima y no recibes daño)
	# (durante el dash también eres invencible)
	if nivel_actual < nivel_corazones or jugador == null or tiempo_invulnerable > 0 or reiniciando or debug_activo or impulsando or dash_activo > 0:
		return
	for rojo in get_tree().get_nodes_in_group("rojos"):
		if rojo.is_queued_for_deletion():
			continue
		if jugador in rojo.get_overlapping_bodies():
			recibir_dano()
			return


func recibir_dano():
	# Hitbox master: en los niveles 11 a 15 cuenta perder un corazón ROJO.
	# Perder el dorado (el 4.º corazón) no cuenta.
	if nivel_actual >= nivel_lento_desde and nivel_actual <= nivel_lento_hasta and corazones <= 3:
		dano_en_rojos = true
	corazones -= 1
	actualizar_corazones()

	if corazones <= 0:
		# Sin corazones: vuelves al nivel 11 (o al 21 si estabas en los niveles de memoria)
		# con corazones nuevos y un mapa nuevo.
		# "reiniciando" bloquea el daño hasta que el jugador reaparezca.
		if nivel_actual >= nivel_armas:
			nivel_actual = nivel_armas
		elif nivel_actual >= nivel_slime:
			nivel_actual = nivel_slime
		elif nivel_actual >= nivel_memoria:
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
	for slime in get_tree().get_nodes_in_group("slimes"):
		slime.queue_free()
	for pasa in get_tree().get_nodes_in_group("pasas"):
		pasa.queue_free()
	for flecha in get_tree().get_nodes_in_group("flechas"):
		flecha.queue_free()
	reiniciar_slime()
	reiniciar_armas()
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

	# Los niveles 26 a 35 (slime) tienen luz normal: no hay linterna
	var es_oscuro = nivel_actual >= nivel_oscuridad and nivel_actual < nivel_slime
	var es_memoria = nivel_actual >= nivel_memoria

	# Al empezar el nivel 11 (o reaparecer en él) empieza el intento de Hitbox master
	if nivel_actual == nivel_corazones:
		dano_en_rojos = false

	# Al entrar a los niveles de memoria (21) y de slime (26) los corazones se reinician
	if nivel_actual == nivel_memoria or nivel_actual == nivel_slime or nivel_actual == nivel_armas:
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

	# NIVELES 26 A 35: mapa especial con slimes y bloques fantasma
	texto_tutorial.visible = false
	puerta.visible = true
	tutorial_dash_activo = false
	# (los niveles 36 a 39 usan el generador normal de bloques rojos; el 40 es el jefe)
	if nivel_actual >= nivel_slime and nivel_actual < nivel_armas:
		generar_nivel_slime()
		terminar_generacion()
		return
	if nivel_actual == 39:
		generar_nivel_dash()
		terminar_generacion()
		return
	if nivel_actual == nivel_jefe:
		generar_nivel_jefe()
		terminar_generacion()
		return

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
	# El corazón dorado siempre aparece; el logro "Gold" solo se da la primera vez
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
		# La linterna está lejos del inicio (más o menos a la mitad del camino)
		var idx_linterna = clampi(int(camino_orden.size() * 0.55), 8, camino_orden.size() - 10)
		crear_linterna(camino_orden[idx_linterna])

		var cantidad_negros = 3 if camino_recto else min(2 + (nivel_actual - nivel_oscuridad), 5)  # 16 -> 2 ... máximo 5
		var disponibles = range(idx_linterna + 3, camino_orden.size() - 3)
		disponibles.shuffle()
		for i in range(min(cantidad_negros, disponibles.size())):
			var c = camino_orden[disponibles[i]]
			mapa_virtual[c.x][c.y] = 4

		# Siempre hay un bloque negro justo enfrente de la puerta: sin linterna no se puede llegar a ella
		mapa_virtual[columnas - 2][5] = 4

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

	# Niveles 36 a 39: slimes pequeños sobre el camino
	if nivel_actual >= nivel_armas:
		crear_enemigos_slime(camino_orden)

	terminar_generacion()


# Final común de todos los niveles: jugador, luz, velocidad y debug
func terminar_generacion():
	# Reposicionamos al jugador
	if jugador:
		jugador.position = Vector2(96, 5 * tamaño_bloque + 32)
	else:
		crear_jugador_auxiliar()

	actualizar_luz()
	actualizar_velocidad()
	if debug_activo:
		aplicar_debug()  # las paredes del nivel nuevo también se atraviesan

	# Pistola desde el nivel 36 y dash desde el 38
	tiene_arma = nivel_actual >= nivel_armas
	tiene_dash = nivel_actual >= nivel_dash
	actualizar_arma_visual()
	actualizar_botones_accion()
	var es_tel = dispositivo_actual == "telefono"
	if nivel_actual == nivel_armas:
		mostrar_mensaje.call_deferred("GUN!  " + ("F" if es_tel else "CLICK") + " = shoot", Color(1, 0.84, 0), 330)
	elif nivel_actual == nivel_dash:
		mostrar_mensaje.call_deferred("DASH!  " + ("D" if es_tel else "SHIFT") + " = dash", Color(0.5, 0.9, 1), 330)


# ==========================================
# NIVELES 26 A 35: SLIME, BLOQUES FANTASMA, FUEGO Y TUTORIAL
# ==========================================
# Cada nivel es una fila de "salas" separadas por muros con un bloque fantasma.
# El bloque fantasma solo se puede cruzar mientras sales disparado por un slime.
# Cada sala tiene su slime pegado al muro de la izquierda, en la misma fila que el
# bloque fantasma de su muro: empuja contra el slime y salta hacia él.
# La fuerza del disparo depende de los segundos que cargues (1, 2 o 3).
func generar_nivel_slime():
	# Tamaño de cada sala (celdas libres entre el slime y el muro).
	# Se mezclan en orden aleatorio en cada intento, pero siempre hay camino de un slime al siguiente.
	# Sala de 1 a 5 = basta 1 s de carga, de 7 a 9 = hacen falta 2 s, de 10 a 12 = hacen falta 3 s.
	var planos_gaps = {
		26: [9],
		27: [6, 4],
		28: [4, 2, 2],
		29: [3, 2, 1, 1],
		30: [2, 1, 1, 1, 1],
		31: [7, 4],
		32: [12, 1],
		33: [4, 7],
		34: [9, 3],
		35: [11, 2],
	}
	var gaps = planos_gaps.get(nivel_actual, [2, 1, 1, 1, 1]).duplicate()
	if nivel_actual != nivel_slime:
		gaps.shuffle()  # el nivel 26 es el tutorial y siempre es igual

	# Columna de cada muro según los tamaños de sala
	var puertas = []
	var inicio_sala = 0
	for g in gaps:
		var w = inicio_sala + g + 1
		puertas.append(w)
		inicio_sala = w + 1
	var n = puertas.size()

	# Fila por la que se cruza cada muro (distinta a la del muro anterior)
	var filas_paso = []
	for k in range(n):
		var f = randi_range(1, filas - 2)
		if nivel_actual == nivel_slime:
			f = 5  # el tutorial es recto
		while k > 0 and f == filas_paso[k - 1]:
			f = randi_range(1, filas - 2)
		filas_paso.append(f)

	# Muros con su bloque fantasma
	for k in range(n):
		for y in range(filas):
			if y == filas_paso[k]:
				crear_bloque_pasa(puertas[k], y)
			else:
				colocar_pared(puertas[k], y)

	# Slimes: el primero al borde izquierdo y los demás pegados al muro anterior
	for k in range(n):
		var col_slime = 0 if k == 0 else puertas[k - 1] + 1
		crear_slime(col_slime, filas_paso[k])

	# Bloques de fuego (niveles 31 a 35): ocupan la fila del disparo antes del bloque fantasma.
	# Si te impulsas poco caes en el fuego; si te impulsas mucho pasas volando por encima.
	if nivel_actual >= nivel_fuego:
		for k in range(n):
			var col_slime_f = 0 if k == 0 else puertas[k - 1] + 1
			for x in range(col_slime_f + 3, puertas[k]):
				colocar_bloque_rojo(x, filas_paso[k])

	# Bloques rojos sueltos en las salas (desde el nivel 28). Nunca tapan la fila de aterrizaje,
	# la fila del disparo ni la columna junto al slime, así que siempre hay camino.
	var rojos_total = 0
	if nivel_actual >= 28:
		rojos_total = mini((nivel_actual - 27) * 2, 12)
	var celdas_rojas = []
	for k in range(n):
		var lo = 0 if k == 0 else puertas[k - 1] + 1
		var hi = puertas[k] - 1
		for x in range(lo + 2, hi + 1):
			for y in range(filas):
				if y == filas_paso[k] or (k > 0 and y == filas_paso[k - 1]):
					continue
				if k == 0 and (y == 5 or x < 3):
					continue
				celdas_rojas.append(Vector2i(x, y))
	celdas_rojas.shuffle()
	for i in range(min(rojos_total, celdas_rojas.size())):
		colocar_bloque_rojo(celdas_rojas[i].x, celdas_rojas[i].y)

	# Mini tutorial del nivel 26: texto y flechas parpadeantes
	if nivel_actual == nivel_slime:
		texto_tutorial.text = "Push into the SLIME: 1, 2 or 3 s = more power"
		texto_tutorial.visible = true
		# Flechas hacia atrás, hacia el slime
		for x in [215, 150, 85]:
			crear_flecha_tutorial(Vector2(x, 4 * tamaño_bloque + 32), false)
		# Flechas hacia adelante, hacia el bloque fantasma
		for x in [420, 490, 560]:
			crear_flecha_tutorial(Vector2(x, 4 * tamaño_bloque + 32), true)
	elif nivel_actual == nivel_fuego:
		texto_tutorial.text = "Fire! Hold longer to fly over it"
		texto_tutorial.visible = true


func agregar_modelo_slime(padre: Node, tam: Vector2, color_cuerpo: Color):
	# Modelo reutilizado para slimes normales, bloques del mod y proyectiles ILS.
	var cuerpo = ColorRect.new()
	cuerpo.size = tam
	cuerpo.color = color_cuerpo
	cuerpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(cuerpo)

	var brillo = ColorRect.new()
	brillo.size = Vector2(maxf(4.0, tam.x - tam.x * 0.28), maxf(2.0, tam.y * 0.14))
	brillo.position = Vector2(tam.x * 0.14, tam.y * 0.12)
	brillo.color = Color(1, 1, 1, 0.3)
	brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(brillo)

	# Ojos escalados al tamaño del modelo para que también se reconozca en miniatura.
	for factor_x in [0.30, 0.64]:
		var ojo = ColorRect.new()
		ojo.size = Vector2(maxf(2.0, tam.x * 0.14), maxf(2.0, tam.y * 0.18))
		ojo.position = Vector2(tam.x * factor_x, tam.y * 0.48)
		ojo.color = Color(1, 1, 1)
		ojo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		padre.add_child(ojo)
		var pupila = ColorRect.new()
		pupila.size = Vector2(maxf(1.0, tam.x * 0.06), maxf(1.0, tam.y * 0.08))
		pupila.position = ojo.position + Vector2(ojo.size.x * 0.35, ojo.size.y * 0.35)
		pupila.color = Color(0, 0, 0)
		pupila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		padre.add_child(pupila)


func color_slime() -> Color:
	# Cada texture pack tiene su color de slime para combinar
	match mod_activo:
		"ilp":
			return Color(0.45, 0.8, 1.0)   # celeste
		"ily":
			return Color(0.65, 0.85, 0.35)  # verde lima
		"ilg":
			return Color(0.2, 0.75, 0.75)   # turquesa
		"ils":
			return Color(0.12, 0.72, 0.18)    # verde slime brillante
		"ilb":
			return Color(0.7, 0.45, 1.0)    # violeta
	return Color(0.25, 0.85, 0.3)           # verde slime


func crear_slime(cx: int, cy: int):
	var cuerpo = StaticBody2D.new()
	cuerpo.add_to_group("slimes")
	cuerpo.position = Vector2(cx * tamaño_bloque, cy * tamaño_bloque)

	var grafico = ColorRect.new()
	grafico.size = Vector2(tamaño_bloque, tamaño_bloque)
	grafico.color = color_slime()
	cuerpo.add_child(grafico)

	# Brillo y carita para que se vea como un slime
	var brillo = ColorRect.new()
	brillo.size = Vector2(tamaño_bloque - 12, 10)
	brillo.position = Vector2(6, 5)
	brillo.color = Color(1, 1, 1, 0.3)
	cuerpo.add_child(brillo)
	for ojo_x in [18, 40]:
		var ojo = ColorRect.new()
		ojo.size = Vector2(9, 11)
		ojo.position = Vector2(ojo_x, 24)
		ojo.color = Color(1, 1, 1)
		cuerpo.add_child(ojo)
		var pupila = ColorRect.new()
		pupila.size = Vector2(4, 5)
		pupila.position = Vector2(ojo_x + 3, 28)
		pupila.color = Color(0, 0, 0)
		cuerpo.add_child(pupila)

	var colision = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(tamaño_bloque, tamaño_bloque)
	colision.shape = forma
	colision.position = Vector2(tamaño_bloque / 2, tamaño_bloque / 2)
	cuerpo.add_child(colision)
	add_child(cuerpo)


# Bloque fantasma: sólido, pero solo se atraviesa mientras sales disparado por un slime
func crear_bloque_pasa(cx: int, cy: int):
	var cuerpo = StaticBody2D.new()
	cuerpo.add_to_group("pasas")
	cuerpo.position = Vector2(cx * tamaño_bloque, cy * tamaño_bloque)

	var c = color_slime()
	var grafico = ColorRect.new()
	grafico.size = Vector2(tamaño_bloque, tamaño_bloque)
	grafico.color = Color(c.r, c.g, c.b, 0.4)
	cuerpo.add_child(grafico)

	# Borde del color del slime
	var borde = ReferenceRect.new()
	borde.size = Vector2(tamaño_bloque, tamaño_bloque)
	borde.border_color = c
	borde.border_width = 3.0
	borde.editor_only = false
	cuerpo.add_child(borde)

	var colision = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(tamaño_bloque, tamaño_bloque)
	colision.shape = forma
	colision.position = Vector2(tamaño_bloque / 2, tamaño_bloque / 2)
	cuerpo.add_child(colision)
	add_child(cuerpo)


# Flecha parpadeante del tutorial
func crear_flecha_tutorial(pos: Vector2, hacia_derecha: bool):
	var flecha = Polygon2D.new()
	flecha.add_to_group("flechas")
	var puntos = PackedVector2Array([Vector2(-14, -12), Vector2(14, 0), Vector2(-14, 12)])
	if not hacia_derecha:
		puntos = PackedVector2Array([Vector2(14, -12), Vector2(-14, 0), Vector2(14, 12)])
	flecha.polygon = puntos
	flecha.position = pos
	flecha.color = Color(1, 1, 0.4)
	add_child(flecha)

	var tween = flecha.create_tween().set_loops()
	tween.tween_property(flecha, "modulate:a", 0.15, 0.45)
	tween.tween_property(flecha, "modulate:a", 1.0, 0.45)


# ==========================================
# NIVELES 36 A 40: PISTOLA, DASH Y EL SLIME GIGANTE
# ==========================================
# Colores según el texture pack: el fuego es el color de los bloques rojos del pack
func color_fuego() -> Color:
	match mod_activo:
		"ilp":
			return Color(0.6, 0.2, 0.85)
		"ily":
			return Color(1, 0.55, 0.05)
		"ilg":
			return Color(0.5, 0.8, 0.5)
		"ilb":
			return Color(0.2, 0.5, 0.75)
		"ils":
			return Color(0.9, 0.06, 0.08) # disparos rojos para ILS
	return Color(0.9, 0.05, 0.05)


# La pistola es negra en el juego base y toma un tono oscuro del color del pack
func color_arma() -> Color:
	var skin = obtener_skin(false)
	# Sin pack (juego base) la pistola es negra
	if typeof(skin) != TYPE_DICTIONARY or not skin.has("color"):
		return Color(0.04, 0.04, 0.04)
	var color_base: Color = skin
	return color_base.darkened(0.55)


# Dibuja la pistola (cañón + empuñadura) pegada al personaje
func crear_arma():
	arma_nodo = Node2D.new()
	arma_nodo.position = Vector2(0, 4)
	arma_nodo.visible = false
	jugador.add_child(arma_nodo)
	construir_arma()


# Cada texture pack tiene su propia pistola con otra forma y otros colores.
# La pistola apunta hacia la derecha; el nodo entero gira hacia donde apuntas.
func construir_arma():
	for parte in arma_nodo.get_children():
		arma_nodo.remove_child(parte)
		parte.queue_free()

	match mod_activo:
		"ilp":
			# Pistola rosa: cañón corto y gordito, punta morada y carita :3
			parte_arma(12, -8, 24, 12, Color(1, 0.55, 0.75))
			parte_arma(36, -8, 7, 12, Color(0.6, 0.2, 0.85))
			parte_arma(15, 4, 10, 14, Color(0.6, 0.2, 0.85))
			parte_arma(20, 4, 4, 4, Color(1, 0.8, 0.9))
			var cara = Label.new()
			cara.text = ":3"
			cara.add_theme_font_size_override("font_size", 11)
			cara.add_theme_color_override("font_color", Color(0.3, 0.05, 0.2))
			cara.position = Vector2(15, -10)
			arma_nodo.add_child(cara)
		"ily":
			# Pistola amarilla: cuerpo grueso con rayas y punta naranja
			parte_arma(12, -8, 28, 12, Color(0.93, 0.85, 0.5))
			parte_arma(18, -8, 4, 12, Color(1, 0.55, 0.05))
			parte_arma(26, -8, 4, 12, Color(1, 0.55, 0.05))
			parte_arma(40, -7, 5, 10, Color(1, 0.55, 0.05))
			parte_arma(14, 4, 11, 14, Color(1, 0.55, 0.05))
		"ilg":
			# Pistola verde: cañón largo y fino con mira y cargador claro
			parte_arma(12, -5, 32, 7, Color(0.1, 0.4, 0.15))
			parte_arma(44, -6, 5, 9, Color(0.5, 0.8, 0.5))
			parte_arma(38, -9, 4, 4, Color(0.5, 0.8, 0.5))
			parte_arma(13, 2, 8, 16, Color(0.1, 0.4, 0.15))
			parte_arma(22, 2, 6, 10, Color(0.5, 0.8, 0.5))
		"ilb":
			# Pistola azul futurista: cuerpo oscuro con franja celeste brillante
			parte_arma(12, -7, 30, 10, Color(0.02, 0.04, 0.18))
			parte_arma(16, -4, 22, 3, Color(0.2, 0.5, 0.75))
			parte_arma(42, -6, 6, 8, Color(0.2, 0.5, 0.75))
			parte_arma(14, 3, 9, 14, Color(0.02, 0.04, 0.18))
			parte_arma(14, 16, 9, 3, Color(0.2, 0.5, 0.75))
		"ils":
			# Pistola I LOVE SLIME: cuerpo verde, núcleo brillante, cañón lima y cargador orgánico.
			parte_arma(12, -8, 30, 12, Color(0.12, 0.48, 0.12))
			parte_arma(17, -5, 19, 4, Color(0.2, 1.0, 0.15))
			parte_arma(40, -7, 8, 10, Color(0.55, 1.0, 0.1))
			parte_arma(15, 4, 10, 14, Color(0.12, 0.48, 0.12))
			parte_arma(17, 7, 6, 5, Color(0.55, 1.0, 0.1))
		_:
			# Pistola básica negra
			parte_arma(14, -6, 24, 9, Color(0.04, 0.04, 0.04))
			parte_arma(15, 2, 9, 15, Color(0.04, 0.04, 0.04))
			parte_arma(36, -8, 3, 3, Color(0.3, 0.3, 0.3))


# Una pieza rectangular de la pistola
func parte_arma(x: float, y: float, ancho: float, alto: float, color: Color):
	var pieza = ColorRect.new()
	pieza.position = Vector2(x, y)
	pieza.size = Vector2(ancho, alto)
	pieza.color = color
	pieza.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arma_nodo.add_child(pieza)


func actualizar_arma_visual():
	if arma_nodo == null:
		return
	arma_nodo.visible = tiene_arma
	construir_arma()  # por si cambiaste de texture pack desde el menú


# Botones D (dash) y F (disparo) para teléfonos
func crear_botones_accion():
	# F en la esquina de abajo a la izquierda y D justo a su lado
	boton_fuego = crear_boton_accion("F", Vector2(55, 585), _fuego_pulsado, _fuego_soltado)
	boton_dash = crear_boton_accion("D", Vector2(145, 585), intentar_dash, _sin_accion)


func _fuego_pulsado():
	fuego_tactil = true


func _fuego_soltado():
	fuego_tactil = false


func _sin_accion():
	pass


func crear_boton_accion(texto: String, pos: Vector2, al_pulsar: Callable, al_soltar: Callable) -> TouchScreenButton:
	var lado = 70
	var boton = TouchScreenButton.new()
	boton.position = pos
	boton.visible = false
	var forma = RectangleShape2D.new()
	forma.size = Vector2(lado, lado)
	boton.shape = forma

	var fondo = ColorRect.new()
	fondo.size = Vector2(lado, lado)
	fondo.position = Vector2(-lado / 2, -lado / 2)
	fondo.color = Color(0, 0, 0, 0.9)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(fondo)

	var etiqueta = Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", 40)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.size = Vector2(lado, lado)
	etiqueta.position = Vector2(-lado / 2, -lado / 2)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(etiqueta)

	boton.pressed.connect(func():
		fondo.color = Color(0.3, 0.3, 0.3, 0.95)
		al_pulsar.call()
	)
	boton.released.connect(func():
		fondo.color = Color(0, 0, 0, 0.9)
		al_soltar.call()
	)
	capa_interfaz.add_child(boton)
	return boton


func actualizar_botones_accion():
	var es_tel = dispositivo_actual == "telefono"
	if boton_fuego:
		boton_fuego.visible = es_tel and tiene_arma
	if boton_dash:
		boton_dash.visible = es_tel and tiene_dash
	if not tiene_arma:
		fuego_tactil = false


# Dirección que se está pulsando (las flechas opuestas se cancelan)
func direccion_pulsada() -> Vector2:
	var d = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		d.x += 1
	if Input.is_action_pressed("ui_left"):
		d.x -= 1
	if Input.is_action_pressed("ui_down"):
		d.y += 1
	if Input.is_action_pressed("ui_up"):
		d.y -= 1
	return d


func reiniciar_armas():
	for grupo in ["balas", "fuego_boss", "boss", "enemigos", "balas_tutorial"]:
		for nodo in get_tree().get_nodes_in_group(grupo):
			nodo.queue_free()
	jefe = null
	jefe_vivo = false
	dash_activo = 0.0
	dash_cd = 0.0
	fuego_cd = 0.0
	if jefe_barra:
		jefe_barra_fondo.visible = false
		jefe_barra.visible = false
		jefe_nombre.visible = false
	if sprite_jugador:
		sprite_jugador.scale = Vector2(0.4, 0.4)


func procesar_armas(delta):
	if jugador == null:
		return
	fuego_cd -= delta
	dash_cd -= delta

	# Dash: mientras dura dejas una estela y no recibes daño
	if dash_activo > 0.0:
		dash_activo -= delta
		crear_estela()

	# Hacia dónde mira el personaje (la pistola gira con él).
	# En un computador apuntas con el mouse; en teléfono mira hacia donde caminas.
	var es_pc_real = OS.has_feature("pc")
	var d = direccion_pulsada()
	if es_pc_real and tiene_arma:
		var haz = get_global_mouse_position() - jugador.position
		if haz.length() > 4.0:
			mirando = haz.normalized()
	elif d != Vector2.ZERO:
		mirando = d.normalized()
	if arma_nodo:
		arma_nodo.rotation = mirando.angle()
		arma_nodo.scale.y = -1.0 if mirando.x < 0 else 1.0

	# Disparo: click izquierdo en PC, botón F en teléfono
	var click = es_pc_real and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if tiene_arma and not reiniciando and (click or fuego_tactil):
		disparar()

	# Nivel 39: tutorial vacío para aprender a esquivar con dash
	if nivel_actual == 39:
		procesar_tutorial_dash(delta)
	elif nivel_actual < nivel_jefe:
		procesar_enemigos(delta)

	if nivel_actual == nivel_jefe:
		procesar_jefe(delta)


# ---------- Slimes pequeños (niveles 36 a 39) ----------
func crear_enemigos_slime(camino_orden: Array):
	var cantidad = nivel_actual - nivel_armas + 2  # 36 -> 2 ... 39 -> 5
	var indices = range(6, camino_orden.size() - 4)
	indices.shuffle()
	var usados = []
	for i in indices:
		if usados.size() >= cantidad:
			break
		var lejos = true
		for u in usados:
			if absi(u - i) < 4:
				lejos = false
		if lejos:
			usados.append(i)
			crear_enemigo_slime(camino_orden[i])


func crear_enemigo_slime(celda: Vector2i):
	var enemigo = Area2D.new()
	enemigo.add_to_group("enemigos")
	enemigo.position = Vector2((celda.x + 0.5) * tamaño_bloque, (celda.y + 0.5) * tamaño_bloque)
	enemigo.set_meta("vida", 3)
	enemigo.set_meta("cd", randf_range(1.0, 3.0))  # cada uno empieza a distinto tiempo

	var cuerpo = ColorRect.new()
	cuerpo.size = Vector2(44, 44)
	cuerpo.position = Vector2(-22, -22)
	cuerpo.color = Color(0.9, 0.05, 0.05)  # Los slimes enemigos siempre son rojos en todos los mods y en el juego base.
	enemigo.add_child(cuerpo)
	var brillo = ColorRect.new()
	brillo.size = Vector2(34, 6)
	brillo.position = Vector2(-17, -18)
	brillo.color = Color(1, 1, 1, 0.3)
	enemigo.add_child(brillo)
	for ojo_x in [-13, 4]:
		var ojo = ColorRect.new()
		ojo.size = Vector2(9, 11)
		ojo.position = Vector2(ojo_x, -8)
		ojo.color = Color(1, 1, 1)
		enemigo.add_child(ojo)
		var pupila = ColorRect.new()
		pupila.size = Vector2(4, 5)
		pupila.position = Vector2(ojo_x + 1, -4)
		pupila.color = Color(0, 0, 0)
		enemigo.add_child(pupila)

	var colision = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(44, 44)
	colision.shape = forma
	enemigo.add_child(colision)
	add_child(enemigo)


# Cada slime pequeño tira 1 bloque de fuego hacia ti cada 3 segundos
func procesar_enemigos(delta):
	if jugador == null or reiniciando:
		return
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if enemigo.is_queued_for_deletion():
			continue
		var espera = float(enemigo.get_meta("cd")) - delta
		if espera <= 0.0:
			espera = 3.0
			var dir = (jugador.position - enemigo.position).normalized()
			var fuego = crear_proyectil(enemigo.position, dir * 260.0, 24, color_fuego(), "fuego_boss")
			fuego.body_entered.connect(_on_fuego_jefe_cuerpo.bind(fuego))
		enemigo.set_meta("cd", espera)


func danar_enemigo(enemigo: Node):
	var vida = int(enemigo.get_meta("vida")) - 1
	enemigo.set_meta("vida", vida)
	if vida <= 0:
		enemigo.remove_from_group("enemigos")
		enemigo.queue_free()
	else:
		enemigo.modulate = Color(1.6, 0.8, 0.8)
		var tween = enemigo.create_tween()
		tween.tween_property(enemigo, "modulate", Color(1, 1, 1), 0.12)


# Script sencillo para los proyectiles: avanzan en línea recta y se borran al salir de la pantalla
func obtener_script_proyectil() -> GDScript:
	if script_proyectil == null:
		script_proyectil = GDScript.new()
		script_proyectil.source_code = """
extends Area2D

var vel = Vector2.ZERO

func _physics_process(delta):
	position += vel * delta
	if position.x < -60 or position.x > 1220 or position.y < -60 or position.y > 700:
		queue_free()
"""
		script_proyectil.reload()
	return script_proyectil


func crear_proyectil(pos: Vector2, vel: Vector2, lado: int, color: Color, grupo: String) -> Area2D:
	var area = Area2D.new()
	area.set_script(obtener_script_proyectil())
	area.add_to_group(grupo)
	area.position = pos
	area.set("vel", vel)

	if mod_activo == "ils":
		# Los disparos usan el modelo de slime ya existente, en rojo; no un cuadrado ni otra textura.
		var grafico_slime = Node2D.new()
		grafico_slime.position = Vector2(-lado / 2, -lado / 2)
		area.add_child(grafico_slime)
		agregar_modelo_slime(grafico_slime, Vector2(maxf(lado, 22.0), maxf(lado, 22.0)), Color(0.9, 0.05, 0.05))
	else:
		var grafico = ColorRect.new()
		grafico.size = Vector2(lado, lado)
		grafico.position = Vector2(-lado / 2, -lado / 2)
		grafico.color = color
		area.add_child(grafico)

	var colision = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(lado, lado)
	colision.shape = forma
	area.add_child(colision)
	add_child(area)
	return area


# Disparo del jugador: una bolita de fuego del color del pack
func disparar():
	if fuego_cd > 0.0:
		return
	fuego_cd = 0.25
	var bala = crear_proyectil(jugador.position + mirando * 36, mirando * 700.0, 14, color_fuego().lightened(0.3), "balas")
	bala.body_entered.connect(_on_bala_cuerpo.bind(bala))
	bala.area_entered.connect(_on_bala_area.bind(bala))


func _on_bala_cuerpo(body, bala):
	if body == jugador or not is_instance_valid(bala):
		return
	if body is StaticBody2D:
		bala.queue_free()  # choca con una pared


func _on_bala_area(area, bala):
	if not is_instance_valid(bala) or bala.is_queued_for_deletion():
		return
	if area.is_in_group("boss"):
		danar_jefe(1)
		bala.queue_free()
	elif area.is_in_group("enemigos"):
		danar_enemigo(area)
		bala.queue_free()
	elif area.is_in_group("fuego_boss"):
		area.queue_free()  # tu disparo apaga el fuego del jefe
		bala.queue_free()
	elif area.is_in_group("rojos"):
		area.queue_free()  # los bloques rojos se destruyen con disparos
		bala.queue_free()


# ---------- Dash ----------
func intentar_dash():
	if not tiene_dash or dash_cd > 0.0 or impulsando or jugador == null or reiniciando or get_tree().paused:
		return
	var d = direccion_pulsada()
	if d == Vector2.ZERO:
		d = mirando
	d = d.normalized()
	dash_cd = 0.8
	dash_activo = 0.25
	jugador.set("impulso", d * 1000.0)
	jugador.set("tiempo_impulso", 0.14)

	# Pequeña animación: el personaje se estira en la dirección del dash y vuelve a la normalidad
	if sprite_jugador:
		var base = Vector2(0.4, 0.4)
		if absf(d.x) >= absf(d.y):
			sprite_jugador.scale = base * Vector2(1.5, 0.7)
		else:
			sprite_jugador.scale = base * Vector2(0.7, 1.5)
		var tween = sprite_jugador.create_tween()
		tween.tween_property(sprite_jugador, "scale", base, 0.22)


# Cuadro azul que se desvanece detrás del personaje mientras hace dash
func crear_estela():
	var estela = ColorRect.new()
	estela.size = Vector2(50, 50)
	estela.position = jugador.position - Vector2(25, 25)
	estela.color = Color(0.6, 0.85, 1, 0.55)
	estela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(estela)
	var tween = estela.create_tween()
	tween.tween_property(estela, "modulate:a", 0.0, 0.25)
	tween.tween_callback(estela.queue_free)


# ---------- Slime gigante (nivel 40) ----------
func generar_nivel_dash():
	# Campo vacío: solo el jugador, las balas y la puerta bloqueada por el tutorial.
	tutorial_dash_tiempo = 0.0
	tutorial_dash_esquivadas = 0
	tutorial_dash_activo = true
	puerta.visible = false
	puerta.position = Vector2((columnas - 1) * tamaño_bloque, 5 * tamaño_bloque)
	texto_tutorial.visible = true
	texto_tutorial.text = "DASH para esquivar balas: esquivadas 0/5"
	texto_tutorial.position = Vector2(230, 80)


func procesar_tutorial_dash(delta):
	if not tutorial_dash_activo or jugador == null or reiniciando:
		return
	tutorial_dash_tiempo += delta
	if tutorial_dash_tiempo >= 5.0:
		tutorial_dash_tiempo = 0.0
		var origen = Vector2(columnas * tamaño_bloque + 20, randf_range(100, 540))
		var bala = crear_proyectil(origen, Vector2(-320.0, 0), 28, color_slime(), "balas_tutorial")
		bala.body_entered.connect(_on_bala_tutorial_cuerpo.bind(bala))


func _on_bala_tutorial_cuerpo(body, bala):
	if body != jugador or not is_instance_valid(bala) or bala.is_queued_for_deletion():
		return
	if dash_activo > 0.0:
		tutorial_dash_esquivadas += 1
		mostrar_mensaje("¡ESQUIVADA! %d/5" % tutorial_dash_esquivadas, Color(0.5, 0.9, 1), 400)
		if tutorial_dash_esquivadas >= 5:
			tutorial_dash_activo = false
			puerta.visible = true
			texto_tutorial.text = "¡Tutorial completado! Ve a la puerta."
	else:
		mostrar_mensaje("¡USA DASH PARA ESQUIVAR!", Color(1, 0.3, 0.3), 330)
	bala.queue_free()


func generar_nivel_jefe():
	# Pilares para taparse de los disparos
	for celda in [Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 6), Vector2i(5, 7), Vector2i(8, 4), Vector2i(8, 5)]:
		colocar_pared(celda.x, celda.y)
	crear_jefe()


func crear_jefe():
	jefe = Area2D.new()
	jefe.add_to_group("boss")
	jefe.add_to_group("rojos")  # tocarlo quita un corazón
	jefe.position = Vector2(928, 320)
	jefe_vivo = true
	jefe_vida = jefe_vida_max
	jefe_tiempo = 0.0
	jefe_cd = 2.0

	var cuerpo = ColorRect.new()
	cuerpo.size = Vector2(200, 240)
	cuerpo.position = Vector2(-100, -120)
	cuerpo.color = color_slime()
	jefe.add_child(cuerpo)

	var brillo = ColorRect.new()
	brillo.size = Vector2(170, 22)
	brillo.position = Vector2(-85, -108)
	brillo.color = Color(1, 1, 1, 0.3)
	jefe.add_child(brillo)

	for ojo_x in [-60, 20]:
		var ojo = ColorRect.new()
		ojo.size = Vector2(40, 50)
		ojo.position = Vector2(ojo_x, -50)
		ojo.color = Color(1, 1, 1)
		jefe.add_child(ojo)
		var pupila = ColorRect.new()
		pupila.size = Vector2(18, 24)
		pupila.position = Vector2(ojo_x + 4, -38)  # mira hacia la izquierda, donde estás tú
		pupila.color = Color(0, 0, 0)
		jefe.add_child(pupila)

	var boca = ColorRect.new()
	boca.size = Vector2(100, 14)
	boca.position = Vector2(-70, 40)
	boca.color = Color(0, 0, 0, 0.7)
	jefe.add_child(boca)

	var colision = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(200, 240)
	colision.shape = forma
	jefe.add_child(colision)
	add_child(jefe)

	jefe_barra.color = color_slime()
	jefe_barra.size.x = 494
	jefe_barra_fondo.visible = true
	jefe_barra.visible = true
	jefe_nombre.visible = true


func procesar_jefe(delta):
	if not jefe_vivo or jefe == null or not is_instance_valid(jefe):
		return
	# Se mueve de arriba a abajo
	jefe_tiempo += delta
	jefe.position.y = 320 + sin(jefe_tiempo * 0.9) * 165

	# Lanza bloques de fuego hacia ti (3 a la vez cuando le queda la mitad de vida)
	jefe_cd -= delta
	if jefe_cd <= 0.0 and jugador != null and not reiniciando:
		var furioso = jefe_vida <= jefe_vida_max / 2
		jefe_cd = 1.0 if furioso else 1.7
		lanzar_fuego_jefe(furioso)


func lanzar_fuego_jefe(furioso: bool):
	var origen = jefe.position + Vector2(-110, 0)
	var dir = (jugador.position - origen).normalized()
	var angulos = [-0.3, 0.0, 0.3] if furioso else [0.0]
	for a in angulos:
		var fuego = crear_proyectil(origen, dir.rotated(a) * 320.0, 30, color_fuego(), "fuego_boss")
		fuego.body_entered.connect(_on_fuego_jefe_cuerpo.bind(fuego))


func _on_fuego_jefe_cuerpo(body, fuego):
	if not is_instance_valid(fuego) or fuego.is_queued_for_deletion():
		return
	if body == jugador:
		# Si estás invencible (o haces dash) el fuego te atraviesa
		if debug_activo or tiempo_invulnerable > 0 or reiniciando or dash_activo > 0 or frames_gracia > 0:
			return
		recibir_dano()
		fuego.queue_free()
	elif body is StaticBody2D:
		fuego.queue_free()  # choca con una pared


func danar_jefe(cantidad: int):
	if not jefe_vivo or jefe == null or not is_instance_valid(jefe):
		return
	jefe_vida -= cantidad
	jefe_barra.size.x = 494.0 * maxf(jefe_vida, 0) / jefe_vida_max
	# Destello al recibir un disparo
	jefe.modulate = Color(1.6, 0.8, 0.8)
	var tween = jefe.create_tween()
	tween.tween_property(jefe, "modulate", Color(1, 1, 1), 0.12)
	if jefe_vida <= 0:
		matar_jefe()


func matar_jefe():
	jefe_vivo = false
	jefe.remove_from_group("boss")
	jefe.remove_from_group("rojos")  # ya no hace daño
	for fuego in get_tree().get_nodes_in_group("fuego_boss"):
		fuego.queue_free()
	# La puerta aparece exactamente donde murió el jefe.
	puerta.position = jefe.position
	puerta.visible = true
	var tween = jefe.create_tween()
	tween.tween_property(jefe, "modulate:a", 0.0, 0.6)
	tween.tween_callback(jefe.queue_free)
	jefe_barra_fondo.visible = false
	jefe_barra.visible = false
	jefe_nombre.visible = false

	# Logro "Slime killer" (solo la primera vez)
	if not logro_slimekiller:
		logro_slimekiller = true
		guardar_logros()
		mostrar_mensaje("ACHIEVEMENT: Slime killer", Color(1, 0.84, 0), 250)
	else:
		mostrar_mensaje("BIG SLIME DEFEATED!", Color(1, 0.84, 0), 280)


# ---------- Lógica del slime ----------
func reiniciar_slime():
	slime_actual = null
	slime_tiempo = 0.0
	impulsando = false
	if texto_slime:
		texto_slime.visible = false
	if jugador:
		jugador.set("tiempo_impulso", 0.0)
		jugador.set("impulso", Vector2.ZERO)


func cancelar_cuenta_slime():
	slime_actual = null
	slime_tiempo = 0.0
	texto_slime.visible = false


func procesar_slime(delta):
	if jugador == null:
		return

	# Mientras sales disparado: se revisa cuándo termina el impulso
	if impulsando:
		var restante = float(jugador.get("tiempo_impulso"))
		if restante <= 0.0:
			if jugador_dentro_de_pasa():
				jugador.set("tiempo_impulso", 0.05)  # sigue hasta salir del bloque fantasma
			else:
				terminar_impulso()
		return

	if debug_activo or reiniciando:
		cancelar_cuenta_slime()
		return

	# Direcciones que se están pulsando
	var dirs = []
	var der = Input.is_action_pressed("ui_right")
	var izq = Input.is_action_pressed("ui_left")
	var aba = Input.is_action_pressed("ui_down")
	var arr = Input.is_action_pressed("ui_up")
	if der and not izq:
		dirs.append(Vector2(1, 0))
	if izq and not der:
		dirs.append(Vector2(-1, 0))
	if aba and not arr:
		dirs.append(Vector2(0, 1))
	if arr and not aba:
		dirs.append(Vector2(0, -1))

	# ¿Estás tocando un slime y empujando hacia él?
	var slime_tocado: Node = null
	var dir_tocada = Vector2.ZERO
	for d in dirs:
		for s in get_tree().get_nodes_in_group("slimes"):
			if s.is_queued_for_deletion():
				continue
			var rel = s.position + Vector2(tamaño_bloque / 2, tamaño_bloque / 2) - jugador.position
			var toca = false
			if d.x != 0:
				toca = absf(rel.y) < 40 and absf(rel.x) <= 60 and signf(rel.x) == d.x
			else:
				toca = absf(rel.x) < 40 and absf(rel.y) <= 60 and signf(rel.y) == d.y
			if toca:
				slime_tocado = s
				dir_tocada = d
				break
		if slime_tocado != null:
			break

	# Dejaste de empujar: si cargaste al menos 1 s, sales disparado con esa fuerza
	if slime_tocado == null:
		if slime_actual != null and slime_tiempo >= 1.0:
			lanzar_jugador()
		else:
			cancelar_cuenta_slime()
		return

	# Cargando: la cuenta sube hasta 3 s
	if slime_tocado != slime_actual or dir_tocada != slime_dir:
		slime_actual = slime_tocado
		slime_dir = dir_tocada
		slime_tiempo = 0.0
	slime_tiempo = minf(slime_tiempo + delta, tiempo_slime)
	texto_slime.visible = true
	texto_slime.text = str(int(slime_tiempo))
	texto_slime.position = jugador.position + Vector2(-10, -80)

	if slime_tiempo >= tiempo_slime:
		lanzar_jugador()


# El slime te dispara hacia el lado contrario. La fuerza depende de los segundos cargados (1, 2 o 3)
func lanzar_jugador():
	var fuerza = clampi(int(slime_tiempo), 1, 3)
	var duracion = float(tiempos_impulso[fuerza - 1])
	var centro = slime_actual.position + Vector2(tamaño_bloque / 2, tamaño_bloque / 2)
	# Te alineamos con el slime para que el disparo pase justo por el bloque fantasma
	if slime_dir.x != 0:
		jugador.position.y = centro.y
	else:
		jugador.position.x = centro.x
	jugador.set("impulso", -slime_dir * velocidad_impulso)
	jugador.set("tiempo_impulso", duracion)
	impulsando = true
	cancelar_cuenta_slime()

	# Mientras vuelas atraviesas los bloques fantasma
	for pasa in get_tree().get_nodes_in_group("pasas"):
		if pasa is PhysicsBody2D:
			jugador.add_collision_exception_with(pasa)

	if nivel_actual == nivel_slime:
		texto_tutorial.text = "Ghost blocks can only be crossed while you fly!"


func terminar_impulso():
	impulsando = false
	if debug_activo:
		return  # con debug los fantasmas siempre se atraviesan
	for pasa in get_tree().get_nodes_in_group("pasas"):
		if pasa is PhysicsBody2D and not pasa.is_queued_for_deletion():
			jugador.remove_collision_exception_with(pasa)


func jugador_dentro_de_pasa() -> bool:
	var caja_jugador = Rect2(jugador.position - Vector2(25, 25), Vector2(50, 50)).grow(2)
	for pasa in get_tree().get_nodes_in_group("pasas"):
		if pasa.is_queued_for_deletion():
			continue
		var caja = Rect2(pasa.position, Vector2(tamaño_bloque, tamaño_bloque))
		if caja_jugador.intersects(caja):
			return true
	return false


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

	# Mod activo: color y carita encima del bloque blanco
	var skin = obtener_skin(false)
	if skin != null:
		poner_skin(nueva_pared, skin)
	add_child(nueva_pared)


# Doble pulsación de flecha arriba (en menos de 0.5 s) en el nivel 10:
# el bloque traspasable empieza a brillar
func _input(event):
	# Shift (PC): dash hacia la dirección que estás pulsando
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SHIFT:
		intentar_dash()
		return

	# Esc: abre el menú de pausa (en PC)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		abrir_pausa()
		get_viewport().set_input_as_handled()
		return

	# Tecla Z: abre la consola, pero solo si el dispositivo real es un computador (PC, Mac o Linux).
	# No depende de la opción PC/TELÉFONO elegida en el menú.
	if OS.has_feature("pc") and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Z:
		abrir_consola()
		get_viewport().set_input_as_handled()  # que la "z" no se escriba en el cuadro
		return

	# Teclado (PC). En teléfonos lo registra el botón táctil de arriba.
	if event is InputEventKey and event.is_action_pressed("ui_up") and not event.is_echo():
		registrar_toque_arriba()


# ==========================================
# MENÚ DE PAUSA Y PARTIDA GUARDADA
# ==========================================
# Botón de dos rayitas "||" arriba a la derecha (solo se ve en la opción de teléfono)
func crear_boton_pausa():
	boton_pausa = Button.new()
	boton_pausa.custom_minimum_size = Vector2(64, 64)
	boton_pausa.position = Vector2(1070, 20)
	boton_pausa.visible = false
	for i in range(2):
		var raya = ColorRect.new()
		raya.color = Color(1, 1, 1)
		raya.size = Vector2(9, 30)
		raya.position = Vector2(17 + i * 21, 17)
		raya.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boton_pausa.add_child(raya)
	boton_pausa.pressed.connect(abrir_pausa)
	capa_interfaz.add_child(boton_pausa)


func abrir_pausa():
	# No se abre en menús, consola o pantalla final (el juego ya está en pausa)
	if get_tree().paused or pausa_capa != null or not partida_en_curso:
		return
	get_tree().paused = true

	pausa_capa = CanvasLayer.new()
	pausa_capa.layer = 105
	pausa_capa.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pausa_capa)

	# Nodo que escucha la tecla Esc para volver a jugar (el juego principal está en pausa)
	var escucha = Node.new()
	var guion = GDScript.new()
	guion.source_code = """
extends Node
signal cerrar
var t0 = Time.get_ticks_msec()

func _input(event):
	if Time.get_ticks_msec() - t0 < 250:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		cerrar.emit()
"""
	guion.reload()
	escucha.set_script(guion)
	escucha.connect("cerrar", cerrar_pausa)
	pausa_capa.add_child(escucha)

	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.75)
	pausa_capa.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro = CenterContainer.new()
	pausa_capa.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var caja = VBoxContainer.new()
	caja.add_theme_constant_override("separation", 20)
	centro.add_child(caja)

	var titulo = Label.new()
	titulo.text = "PAUSED"
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.modulate = Color(0, 0.6, 1)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)

	var seguir = Button.new()
	seguir.text = "RESUME"
	seguir.custom_minimum_size = Vector2(320, 80)
	seguir.add_theme_font_size_override("font_size", 40)
	seguir.pressed.connect(cerrar_pausa)
	caja.add_child(seguir)

	var salir = Button.new()
	salir.text = "EXIT"
	salir.custom_minimum_size = Vector2(320, 80)
	salir.add_theme_font_size_override("font_size", 40)
	salir.pressed.connect(_on_salir_de_partida)
	caja.add_child(salir)

	var aviso = Label.new()
	aviso.text = "Your progress is saved when you exit"
	aviso.add_theme_font_size_override("font_size", 20)
	aviso.modulate = Color(0.6, 0.6, 0.6)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(aviso)

	seguir.grab_focus.call_deferred()


func cerrar_pausa():
	if pausa_capa == null:
		return
	pausa_capa.queue_free()
	pausa_capa = null
	get_tree().paused = false


# EXIT: guarda la partida y vuelve al menú principal
func _on_salir_de_partida():
	guardar_partida()
	partida_en_curso = false
	_volver_al_menu()


func guardar_partida():
	var archivo = ConfigFile.new()
	archivo.set_value("partida", "dispositivo", dispositivo_actual)
	archivo.set_value("partida", "nivel", nivel_actual)
	archivo.set_value("partida", "corazones", corazones)
	archivo.set_value("partida", "dorado", tiene_dorado)
	archivo.set_value("partida", "dano_rojos", dano_en_rojos)
	archivo.save(ARCHIVO_PARTIDA)


func existe_partida_guardada(dispositivo: String) -> bool:
	var archivo = ConfigFile.new()
	if archivo.load(ARCHIVO_PARTIDA) != OK:
		return false
	return archivo.get_value("partida", "dispositivo", "") == dispositivo \
		and int(archivo.get_value("partida", "nivel", 1)) > 1


func cargar_partida():
	var archivo = ConfigFile.new()
	if archivo.load(ARCHIVO_PARTIDA) != OK:
		return
	nivel_actual = int(archivo.get_value("partida", "nivel", 1))
	tiene_dorado = archivo.get_value("partida", "dorado", false)
	corazones_max = 4 if tiene_dorado else 3
	corazones = clampi(int(archivo.get_value("partida", "corazones", 3)), 1, corazones_max)
	dano_en_rojos = archivo.get_value("partida", "dano_rojos", false)
	corazones_visuales[3].visible = tiene_dorado
	texto_nivel.text = "NIVEL: " + str(nivel_actual)
	actualizar_corazones()


# Si se cierra la ventana o la app pasa a segundo plano jugando, también se guarda
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		guardar_logros()  # guarda el mod activo, los logros y el nombre aunque no estés jugando
		if partida_en_curso:
			guardar_partida()


# ==========================================
# CONSOLA DE COMANDOS (tecla Z) Y MODO DEBUG
# ==========================================
# Comando "DeBug": activa/desactiva atravesar paredes y fuego sin recibir daño.
func abrir_consola():
	# No se abre en los menús ni en la pantalla final (el juego está en pausa) ni si ya está abierta
	if get_tree().paused or consola_capa != null:
		return
	get_tree().paused = true

	consola_capa = CanvasLayer.new()
	consola_capa.layer = 110
	consola_capa.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(consola_capa)

	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.65)
	consola_capa.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro = CenterContainer.new()
	consola_capa.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var caja = VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	centro.add_child(caja)

	var titulo = Label.new()
	titulo.text = "CONSOLE"
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.modulate = Color(0, 0.6, 1)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)

	var linea = LineEdit.new()
	linea.placeholder_text = "Type a command..."
	linea.custom_minimum_size = Vector2(420, 56)
	linea.add_theme_font_size_override("font_size", 28)
	linea.text_submitted.connect(_on_comando)
	linea.gui_input.connect(_on_consola_tecla)  # Esc cierra la consola
	caja.add_child(linea)

	consola_aviso = Label.new()
	consola_aviso.add_theme_font_size_override("font_size", 22)
	consola_aviso.modulate = Color(1, 0.3, 0.3)
	consola_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(consola_aviso)

	var cerrar = Button.new()
	cerrar.text = "CLOSE"
	cerrar.custom_minimum_size = Vector2(200, 50)
	cerrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cerrar.add_theme_font_size_override("font_size", 26)
	cerrar.pressed.connect(cerrar_consola)
	caja.add_child(cerrar)

	linea.grab_focus.call_deferred()


func _on_consola_tecla(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cerrar_consola()


func cerrar_consola():
	if consola_capa == null:
		return
	consola_capa.queue_free()
	consola_capa = null
	get_tree().paused = false


func _on_comando(texto: String):
	# No importa cómo se escriba (debug, DEBUG, DeBug...)
	if texto.strip_edges().to_lower() == "debug":
		debug_activo = not debug_activo
		aplicar_debug()
		cerrar_consola()
		if debug_activo:
			mostrar_mensaje("DEBUG: ON", Color(0.3, 1, 0.3), 440)
		else:
			mostrar_mensaje("DEBUG: OFF", Color(1, 0.4, 0.4), 440)
	else:
		# Un número (o "tp 12") te teletransporta a ese nivel
		var numero = texto.strip_edges().to_lower().trim_prefix("tp").strip_edges()
		if numero.is_valid_int() and int(numero) >= 1 and int(numero) <= nivel_final:
			teletransportar_a_nivel(int(numero))
		else:
			consola_aviso.text = "Unknown command (type a level 1-%d)" % nivel_final


# Salta directamente a un nivel (solo desde la consola)
func teletransportar_a_nivel(nivel: int):
	cerrar_consola()
	nivel_actual = nivel
	texto_nivel.text = "NIVEL: " + str(nivel_actual)
	# Saltarte el nivel 11 cuenta como no haberlo jugado: no se puede ganar Hitbox master así
	if nivel_actual > nivel_lento_desde and nivel_actual <= nivel_lento_hasta:
		dano_en_rojos = true
	generar_mapa_procedural.call_deferred()
	mostrar_mensaje.call_deferred("TP: LEVEL %d" % nivel, Color(0.4, 0.8, 1), 430)


# Con debug activo el jugador ignora las paredes y los bloques negros
# (los bloques rojos no le hacen daño: se revisa en _physics_process)
func aplicar_debug():
	if jugador == null:
		return
	var solidos = get_tree().get_nodes_in_group("paredes") + get_tree().get_nodes_in_group("negros") \
		+ get_tree().get_nodes_in_group("pasas") + get_tree().get_nodes_in_group("slimes")
	for bloque in solidos:
		if bloque is PhysicsBody2D and not bloque.is_queued_for_deletion():
			if debug_activo:
				jugador.add_collision_exception_with(bloque)
			else:
				jugador.remove_collision_exception_with(bloque)
	texto_debug.visible = debug_activo


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

	# Mod activo: otro color (y carita) para los bloques rojos
	var skin = obtener_skin(true)
	if skin != null:
		poner_skin(area, skin)
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
	luz_jugador.enabled = nivel_actual >= nivel_oscuridad and nivel_actual < nivel_slime
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
		if nivel_actual >= nivel_oscuridad and nivel_actual < nivel_slime and not tiene_linterna:
			mostrar_mensaje("NECESITAS LA LINTERNA", Color(1, 0.3, 0.3), 330)
			return
		# En el nivel 39 la puerta no funciona hasta esquivar cinco balas con dash.
		if nivel_actual == 39 and tutorial_dash_esquivadas < 5:
			mostrar_mensaje("ESQUIVA 5 BALAS CON DASH: %d/5" % tutorial_dash_esquivadas, Color(1, 0.3, 0.3), 260)
			return
		# El slime gigante cierra la puerta mientras siga vivo
		if nivel_actual == nivel_jefe and jefe_vivo:
			mostrar_mensaje("KILL THE BIG SLIME!", Color(1, 0.3, 0.3), 300)
			return
		# La puerta del último nivel termina la Alpha
		if nivel_actual >= nivel_final:
			terminar_alpha.call_deferred()
			return
		# Terminar el nivel 15 sin perder corazones rojos: logro "Hitbox master" (solo una vez)
		var gana_hitbox = nivel_actual == nivel_lento_hasta and not dano_en_rojos and not logro_hitbox
		if gana_hitbox:
			logro_hitbox = true
			guardar_logros()
		nivel_actual += 1
		texto_nivel.text = "NIVEL: " + str(nivel_actual)
		# Diferido para no modificar la física dentro de la señal
		generar_mapa_procedural.call_deferred()
		if gana_hitbox:
			# Se muestra después de generar el nivel (que borra los carteles)
			mostrar_mensaje.call_deferred("ACHIEVEMENT: Hitbox master", Color(1, 0.84, 0), 280)


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
		logro_modder = archivo.get_value("logros", "modder", false)
		logro_hitbox = archivo.get_value("logros", "hitbox", false)
		logro_door = archivo.get_value("logros", "door", false)
		logro_slimekiller = archivo.get_value("logros", "slimekiller", false)
		nombre_bloqueado = archivo.get_value("perfil", "bloqueado", false)
		nombre_usuario = str(archivo.get_value("perfil", "nombre", "")).left(10)
		mods_instalados = archivo.get_value("mods", "instalados", ["base"])
		mod_activo = archivo.get_value("mods", "activo", "base")
		# Seguridad: el mod activo siempre debe estar instalado
		if not mods_instalados.has("base"):
			mods_instalados.append("base")
		if not mods_instalados.has(mod_activo):
			mod_activo = "base"


func guardar_logros():
	var archivo = ConfigFile.new()
	archivo.set_value("logros", "end", logro_end)
	archivo.set_value("logros", "gold", logro_gold)
	archivo.set_value("logros", "modder", logro_modder)
	archivo.set_value("logros", "hitbox", logro_hitbox)
	archivo.set_value("logros", "door", logro_door)
	archivo.set_value("logros", "slimekiller", logro_slimekiller)
	archivo.set_value("perfil", "bloqueado", nombre_bloqueado)
	archivo.set_value("perfil", "nombre", nombre_usuario)
	archivo.set_value("mods", "instalados", mods_instalados)
	archivo.set_value("mods", "activo", mod_activo)
	archivo.save(ARCHIVO_LOGROS)


# Pantalla final: "You finished the Alpha!" + logro ¿End?
# Si ya tenías el logro ¿End?, no se muestra: vuelves directo al menú.
func terminar_alpha():
	var primera_vez = not logro_end
	logro_end = true
	guardar_logros()

	# La Alpha terminó: ya no hay partida que guardar (se borra el archivo de guardado)
	partida_en_curso = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO_PARTIDA))

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

	# El logro solo se muestra la primera vez; después queda solo el título y el botón MENU
	if primera_vez:
		var aviso = Label.new()
		aviso.text = "ACHIEVEMENT UNLOCKED!"
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

	sprite_jugador = sprite
	jugador.add_child(sprite)
	jugador.add_child(colision)
	jugador.add_child(luz_jugador)
	jugador.position = Vector2(96, 5 * 64 + 32)
	crear_arma()  # la pistola (solo se ve desde el nivel 36)

	var script_jugador = GDScript.new()
	script_jugador.source_code = """
extends CharacterBody2D

var velocidad = 300.0
var impulso = Vector2.ZERO
var tiempo_impulso = 0.0

func _physics_process(delta):
	# Disparo del slime: durante unos instantes el personaje sale volando
	if tiempo_impulso > 0.0:
		tiempo_impulso -= delta
		velocity = impulso
		move_and_slide()
		return

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
