extends Area2D
# Objeto recogible (botiquin, linterna, agua, radio). Se elige con la variable "tipo".

var tipo := "botiquin"

const MENSAJES := {
	"botiquin": "Tomaste el botiquín. Es lo más importante de un kit de emergencia.",
	"linterna": "Linterna: tu luz llega más lejos y ves mejor en la oscuridad.",
	"agua_potable": "Agua potable: el agua de una inundación está contaminada, no la bebas.",
	"radio": "Radio de pilas: así recibes las indicaciones de las autoridades.",
}


func _ready():
	var s := Sprite2D.new()
	s.texture = load("res://sprites/item_%s.png" % tipo)
	add_child(s)

	var cs := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = Vector2(12, 12)
	cs.shape = forma
	add_child(cs)

	body_entered.connect(_al_entrar)


func _al_entrar(body):
	if not body.is_in_group("jugador"):
		return
	if tipo == "botiquin":
		Game.botiquin = true
		if Game.nivel == 3:
			Game.mensaje.emit("Botiquín: pulsa Q cuando estés sucio o herido para curarte.")
		else:
			Game.mensaje.emit(MENSAJES[tipo])
	else:
		Game.extras += 1
		Game.kit_nivel[tipo] = true
		Game.mensaje.emit(MENSAJES[tipo])
	Audio.sfx("recoger")
	Game.item_recogido.emit(tipo)
	queue_free()
