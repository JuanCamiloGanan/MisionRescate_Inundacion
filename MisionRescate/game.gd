extends Node
# AUTOLOAD "Game": estado global (nivel, vida, kit, tareas, mensajes finales...)

signal vida_cambiada
signal mensaje(texto)
signal fin(gano, titulo, explicacion)
signal item_recogido(tipo)

const NIVELES := 3
const MAX_CONT := 5          # contaminacion maxima antes de enfermarte (nivel 3)

var nivel := 1
var info := {}               # datos del nivel actual (los pone main.gd)
var kit := {}                # objetos que conservas entre niveles (linterna, radio, agua)
var kit_nivel := {}          # kit durante el nivel actual
var historial: Array = []    # resumen de niveles superados

var vida := 3
var botiquin := false
var rescatados := 0
var extras := 0
var total_personas := 3
var total_extras := 3
var tiempo_max := 70
var tiempo := 70
var contaminacion := 0
var tareas := 0
var total_tareas := 0
var electricidad_cortada := false
var espera := 0.0
var autorizado := true
var req_botiquin := true

var terminado := false
var gano := false
var activo := false          # false mientras se ve la pantalla de inicio
var intro_vista := false     # para no repetir la pantalla de inicio al reintentar
var portada_vista := false   # la portada solo se muestra al abrir el juego
var en_meta := false
var transicion := false      # true mientras la camara cambia de pantalla
var meta_rect := Rect2()
var mundo = null             # referencia a main.gd
var _tex_luz: Texture2D


func _ready():
	# Crea los controles por codigo (no hace falta configurar el Input Map)
	_tecla("izquierda", [KEY_LEFT, KEY_A])
	_tecla("derecha", [KEY_RIGHT, KEY_D])
	_tecla("arriba", [KEY_UP, KEY_W])
	_tecla("abajo", [KEY_DOWN, KEY_S])
	_tecla("accion", [KEY_E, KEY_SPACE])
	_tecla("usar", [KEY_Q])
	_tecla("silencio", [KEY_M])
	_tecla("reiniciar", [KEY_ENTER, KEY_KP_ENTER])


func _tecla(nombre: String, teclas: Array):
	if not InputMap.has_action(nombre):
		InputMap.add_action(nombre)
	for k in teclas:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(nombre, e)


# ------------------------------------------------------------ INICIO DE NIVEL
func nuevo_juego():
	nivel = 1
	kit.clear()
	historial.clear()
	intro_vista = false
	portada_vista = false


func reiniciar(d: Dictionary):
	info = d
	vida = 3
	botiquin = false
	rescatados = 0
	extras = 0
	total_personas = d["personas"].size()
	total_extras = d["extras"].size()
	tiempo_max = d["tiempo"]
	tiempo = tiempo_max
	contaminacion = 0
	tareas = 0
	total_tareas = d["tareas"]
	electricidad_cortada = false
	espera = d["espera"]
	autorizado = espera <= 0.0
	req_botiquin = d["req_botiquin"]
	kit_nivel = kit.duplicate()
	terminado = false
	gano = false
	activo = false
	en_meta = false
	transicion = false
	meta_rect = Rect2()


func iniciar():
	activo = true
	mensaje.emit(info["inicio_msg"])
	if nivel == 1:
		Audio.sfx("sirena", -4.0)     # orden de evacuacion
	elif nivel == 2:
		Audio.sfx("radio", -4.0)


# ------------------------------------------------------------ LUCES (nivel nocturno)
func textura_luz() -> Texture2D:
	if _tex_luz == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))   # centro blanco
		g.set_color(1, Color(0, 0, 0, 1))   # borde negro = sin luz
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_tex_luz = t
	return _tex_luz


func nueva_luz(radio: float, color: Color = Color.WHITE, energia: float = 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = textura_luz()
	l.texture_scale = radio / 64.0
	l.color = color
	l.energy = energia
	return l


# ------------------------------------------------------------ SALUD Y KIT
func hacer_dano(cantidad: int, razon: String):
	if terminado:
		return
	vida -= cantidad
	Audio.sfx("dano")
	vida_cambiada.emit()
	if vida <= 0:
		perder(razon)


func contaminar(cantidad: int):
	if terminado:
		return
	contaminacion += cantidad
	Audio.sfx("enfermo")
	if contaminacion >= MAX_CONT:
		perder("Tocar agua estancada y sucia enferma: contiene bacterias y parásitos. Después de una inundación, evita el contacto y usa el botiquín.")


func _unhandled_input(event):
	if event.is_action_pressed("usar") and activo and not terminado and nivel == 3:
		usar_botiquin()


func usar_botiquin():
	if not botiquin:
		mensaje.emit("No tienes botiquín. Búscalo en el barrio.")
	elif contaminacion == 0 and vida >= 3:
		mensaje.emit("Estás bien: guarda el botiquín para cuando lo necesites.")
	else:
		botiquin = false
		contaminacion = 0
		vida = mini(vida + 1, 3)
		vida_cambiada.emit()
		mensaje.emit("Usaste el botiquín: limpiaste tus heridas y te sientes mejor.")
		Audio.sfx("tarea")


# ------------------------------------------------------------ TEXTOS DEL HUD
func texto_hud() -> Array:
	if nivel == 3:
		var c := ("ESPERA:%d" % ceili(maxf(espera, 0.0))) if not autorizado else ("TIEMPO:%d" % tiempo)
		return ["SUCIO:%d/%d" % [contaminacion, MAX_CONT], "TAREAS:%d/%d" % [tareas, total_tareas], c]
	if nivel == 2:
		return ["LUZ:" + ("FUERTE" if kit_nivel.get("linterna", false) else "DÉBIL"), "VECINOS:%d/%d" % [rescatados, total_personas], "TIEMPO:%d" % tiempo]
	return ["KIT:" + ("SI" if botiquin else "NO") + " +%d" % extras, "VECINOS:%d/%d" % [rescatados, total_personas], "TIEMPO:%d" % tiempo]


# ------------------------------------------------------------ FINAL DE NIVEL
func perder(razon: String):
	if terminado:
		return
	terminado = true
	gano = false
	Audio.fin(false)
	fin.emit(false, "¡NO LO LOGRASTE!", razon + "\n\nAprendizaje: reconocer el riesgo y actuar a tiempo salva vidas.")


func ganar():
	if terminado:
		return
	terminado = true
	gano = true
	Audio.fin(true)
	kit = kit_nivel.duplicate()    # conservas linterna, radio y agua para el siguiente nivel
	var t := ""
	var resumen := ""
	if nivel == 1:
		resumen = "N1 vecinos %d/%d" % [rescatados, total_personas]
		t = "Vecinos a salvo: %d de %d\nObjetos extra: %d de %d\n\n" % [rescatados, total_personas, extras, total_extras]
		t += "Si no puedes ayudar a alguien, avisa de inmediato a las autoridades.\n\n" if rescatados < total_personas else "¡Ayudaste a todos tus vecinos!\n\n"
		t += "LO QUE APRENDISTE:\n- No cruces zonas inundadas\n- Ten un kit de emergencia listo\n- Evacúa cuando las autoridades lo indiquen\n- Ayuda a otros"
	elif nivel == 2:
		resumen = "N2 vecinos %d/%d" % [rescatados, total_personas]
		t = "Vecinos a salvo: %d de %d\n\n" % [rescatados, total_personas]
		t += "Dejaste a alguien atrás. Los niños, adultos mayores y mascotas necesitan ayuda primero.\n\n" if rescatados < total_personas else "¡Salvaste al niño, al adulto mayor y a la mascota!\n\n"
		t += "LO QUE APRENDISTE:\n- No toques cables ni postes con agua cerca\n- No cruces calles inundadas ni te acerques a carros arrastrados\n- Ten linterna y radio de pilas\n- Ayuda primero a los más vulnerables"
	else:
		resumen = "N3 tareas %d/%d" % [tareas, total_tareas]
		t = "Reportaste los daños a las autoridades.\nTareas: %d de %d   Contaminación: %d/%d\n\n" % [tareas, total_tareas, contaminacion, MAX_CONT]
		t += "LO QUE APRENDISTE:\n- Espera la autorización para volver\n- Corta la electricidad antes de tocar nada\n- Elimina el agua estancada (mosquitos) y tira la comida mojada\n- Hierve el agua antes de beberla\n\n"
		t += "RESUMEN: " + " | ".join(historial + [resumen])
	historial.append(resumen)
	var titulo := "¡ESTÁS A SALVO!" if nivel < 3 else "¡MISIÓN COMPLETA!"
	fin.emit(true, titulo, t)
