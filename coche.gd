extends Area2D
# Carro arrastrado por la corriente: se mueve por la calle y hace dano al tocarte.

var dir := -1
var vel := 28.0
var x_min := 16.0
var x_max := 736.0
var enfriamiento := 0.0


func _ready():
	var s := Sprite2D.new()
	s.texture = load("res://sprites/item_coche.png")
	s.flip_h = dir < 0       # el sprite mira a la derecha
	add_child(s)

	var cs := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = Vector2(28, 10)
	cs.shape = forma
	add_child(cs)

	if Game.mundo != null and Game.mundo.noche:
		add_child(Game.nueva_luz(26.0, Color(1.0, 0.9, 0.6), 0.9))   # faros


func _physics_process(delta):
	if not Game.activo or Game.terminado:
		return
	position.x += dir * vel * delta
	if dir < 0 and position.x < x_min:
		position.x = x_max
	elif dir > 0 and position.x > x_max:
		position.x = x_min

	enfriamiento -= delta
	if enfriamiento <= 0.0:
		for b in get_overlapping_bodies():
			if b.is_in_group("jugador"):
				enfriamiento = 1.5
				b.golpe()
				Audio.sfx("bocina")
				Game.mensaje.emit("¡Un carro arrastrado por la corriente! Nunca te acerques a vehículos en una calle inundada.")
				Game.hacer_dano(1, "Los carros arrastrados por la corriente son muy peligrosos: nunca cruces ni te acerques a una calle inundada.")
				break
