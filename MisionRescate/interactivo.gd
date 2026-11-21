extends Area2D
# Puntos con los que se interactua pulsando E (nivel 3): rescatista, interruptor,
# recipientes con agua, comida mojada, estufa y puesto de reporte.

var tipo := "interruptor"
var hecho := false
var cerca := false
var sprite: Sprite2D

const AVISOS := {
	"interruptor": "Interruptor general. Pulsa E para cortar la electricidad antes de tocar nada.",
	"recipiente": "Recipiente con agua estancada: ahí se crían mosquitos. Pulsa E para vaciarlo.",
	"comida": "Comida que tocó el agua sucia. Pulsa E para tirarla.",
	"estufa": "Estufa eléctrica. Pulsa E para hervir agua y volverla potable.",
	"reporte": "Puesto de reporte. Pulsa E para informar los daños a las autoridades.",
	"rescatista": "Rescatista. Pulsa E para hablar con él.",
}


func _ready():
	sprite = Sprite2D.new()
	sprite.texture = load("res://sprites/item_%s.png" % tipo)
	add_child(sprite)

	var cs := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 18
	cs.shape = forma
	add_child(cs)

	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func _al_entrar(body):
	if body.is_in_group("jugador"):
		cerca = true
		if not hecho:
			Game.mensaje.emit(AVISOS[tipo])


func _al_salir(body):
	if body.is_in_group("jugador"):
		cerca = false


func _completar(texto: String):
	hecho = true
	sprite.modulate = Color(0.6, 1.0, 0.6, 0.75)
	Game.tareas += 1
	Audio.sfx("tarea")
	Game.mensaje.emit(texto + " (%d/%d)" % [Game.tareas, Game.total_tareas])


func _unhandled_input(event):
	if not (Game.activo and not Game.terminado and cerca and event.is_action_pressed("accion")):
		return
	match tipo:
		"rescatista":
			if Game.autorizado:
				Game.mensaje.emit("RESCATISTA: Ya pueden entrar, pero con cuidado: lodo, vidrios y agua sucia.")
			else:
				Game.mensaje.emit("RESCATISTA: Aún revisamos las estructuras. Espera %d segundos más." % ceili(Game.espera))
		"interruptor":
			if not hecho:
				Audio.sfx("interruptor")
				Game.electricidad_cortada = true
				_completar("Cortaste la electricidad. Siempre hazlo antes de tocar nada eléctrico.")
		"recipiente":
			if not hecho:
				Audio.sfx("chapoteo")
				_completar("Vaciaste el recipiente: sin agua estancada no se crían mosquitos.")
		"comida":
			if not hecho:
				Audio.sfx("tirar")
				_completar("Tiraste la comida que tocó el agua: puede enfermarte aunque parezca buena.")
		"estufa":
			if hecho:
				return
			if not Game.electricidad_cortada:
				Audio.sfx("descarga")
				Game.mensaje.emit("¡Descarga! Con la casa mojada, primero corta la electricidad en el interruptor.")
				get_tree().get_first_node_in_group("jugador").golpe()
				Game.hacer_dano(1, "Tocar aparatos eléctricos en una casa inundada puede electrocutar: corta la electricidad primero.")
			elif not Game.kit_nivel.get("agua_potable", false):
				Game.mensaje.emit("Necesitas agua para hervir. Busca el agua potable.")
			else:
				Audio.sfx("hervir")
				_completar("Hervir el agua al menos un minuto la hace segura para beber.")
		"reporte":
			if Game.tareas >= Game.total_tareas:
				Game.mensaje.emit("Informaste los daños a las autoridades. ¡Gracias!")
				Game.ganar()
			else:
				Game.mensaje.emit("Aún faltan tareas: %d de %d. Complétalas antes de reportar." % [Game.tareas, Game.total_tareas])
