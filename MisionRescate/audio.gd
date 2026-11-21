extends Node
# AUTOLOAD "Audio": efectos, ambiente (lluvia, agua, truenos, pajaros) y musica.
# Si falta un archivo .wav simplemente no suena (no da error).
# Tecla M: silenciar / activar todo el sonido.

const RUTA := "res://audio/%s.wav"
const DB_MUSICA := -11.0
const DB_LLUVIA := -17.0
const DB_LLUVIA_N2 := -12.0
const DB_PAJAROS := -16.0

var cache := {}
var pool: Array[AudioStreamPlayer] = []
var p_musica: AudioStreamPlayer
var p_lluvia: AudioStreamPlayer
var p_agua: AudioStreamPlayer
var trueno_aleatorio := false
var pajaros := false
var t_trueno := 12.0
var t_pajaro := 4.0
var musica_actual := ""
var gen := 0                 # cambia al reiniciar la escena (cancela fundidos pendientes)
var tweens: Array = []


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Tres buses: Musica, Efectos y Ambiente (para poder mezclar el volumen)
	for b in ["Musica", "Efectos", "Ambiente"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = "Efectos"
		add_child(p)
		pool.append(p)
	p_musica = _nuevo("Musica")
	p_lluvia = _nuevo("Ambiente")
	p_agua = _nuevo("Ambiente")


func _nuevo(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _stream(nombre: String) -> AudioStream:
	if cache.has(nombre):
		return cache[nombre]
	var ruta := RUTA % nombre
	var s: AudioStream = null
	if ResourceLoader.exists(ruta):
		s = load(ruta)
	cache[nombre] = s
	return s


# Devuelve el sonido listo para repetirse sin cortes
func _stream_loop(nombre: String) -> AudioStream:
	var s := _stream(nombre)
	var w := s as AudioStreamWAV
	if w != null:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.data.size() / 2.0)   # 16 bits, mono
	return s


# ------------------------------------------------------------ EFECTOS
func sfx(nombre: String, db: float = 0.0, pitch: float = 1.0):
	var s := _stream(nombre)
	if s == null:
		return
	var p: AudioStreamPlayer = null
	for q in pool:
		if not q.playing:
			p = q
			break
	if p == null:
		p = pool[0]
	p.stream = s
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()


func trueno_en(retraso: float, db: float = -6.0):
	var g := gen
	await get_tree().create_timer(retraso).timeout
	if g == gen:
		sfx("trueno", db, randf_range(0.92, 1.08))


# ------------------------------------------------------------ ESCENA / MUSICA
func iniciar_escena(nivel: int, hay_lluvia: bool, hay_agua: bool):
	detener()
	musica("musica_portada" if not Game.portada_vista else "musica_n%d" % nivel)
	if hay_lluvia:
		p_lluvia.stream = _stream_loop("lluvia")
		p_lluvia.volume_db = DB_LLUVIA_N2 if nivel == 2 else DB_LLUVIA
		if p_lluvia.stream != null:
			p_lluvia.play()
	if hay_agua:
		p_agua.stream = _stream_loop("agua_sube")
		p_agua.volume_db = -60.0           # se activa cuando empieza a subir el agua
	trueno_aleatorio = nivel == 1
	pajaros = nivel == 3
	t_trueno = randf_range(8.0, 16.0)
	t_pajaro = randf_range(2.0, 5.0)


func musica(nombre: String):
	if nombre == musica_actual and p_musica.playing:
		return
	musica_actual = nombre
	var s := _stream_loop(nombre)
	if s == null:
		p_musica.stop()
		return
	p_musica.stream = s
	p_musica.volume_db = DB_MUSICA
	p_musica.play()


# Sube el rumor del agua segun avanza la inundacion (p de 0 a 1)
func nivel_agua(p: float):
	if p_agua.stream == null:
		return
	if not p_agua.playing:
		p_agua.play()
	p_agua.volume_db = linear_to_db(0.12 + 0.88 * clampf(p, 0.0, 1.0)) - 9.0


func fin(gano: bool):
	_fade(p_musica, 0.4)
	_fade(p_lluvia, 1.2)
	_fade(p_agua, 1.2)
	trueno_aleatorio = false
	pajaros = false
	sfx("victoria" if gano else "derrota", -2.0)


func _fade(p: AudioStreamPlayer, d: float):
	if not p.playing:
		return
	var g := gen
	var tw := create_tween()
	tween_agregar(tw)
	tw.tween_property(p, "volume_db", -60.0, d)
	tw.tween_callback(_parar.bind(p, g))


func _parar(p: AudioStreamPlayer, g: int):
	if g == gen:
		p.stop()


func tween_agregar(tw: Tween):
	tweens.append(tw)


func detener():
	gen += 1
	for t in tweens:
		if t.is_valid():
			t.kill()
	tweens.clear()
	p_musica.stop()
	p_lluvia.stop()
	p_agua.stop()
	for p in pool:
		p.stop()
	musica_actual = ""


# ------------------------------------------------------------ AMBIENTE ALEATORIO
func _process(delta):
	if not Game.activo or Game.terminado:
		return
	if trueno_aleatorio:
		t_trueno -= delta
		if t_trueno <= 0.0:
			t_trueno = randf_range(14.0, 26.0)
			sfx("trueno", randf_range(-14.0, -8.0), randf_range(0.9, 1.1))
	if pajaros:
		t_pajaro -= delta
		if t_pajaro <= 0.0:
			t_pajaro = randf_range(3.0, 8.0)
			sfx("pajaro1" if randf() < 0.5 else "pajaro2", DB_PAJAROS, randf_range(0.9, 1.15))


func _unhandled_input(event):
	if event.is_action_pressed("silencio"):
		var apagar := not AudioServer.is_bus_mute(0)
		AudioServer.set_bus_mute(0, apagar)
		Game.mensaje.emit("Sonido apagado. Pulsa M para encenderlo." if apagar else "Sonido encendido. Pulsa M para apagarlo.")
