extends Node2D
# ESCENA PRINCIPAL (sirve para los 3 niveles; los datos vienen de niveles.gd)
# - Construye el mundo (3x2 pantallas de 16x11 casillas) a partir del texto del mapa.
# - Camara FIJA: muestra una pantalla y salta a la siguiente al llegar al borde.
# - Segun el nivel activa: inundacion progresiva, noche con luces, carros,
#   zona no autorizada, misiones, etc.

const T := 16            # tamano de cada casilla en pixeles
const PANT_W := 256      # una pantalla = 16 x 11 casillas
const PANT_H := 176
const COLOR_NOCHE := Color(0.07, 0.08, 0.17)
const RELAMPAGOS := true # relampagos suaves en el nivel nocturno

const Persona = preload("res://persona.gd")
const Objeto = preload("res://objeto.gd")
const Interactivo = preload("res://interactivo.gd")
const Coche = preload("res://coche.gd")
const Jugador = preload("res://player.gd")
const Hud = preload("res://hud.gd")
const Lluvia = preload("res://lluvia.gd")
const Niveles = preload("res://niveles.gd")

# Letra del mapa -> nombre de la textura
const TEX := {
	".": "pasto", "=": "calle", "~": "agua", "R": "techo", "#": "pared", "D": "puerta",
	"T": "arbol", "O": "roca", ",": "arena", "M": "punto_encuentro",
	"C": "cable", "H": "hueco", "L": "lodo", "P": "charco", "V": "vidrio",
	"B": "pasto", "b": "calle",
}

var datos: Dictionary
var mapa: Array
var noche := false
var texturas := {}
var jugador
var camara: Camera2D
var pantalla := Vector2i(-1, -1)
var transcurrido := 0.0
var avisos: Array = []

# Inundacion
var hay_agua := false
var capa_agua: Node2D
var origen := Vector2.ZERO            # esquina de donde sale el agua (en casillas)
var distancia_max := 0.0
var orden_inundacion: Array = []      # Vector3(x, y, distancia), de cerca a lejos
var siguiente := 0
var frente := -1.0                    # hasta que distancia ha llegado el agua

# Noche
var modulado: CanvasModulate
var luz_jugador: PointLight2D
var luces_chispa: Array = []
var t_chispa := 0.0
var t_rayo := 8.0

# Zona no autorizada (nivel 3)
var cintas: Array = []
var t_zona := 0.0


func _ready():
	datos = Niveles.datos(Game.nivel)
	mapa = datos["mapa"]
	noche = datos["noche"]
	Game.reiniciar(datos)
	Game.mundo = self

	for n in ["pasto", "calle", "agua", "pared", "techo", "puerta", "arbol", "punto_encuentro",
			"arena", "roca", "cable", "hueco", "lodo", "charco", "vidrio", "cinta"]:
		texturas[n] = load("res://sprites/tile_%s.png" % n)

	_pintar_mapa()
	if datos["agua"] != null:
		_preparar_inundacion()
	if datos["meta"] != null:
		_crear_meta()
	_crear_objetos()

	jugador = Jugador.new()
	jugador.position = _centro(datos["inicio"])
	add_child(jugador)

	camara = Camera2D.new()
	add_child(camara)
	_ir_a_pantalla(_pantalla_de(jugador.position), false)

	if noche:
		_preparar_noche()
	if datos["lluvia"] > 0:
		var ll := Lluvia.new()
		ll.cantidad = datos["lluvia"]
		add_child(ll)

	Audio.iniciar_escena(Game.nivel, datos["lluvia"] > 0, datos["agua"] != null)
	avisos = datos["avisos"].duplicate()
	add_child(Hud.new())
	if Game.intro_vista:
		Game.iniciar()


# ---------------------------------------------------------------- MAPA
func _pintar_mapa():
	var capa_suelo := Node2D.new()
	add_child(capa_suelo)
	var solidos := StaticBody2D.new()   # un solo cuerpo con muchas colisiones
	add_child(solidos)

	for y in mapa.size():
		var fila: String = mapa[y]
		for x in fila.length():
			var c: String = fila[x]
			var s := Sprite2D.new()
			s.texture = texturas[TEX[c]]
			s.centered = false
			s.position = Vector2(x * T, y * T)
			capa_suelo.add_child(s)

			# Cinta de seguridad encima del suelo
			if c == "B" or c == "b":
				var cinta := Sprite2D.new()
				cinta.texture = texturas["cinta"]
				cinta.centered = false
				cinta.position = Vector2(x * T, y * T)
				capa_suelo.add_child(cinta)
				cintas.append(cinta)

			# Chispas de los cables caidos (solo se ven luz en la noche)
			if c == "C" and noche:
				var l := Game.nueva_luz(20.0, Color(1.0, 0.65, 0.2), 1.0)
				l.position = Vector2(x * T + T / 2.0, y * T + T / 2.0)
				add_child(l)
				luces_chispa.append(l)

			# Paredes, techos, arboles y rocas bloquean al jugador
			if c in ["R", "#", "T", "O"]:
				var cs := CollisionShape2D.new()
				var forma := RectangleShape2D.new()
				forma.size = Vector2(T, T)
				cs.shape = forma
				cs.position = Vector2(x * T + T / 2.0, y * T + T / 2.0)
				solidos.add_child(cs)


func _zona(rect: Rect2) -> Area2D:
	var a := Area2D.new()
	a.position = rect.position + rect.size / 2.0
	var cs := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = rect.size
	cs.shape = forma
	a.add_child(cs)
	add_child(a)
	return a


func _centro(c: Vector2i) -> Vector2:
	return Vector2(c.x * T + T / 2.0, c.y * T + T / 2.0)


# ---------------------------------------------------------------- SUELO Y AGUA
func _inundada(cx: int, cy: int) -> bool:
	if not hay_agua:
		return false
	return Vector2(cx + 0.5, cy + 0.5).distance_to(origen) <= frente


# El jugador pregunta aqui que hay bajo sus pies: "", agua, cable, cable_agua,
# hueco, lodo, charco o vidrio.
func suelo(pos: Vector2) -> String:
	var cx := floori(pos.x / T)
	var cy := floori(pos.y / T)
	if cy < 0 or cy >= mapa.size():
		return ""
	var fila: String = mapa[cy]
	if cx < 0 or cx >= fila.length():
		return ""
	var c: String = fila[cx]
	var inundada := _inundada(cx, cy)
	match c:
		"~":
			return "agua"
		"C":
			if inundada or _inundada(cx + 1, cy) or _inundada(cx - 1, cy) or _inundada(cx, cy + 1) or _inundada(cx, cy - 1):
				return "cable_agua"
			return "cable"
		"H":
			return "hueco"
		"L":
			return "lodo"
		"P":
			return "charco"
		"V":
			return "vidrio"
	if inundada:
		return "agua"
	return ""


func _preparar_inundacion():
	hay_agua = true
	capa_agua = Node2D.new()
	add_child(capa_agua)   # encima del suelo y debajo de objetos, vecinos y jugador
	var filas := mapa.size()
	var cols: int = mapa[0].length()
	origen = datos["agua"]["origen"]
	for y in filas:
		for x in cols:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(origen)
			orden_inundacion.append(Vector3(x, y, d))
			distancia_max = maxf(distancia_max, d)
	orden_inundacion.sort_custom(func(a, b): return a.z < b.z)


func _actualizar_inundacion():
	var inicio: float = datos["agua"]["inicio"]
	var avance := (transcurrido - inicio) / (Game.tiempo_max - inicio)
	if avance <= 0.0:
		return
	frente = clampf(avance, 0.0, 1.0) * (distancia_max + 1.0)
	Audio.nivel_agua(frente / (distancia_max + 1.0))
	# Cubre de agua, casilla por casilla, todo lo que el frente ya alcanzo
	while siguiente < orden_inundacion.size() and orden_inundacion[siguiente].z <= frente:
		var c: Vector3 = orden_inundacion[siguiente]
		siguiente += 1
		var s := Sprite2D.new()
		s.texture = texturas["agua"]
		s.centered = false
		s.position = Vector2(c.x * T, c.y * T)
		s.modulate.a = 0.0
		capa_agua.add_child(s)
		create_tween().tween_property(s, "modulate:a", 0.88, 0.6)


# ---------------------------------------------------------------- NOCHE
func _preparar_noche():
	modulado = CanvasModulate.new()
	modulado.color = COLOR_NOCHE
	add_child(modulado)

	var radio := 90.0 if Game.kit_nivel.get("linterna", false) else 44.0
	luz_jugador = Game.nueva_luz(radio, Color(1.0, 0.95, 0.8), 0.95)
	jugador.add_child(luz_jugador)
	Game.item_recogido.connect(_al_recoger)


func _al_recoger(tipo):
	if tipo == "linterna" and luz_jugador != null:
		create_tween().tween_property(luz_jugador, "texture_scale", 90.0 / 64.0, 0.5)


func _cable_cerca() -> bool:
	for l in luces_chispa:
		if l.global_position.distance_to(jugador.global_position) < 60.0:
			return true
	return false


func _animar_noche(delta):
	# Las chispas de los cables parpadean (y crepitan si estas cerca)
	t_chispa -= delta
	if t_chispa <= 0.0:
		t_chispa = 0.08
		for l in luces_chispa:
			l.energy = randf_range(0.2, 1.4)
		if Game.activo and not Game.terminado and randf() < 0.3 and _cable_cerca():
			Audio.sfx("chispa", -7.0, randf_range(0.9, 1.2))
	# Relampago suave de vez en cuando, con su trueno
	if RELAMPAGOS:
		t_rayo -= delta
		if t_rayo <= 0.0:
			t_rayo = randf_range(9.0, 16.0)
			if Game.activo and not Game.terminado:
				Audio.trueno_en(randf_range(0.3, 0.9), -4.0)
			var tw := create_tween()
			tw.tween_property(modulado, "color", Color(0.5, 0.55, 0.75), 0.08)
			tw.tween_property(modulado, "color", COLOR_NOCHE, 0.5)


# ---------------------------------------------------------------- META Y OBJETOS
func _crear_meta():
	var m: Rect2i = datos["meta"]
	var r := Rect2(Vector2(m.position) * T, Vector2(m.size) * T)
	Game.meta_rect = r
	var a := _zona(r)
	a.body_entered.connect(_entra_meta)


func _crear_objetos():
	for pos in datos["botiquines"]:
		_objeto("botiquin", pos)
	for e in datos["extras"]:
		_objeto(e["tipo"], e["pos"])
	for i in datos["interactivos"]:
		var it := Interactivo.new()
		it.tipo = i["tipo"]
		it.position = _centro(i["pos"])
		add_child(it)
	for p in datos["personas"]:
		var per := Persona.new()
		per.tipo = p["tipo"]
		per.position = _centro(p["pos"])
		add_child(per)
	for c in datos["coches"]:
		var co := Coche.new()
		co.dir = c["dir"]
		co.position = Vector2(c["x"] * T, c["fila"] * T + T / 2.0)
		add_child(co)


func _objeto(tipo: String, celda: Vector2i):
	var o := Objeto.new()
	o.tipo = tipo
	o.position = _centro(celda)
	add_child(o)


func _todos_llegaron() -> bool:
	for p in get_tree().get_nodes_in_group("persona"):
		if p.ayudada and not p.a_salvo:
			return false
	return true


func _entra_meta(body):
	if not body.is_in_group("jugador") or Game.terminado or Game.en_meta:
		return
	if Game.req_botiquin and not Game.botiquin:
		Game.mensaje.emit("Te falta el botiquín. ¡Un kit de emergencia es clave! Búscalo antes de salir.")
		return
	Game.en_meta = true
	Audio.sfx("tarea")
	Game.mensaje.emit("¡Llegaste! Espera a que lleguen quienes vienen contigo...")
	# Espera (maximo 8 s) a que todos los que ayudaste lleguen a salvo
	for i in 80:
		await get_tree().create_timer(0.1).timeout
		if Game.terminado or _todos_llegaron():
			break
	await get_tree().create_timer(0.6).timeout
	Game.ganar()


# ---------------------------------------------------------------- PANTALLAS (camara fija)
func _pantalla_de(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / PANT_W), floori(pos.y / PANT_H))


func _vigilar_pantalla():
	var p := _pantalla_de(jugador.position)
	if p != pantalla:
		_ir_a_pantalla(p, true)


func _ir_a_pantalla(p: Vector2i, animar: bool):
	pantalla = p
	# La zona de juego mide 256x176 y va entre la barra (24 px) y la caja de mensajes (40 px)
	var destino := Vector2(p.x * PANT_W + PANT_W / 2.0, p.y * PANT_H + 96.0)
	if animar:
		Game.transicion = true
		var tw := create_tween()
		tw.tween_property(camara, "position", destino, 0.45)
		tw.finished.connect(func(): Game.transicion = false)
	else:
		camara.position = destino


# ---------------------------------------------------------------- ZONA NO AUTORIZADA (nivel 3)
func _vigilar_zona(delta):
	if datos["zona"] == null:
		return
	# Cuenta atras de la autorizacion del rescatista
	if not Game.autorizado:
		Game.espera -= delta
		if Game.espera <= 0.0:
			Game.autorizado = true
			Audio.sfx("tarea")
			Game.mensaje.emit("RESCATISTA: La zona ya es segura para entrar. Ve con cuidado: lodo, vidrios y agua sucia.")
			for c in cintas:
				create_tween().tween_property(c, "modulate:a", 0.25, 0.6)
			return
		# Entrar antes de tiempo es peligroso
		var z: Rect2i = datos["zona"]
		var celda := Vector2i(floori(jugador.position.x / T), floori(jugador.position.y / T))
		if z.has_point(celda):
			t_zona -= delta
			if t_zona <= 0.0:
				t_zona = 2.0
				Game.mensaje.emit("¡Zona NO autorizada! Hay estructuras inestables. Sal y espera al rescatista.")
				jugador.golpe()
				Audio.sfx("derrumbe", -2.0)
				Game.hacer_dano(1, "Entraste antes de que las autoridades autorizaran el regreso: hay estructuras inestables, cables y riesgo de derrumbe.")
		else:
			t_zona = 0.0


# ---------------------------------------------------------------- RELOJ
func _process(delta):
	if noche:
		_animar_noche(delta)
	if not Game.activo or Game.terminado:
		return
	transcurrido += delta
	Game.tiempo = maxi(ceili(Game.tiempo_max - transcurrido), 0)

	if hay_agua:
		_actualizar_inundacion()
	_vigilar_pantalla()
	_vigilar_zona(delta)

	# Avisos de la radio programados en el nivel
	while avisos.size() > 0 and transcurrido >= avisos[0]["t"]:
		var a: Dictionary = avisos.pop_front()
		if a.has("requiere") and not Game.kit_nivel.get(a["requiere"], false):
			continue
		Audio.sfx("radio", -6.0)
		Game.mensaje.emit(a["texto"])

	if transcurrido >= Game.tiempo_max:
		Game.perder(datos["fin_tiempo"])
