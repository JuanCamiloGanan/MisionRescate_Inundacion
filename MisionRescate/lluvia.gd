extends CanvasLayer
# Lluvia: gotas que caen en diagonal, pequenos chapoteos al tocar el suelo
# y un tinte azul oscuro de tormenta. Solo se dibuja sobre la zona de juego.

var cantidad := 120
const TOPE := 24.0      # y donde empieza la zona de juego (debajo de la barra)
const FONDO := 200.0    # y donde termina (encima de la caja de mensajes)

var gotas: Array = []
var chapoteos: Array = []
var lienzo: Node2D


func _ready():
	layer = 5   # encima del mundo, debajo del HUD (capa 10)

	var tinte := ColorRect.new()
	tinte.color = Color(0.05, 0.1, 0.3, 0.2)
	tinte.position = Vector2(0, TOPE)
	tinte.size = Vector2(256, FONDO - TOPE)
	tinte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tinte)

	lienzo = Node2D.new()
	lienzo.draw.connect(_dibujar)
	add_child(lienzo)

	for i in cantidad:
		gotas.append(_nueva(true))


func _nueva(inicial: bool) -> Dictionary:
	var y := randf_range(TOPE, FONDO) if inicial else randf_range(TOPE - 20.0, TOPE)
	return {
		"p": Vector2(randf_range(20.0, 290.0), y),
		"v": randf_range(170.0, 250.0),            # velocidad de caida
		"s": randf_range(TOPE + 20.0, FONDO),      # altura a la que "toca el suelo"
	}


func _process(delta):
	for g in gotas:
		g["p"] += Vector2(-35.0, g["v"]) * delta
		if g["p"].y >= g["s"]:
			if g["p"].x > 0.0 and g["p"].x < 256.0:
				chapoteos.append({"p": g["p"], "t": 0.0})
			var n := _nueva(false)
			g["p"] = n["p"]
			g["v"] = n["v"]
			g["s"] = n["s"]
	for c in chapoteos:
		c["t"] += delta
	chapoteos = chapoteos.filter(func(c): return c["t"] < 0.2)
	lienzo.queue_redraw()


func _dibujar():
	for g in gotas:
		var p: Vector2 = g["p"]
		var dir := Vector2(-35.0, g["v"]).normalized()
		lienzo.draw_line(p, p - dir * 6.0, Color(0.8, 0.9, 1.0, 0.7), 1.0)
	for c in chapoteos:
		var k: float = c["t"] / 0.2
		var p: Vector2 = c["p"]
		var col := Color(0.85, 0.93, 1.0, 0.7 * (1.0 - k))
		var r := 1.5 + 3.0 * k
		lienzo.draw_line(p + Vector2(-r, 0), p + Vector2(-r * 0.5, -1.5), col, 1.0)
		lienzo.draw_line(p + Vector2(r, 0), p + Vector2(r * 0.5, -1.5), col, 1.0)
