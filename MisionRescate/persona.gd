extends Area2D
# Persona a la que ayudar. Pulsa E cerca y te seguira hasta el punto de encuentro.
# Cada "tipo" se comporta distinto: vecino, anciano (lento), nino (se asusta), perro (rapido).

var tipo := "vecino"
var cerca := false
var ayudada := false
var a_salvo := false
var sprite: Sprite2D
var jugador: Node2D
var vel := 45.0
var umbral := 20.0
var t_miedo := 0.0

const PERFIL := {
	"vecino": {"sprite": "persona", "vel": 45.0, "umbral": 20.0,
		"aviso": "Un vecino necesita ayuda. Pulsa E para guiarlo a la zona segura.",
		"ayuda": "Tu vecino te sigue. Llévalo al punto de encuentro verde."},
	"anciano": {"sprite": "anciano", "vel": 24.0, "umbral": 18.0,
		"aviso": "Un adulto mayor necesita ayuda. Pulsa E: camina despacio, ten paciencia.",
		"ayuda": "Camina lento: espéralo para no dejarlo atrás."},
	"nino": {"sprite": "nino", "vel": 50.0, "umbral": 18.0,
		"aviso": "Un niño asustado llora. Pulsa E para tomarlo de la mano.",
		"ayuda": "El niño solo te sigue si estás cerca. ¡No lo dejes solo!"},
	"perro": {"sprite": "perro", "vel": 64.0, "umbral": 14.0,
		"aviso": "Una mascota asustada. Pulsa E para llamarla.",
		"ayuda": "La mascota te sigue. ¡Llévala a la zona segura!"},
}


func _ready():
	add_to_group("persona")
	var perfil: Dictionary = PERFIL[tipo]
	vel = perfil["vel"]
	umbral = perfil["umbral"]

	sprite = Sprite2D.new()
	sprite.texture = load("res://sprites/item_%s.png" % perfil["sprite"])
	add_child(sprite)

	var cs := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 20
	cs.shape = forma
	add_child(cs)

	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func _al_entrar(body):
	if body.is_in_group("jugador"):
		cerca = true
		if not ayudada:
			Game.mensaje.emit(PERFIL[tipo]["aviso"])


func _al_salir(body):
	if body.is_in_group("jugador"):
		cerca = false


func _unhandled_input(event):
	if Game.activo and not Game.terminado and cerca and not ayudada and event.is_action_pressed("accion"):
		ayudada = true
		if tipo == "vecino":
			sprite.texture = load("res://sprites/item_persona_ayudada.png")
		else:
			sprite.modulate = Color(0.7, 1.0, 0.7)
		Audio.sfx("ladrido" if tipo == "perro" else "ayudar")
		Game.mensaje.emit(PERFIL[tipo]["ayuda"])


func _process(delta):
	if not ayudada or Game.terminado:
		return
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
		return

	var d := global_position.distance_to(jugador.global_position)
	var u := 4.0 if Game.en_meta else umbral
	var puede := true
	# El nino se asusta y se queda quieto si te alejas demasiado
	if tipo == "nino" and d > 72.0 and not Game.en_meta:
		puede = false
		t_miedo -= delta
		if t_miedo <= 0.0:
			t_miedo = 4.0
			Audio.sfx("miedo", -4.0)
			Game.mensaje.emit("¡Tengo miedo! No me dejes solo.")
	if puede and d > u:
		global_position = global_position.move_toward(jugador.global_position, vel * delta)

	# Cuenta como rescatado cuando llega al punto de encuentro
	if not a_salvo and Game.meta_rect.has_point(global_position):
		a_salvo = true
		Game.rescatados += 1
		Audio.sfx("salvo")
		Game.mensaje.emit("¡Llegó a salvo! Van %d de %d." % [Game.rescatados, Game.total_personas])
