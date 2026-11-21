extends CanvasLayer
# HUD estilo Zelda 1986: barra negra arriba (corazones y 3 datos del nivel),
# caja de mensajes abajo, portada, pantallas de inicio de nivel y de final.
# Todo el texto largo se AJUSTA SOLO para que quepa dentro de la pantalla.

var tex_lleno: Texture2D = load("res://sprites/item_corazon_lleno.png")
var tex_vacio: Texture2D = load("res://sprites/item_corazon_vacio.png")
var corazones: Array[TextureRect] = []
var lbl_a: Label
var lbl_b: Label
var lbl_c: Label
var lbl_msg: Label
var portada: Control
var lbl_enter: Label
var inicio: Control
var pantalla_fin: Control
var lbl_titulo: Label
var lbl_expl: Label
var lbl_pie: Label


func _ready():
	layer = 10
	_construir_barra()
	_construir_mensajes()
	_construir_fin()
	_construir_inicio()
	_construir_portada()
	Game.mensaje.connect(_al_mensaje)
	Game.fin.connect(_al_fin)


# ---------------------------------------------------------------- AYUDAS
func _rect(pos: Vector2, tam: Vector2, color: Color, padre: Node = null) -> ColorRect:
	if padre == null:
		padre = self
	var r := ColorRect.new()
	r.color = color
	r.position = pos
	r.size = tam
	padre.add_child(r)
	return r


func _label(texto: String, pos: Vector2, tam: int = 8, color: Color = Color.WHITE, padre: Node = null) -> Label:
	if padre == null:
		padre = self
	var l := Label.new()
	l.text = texto
	l.position = pos
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # texto suave y nitido
	padre.add_child(l)
	return l


func _centrar(l: Label, ancho: float = 256.0, alto: float = 20.0):
	l.size = Vector2(ancho, alto)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _contorno(l: Label, grosor: int = 3):
	l.add_theme_constant_override("outline_size", grosor)
	l.add_theme_color_override("font_outline_color", Color(0.03, 0.06, 0.18))


# Reduce la letra hasta que el texto quepa en la caja (ancho x alto).
func _ajustar(l: Label, ancho: float, alto: float, tam: int = 8, minimo: int = 5):
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size = Vector2(ancho, alto)
	var fuente := l.get_theme_default_font()
	while tam > minimo:
		var h := fuente.get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, ancho, tam).y
		if h <= alto - 3.0:
			break
		tam -= 1
	l.add_theme_font_size_override("font_size", tam)


# Igual, pero para una sola linea: reduce la letra hasta que quepa de ancho.
func _ajustar_linea(l: Label, ancho: float, tam: int = 8, minimo: int = 5):
	var fuente := l.get_theme_default_font()
	while tam > minimo:
		if fuente.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x <= ancho:
			break
		tam -= 1
	l.add_theme_font_size_override("font_size", tam)


# ---------------------------------------------------------------- BARRA Y MENSAJES
func _construir_barra():
	_rect(Vector2(0, 0), Vector2(256, 24), Color.BLACK)
	for i in 3:
		var t := TextureRect.new()
		t.texture = tex_lleno
		t.position = Vector2(6 + i * 17, 4)
		add_child(t)
		corazones.append(t)
	lbl_a = _label("", Vector2(58, 8))
	lbl_b = _label("", Vector2(116, 8))
	lbl_c = _label("", Vector2(186, 8))


func _construir_mensajes():
	_rect(Vector2(0, 200), Vector2(256, 40), Color.WHITE)
	_rect(Vector2(1, 201), Vector2(254, 39), Color.BLACK)
	lbl_msg = _label("", Vector2(6, 204))
	lbl_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_msg.size = Vector2(244, 34)


# ---------------------------------------------------------------- PANTALLA FINAL DE NIVEL
func _construir_fin():
	pantalla_fin = Control.new()
	pantalla_fin.visible = false
	add_child(pantalla_fin)
	_rect(Vector2(0, 0), Vector2(256, 240), Color.BLACK, pantalla_fin)
	lbl_titulo = _label("", Vector2(0, 10), 16, Color.WHITE, pantalla_fin)
	_centrar(lbl_titulo)
	lbl_expl = _label("", Vector2(14, 36), 8, Color.WHITE, pantalla_fin)
	lbl_expl.size = Vector2(228, 172)
	lbl_pie = _label("", Vector2(0, 222), 8, Color(1, 0.9, 0.3), pantalla_fin)
	_centrar(lbl_pie, 256.0, 12.0)


# ---------------------------------------------------------------- INICIO DE NIVEL
func _construir_inicio():
	var d: Dictionary = Game.info
	inicio = Control.new()
	inicio.visible = true
	add_child(inicio)
	_rect(Vector2(0, 0), Vector2(256, 240), Color.BLACK, inicio)
	var t0 := _label(d["nivel"], Vector2(0, 10), 8, Color(1, 0.9, 0.3), inicio)
	_centrar(t0, 256.0, 12.0)
	var t1 := _label("MISIÓN RESCATE", Vector2(0, 22), 12, Color(0.4, 0.7, 1), inicio)
	_centrar(t1, 256.0, 16.0)
	var t2 := _label(d["titulo"], Vector2(0, 40), 16, Color(0.4, 0.7, 1), inicio)
	_centrar(t2)
	_ajustar_linea(t2, 240.0, 16, 10)
	var info := _label(d["intro"], Vector2(18, 70), 8, Color.WHITE, inicio)
	_ajustar(info, 220.0, 128.0, 8, 5)
	var pie1 := _label("ENTER: EMPEZAR", Vector2(0, 206), 8, Color(1, 0.9, 0.3), inicio)
	_centrar(pie1, 256.0, 12.0)
	var pie2 := _label("1 / 2 / 3: ELEGIR NIVEL      M: SONIDO", Vector2(0, 220), 8, Color(0.7, 0.7, 0.7), inicio)
	_centrar(pie2, 256.0, 12.0)
	inicio.visible = Game.portada_vista and not Game.intro_vista


# ---------------------------------------------------------------- PORTADA
func _construir_portada():
	portada = Control.new()
	portada.visible = not Game.portada_vista
	add_child(portada)
	var fondo := TextureRect.new()
	fondo.texture = load("res://sprites/portada.png")
	portada.add_child(fondo)

	var t1 := _label("MISIÓN RESCATE", Vector2(0, 12), 16, Color(1, 0.9, 0.35), portada)
	_centrar(t1)
	_contorno(t1, 4)
	var t2 := _label("INUNDACIÓN", Vector2(0, 34), 16, Color(0.45, 0.8, 1), portada)
	_centrar(t2)
	_contorno(t2, 4)
	var t3 := _label("Aprende a actuar cuando el agua sube", Vector2(0, 58), 8, Color.WHITE, portada)
	_centrar(t3, 256.0, 12.0)
	_contorno(t3, 3)
	_ajustar_linea(t3, 244.0, 8, 6)
	var t4 := _label("SERIOUS GAME  ·  PREVENCIÓN DE INUNDACIONES", Vector2(0, 228), 6, Color(1, 0.9, 0.35), portada)
	_centrar(t4, 256.0, 10.0)
	_contorno(t4, 2)
	lbl_enter = _label("PRESIONA ENTER", Vector2(0, 214), 8, Color.WHITE, portada)
	_centrar(lbl_enter, 256.0, 12.0)
	_contorno(lbl_enter, 3)


# ---------------------------------------------------------------- ACTUALIZACION
func _process(_d):
	if portada.visible:
		lbl_enter.visible = int(Time.get_ticks_msec() / 500.0) % 2 == 0
	for i in corazones.size():
		corazones[i].texture = tex_lleno if i < Game.vida else tex_vacio
	var t := Game.texto_hud()
	lbl_a.text = t[0]
	lbl_b.text = t[1]
	lbl_c.text = t[2]
	var urgente: bool = t[2].begins_with("TIEMPO") and Game.tiempo <= 15
	lbl_c.add_theme_color_override("font_color", Color(1, 0.3, 0.3) if urgente else Color.WHITE)


func _al_mensaje(texto):
	lbl_msg.text = texto
	_ajustar(lbl_msg, 244.0, 34.0, 8, 6)


func _al_fin(gano, titulo, explicacion):
	lbl_titulo.text = titulo
	lbl_titulo.add_theme_color_override("font_color", Color(0.4, 1, 0.5) if gano else Color(1, 0.4, 0.4))
	lbl_expl.text = explicacion
	_ajustar(lbl_expl, 228.0, 172.0, 8, 5)
	if gano and Game.nivel < Game.NIVELES:
		lbl_pie.text = "ENTER: SIGUIENTE NIVEL"
	elif gano:
		lbl_pie.text = "ENTER: JUGAR DE NUEVO"
	else:
		lbl_pie.text = "ENTER: VOLVER A INTENTAR"
	pantalla_fin.visible = true


# ---------------------------------------------------------------- CONTROLES
func _unhandled_input(event):
	# 1) Portada: Enter para pasar
	if portada.visible:
		if event.is_action_pressed("reiniciar"):
			portada.visible = false
			Game.portada_vista = true
			inicio.visible = not Game.intro_vista
			Audio.sfx("confirmar")
			Audio.musica("musica_n%d" % Game.nivel)
		return

	# 2) En la pantalla de inicio, 1 / 2 / 3 elige el nivel
	if inicio.visible and event is InputEventKey and event.pressed and not event.echo:
		var n := int(event.physical_keycode) - int(KEY_1) + 1
		if n >= 1 and n <= Game.NIVELES:
			Game.nivel = n
			Game.intro_vista = false
			get_tree().reload_current_scene()
			return

	if not event.is_action_pressed("reiniciar"):
		return
	if inicio.visible:
		inicio.visible = false
		Game.intro_vista = true
		Audio.sfx("confirmar")
		Game.iniciar()
	elif pantalla_fin.visible:
		if Game.gano:
			if Game.nivel < Game.NIVELES:
				Game.nivel += 1
				Game.intro_vista = false
			else:
				Game.nuevo_juego()
		get_tree().reload_current_scene()
