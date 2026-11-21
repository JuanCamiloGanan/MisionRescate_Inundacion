extends CharacterBody2D
# Jugador: se mueve en 4 direcciones como en Zelda 1986.
# El efecto del suelo (agua, cables, lodo...) lo pregunta a main.gd con suelo().

const VELOCIDAD := 55.0

var anterior := ""
var temporizador := 0.0
var aturdido := 0.0
var paso_t := 0.0
var sprite: Sprite2D


func _ready():
	add_to_group("jugador")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING   # vista desde arriba

	sprite = Sprite2D.new()
	sprite.texture = load("res://sprites/jugador.png")
	sprite.hframes = 4
	add_child(sprite)

	var cs := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = Vector2(10, 10)
	cs.shape = forma
	cs.position = Vector2(0, 3)
	add_child(cs)


func _physics_process(delta):
	if not Game.activo or Game.terminado or Game.transicion:
		velocity = Vector2.ZERO
		return
	if aturdido > 0.0:
		aturdido -= delta
		velocity = Vector2.ZERO
		return

	# Solo 4 direcciones, sin diagonales (como Zelda)
	var entrada := Input.get_vector("izquierda", "derecha", "arriba", "abajo")
	var dir := Vector2.ZERO
	if absf(entrada.x) > absf(entrada.y):
		dir = Vector2(signf(entrada.x), 0)
	elif entrada.y != 0:
		dir = Vector2(0, signf(entrada.y))

	# Frame del sprite segun la direccion: 0 abajo, 1 arriba, 2 izquierda, 3 derecha
	if dir.y > 0:
		sprite.frame = 0
	elif dir.y < 0:
		sprite.frame = 1
	elif dir.x < 0:
		sprite.frame = 2
	elif dir.x > 0:
		sprite.frame = 3

	# Pequeno saltito al caminar
	if dir != Vector2.ZERO:
		sprite.position.y = -1 if int(Time.get_ticks_msec() / 150.0) % 2 == 0 else 0
	else:
		sprite.position.y = 0

	var suelo := ""
	if Game.mundo != null:
		suelo = Game.mundo.suelo(global_position + Vector2(0, 3))
	var mult := _efecto_suelo(suelo, delta)

	# Sonido de pasos (cambia segun el suelo)
	if dir != Vector2.ZERO:
		paso_t -= delta
		if paso_t <= 0.0:
			paso_t = 0.28 if mult >= 1.0 else 0.4
			_sonido_paso(suelo)
	else:
		paso_t = 0.0

	velocity = dir * VELOCIDAD * mult
	move_and_slide()


# Devuelve el multiplicador de velocidad del suelo y aplica su dano o efecto.
func _efecto_suelo(suelo: String, delta: float) -> float:
	var cambio := suelo != anterior
	anterior = suelo
	temporizador -= delta
	match suelo:
		"agua":
			if cambio:
				temporizador = 0.6
				Audio.sfx("chapoteo")
				Game.mensaje.emit("¡Estás en el agua! Es peligrosa: sal de ella de inmediato.")
			if temporizador <= 0.0:
				temporizador = 1.0
				golpe()
				Game.hacer_dano(1, "Caminar por el agua de una inundación es muy peligroso: la corriente arrastra, puede haber cables eléctricos y objetos ocultos.")
			return 0.5
		"cable", "cable_agua":
			if cambio or temporizador <= 0.0:
				temporizador = 1.0
				golpe()
				Audio.sfx("descarga")
				if suelo == "cable_agua":
					Game.mensaje.emit("¡Descarga fuerte! Un cable con agua cerca es mortal. ¡Aléjate!")
					Game.hacer_dano(2, "Los cables caídos con agua cerca pueden electrocutar. Nunca los toques y avisa a las autoridades.")
				else:
					Game.mensaje.emit("¡Descarga! Nunca toques cables caídos: avisa a las autoridades.")
					Game.hacer_dano(1, "Los cables caídos pueden electrocutar. Nunca los toques y avisa a las autoridades.")
			return 1.0
		"hueco":
			if cambio:
				aturdido = 0.5
				golpe()
				Audio.sfx("hueco")
				Game.mensaje.emit("¡Caíste en una alcantarilla destapada! Con lluvia y oscuridad no se ven.")
				Game.hacer_dano(1, "Las alcantarillas destapadas son trampas invisibles en una inundación. Camina por zonas conocidas y con luz.")
			return 1.0
		"vidrio":
			if cambio or temporizador <= 0.0:
				temporizador = 1.5
				golpe()
				Audio.sfx("vidrio")
				Game.mensaje.emit("¡Auch! Pisaste vidrios rotos. Usa calzado cerrado y camina con cuidado.")
				Game.hacer_dano(1, "Después de una inundación hay vidrios y objetos filosos escondidos en el lodo: usa botas y guantes.")
			return 0.8
		"charco":
			if cambio:
				temporizador = 0.0
				Audio.sfx("chapoteo", -4.0, 0.8)
				Game.mensaje.emit("Agua estancada y sucia: contamina y enferma. ¡Sal de ahí!")
			if temporizador <= 0.0:
				temporizador = 1.2
				Game.contaminar(1)
			return 0.7
		"lodo":
			if cambio:
				Audio.sfx("lodo")
				Game.mensaje.emit("El lodo te frena y esconde objetos peligrosos.")
			return 0.6
	return 1.0


func golpe():
	sprite.modulate = Color(1, 0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.4)


func _sonido_paso(suelo: String):
	match suelo:
		"agua", "charco":
			Audio.sfx("chapoteo", -9.0, randf_range(0.9, 1.2))
		"lodo":
			Audio.sfx("lodo", -8.0, randf_range(0.9, 1.15))
		_:
			Audio.sfx("paso", -12.0, randf_range(0.9, 1.15))
