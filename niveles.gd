extends RefCounted
# DATOS DE LOS 3 NIVELES
# Cada nivel es un diccionario: mapa, posiciones (columna, fila) y reglas.
# Para crear un nivel nuevo, copia una funcion _nivelN() y cambia los datos.
#
# LEYENDA DEL MAPA
#  . pasto   = calle/puente   ~ agua del rio   R techo   # pared   D puerta
#  T arbol   O roca   , arena   M punto de encuentro
#  C cable caido   H alcantarilla destapada   L lodo   P agua estancada
#  V vidrios   B cinta de seguridad (pasto)   b cinta de seguridad (calle)

const MAPA_1 := [
	"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
	"T.RRRRR....RRRRR....,~~~~,..RRRRR.RRRRR.MMMM...T",
	"T.RRRRR..T.RRRRR..T.,~~~~,..RRRRR.RRRRR.MMMM...T",
	"T.RRRRR....RRRRR....,~~~~,..RRRRR.RRRRR.==...T.T",
	"T.##D##....##D##....,~~~~,..##D##.##D##.==.....T",
	"T==============================================T",
	"T==============================================T",
	"T......==...........,~~~~,..............==.....T",
	"T......==.....T.....,~~~~,............T.==...T.T",
	"T..T...==.T..O....T.,~~~~,.T..O..T......==..O..T",
	"T......==...........,~~~~,..............==.....T",
	"T.RRRRR==..RRRRR....,~~~~,..RRRRR.RRRRR.==.RRRRT",
	"T.RRRRR==..RRRRR....,~~~~,..RRRRR.RRRRR.==.RRRRT",
	"T.RRRRR==..RRRRR....,~~~~,..RRRRR.RRRRR.==.RRRRT",
	"T.##D##==..##D##....,~~~~,..##D##.##D##.==.#D##T",
	"T==============================================T",
	"T==============================================T",
	"T...................,~~~~,.....................T",
	"T.................T.,~~~~,..........O..........T",
	"T..T......T...O.....,~~~~,..T....T....T......T.T",
	"T...................,~~~~,.....................T",
	"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
]

const MAPA_2 := [
	"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
	"T.MMMM.....RRRRR.RRRRR....RRRRR.RRRRR....RRRRR.T",
	"T.MMMM.T...RRRRR.RRRRR..T.RRRRR.RRRRR....RRRRR.T",
	"T..==......RRRRR.RRRRR....RRRRR.RRRRR....RRRRR.T",
	"T..==......##D##.##D##....##D##.##D##....##D##.T",
	"T=============C=============C==================T",
	"T=============C=H========H================C====T",
	"T.......==............==..............==.......T",
	"T.......==........T...==.......T......==T...O..T",
	"T..T....=HT...........==T.........T...==......TT",
	"T.......==............=C..............=H.......T",
	"T.RRRRR.==.RRRRR.RRRRR==..RRRRR.RRRRR.==.RRRRR.T",
	"T.RRRRR.==.RRRRR.RRRRR==..RRRRR.RRRRR.==.RRRRR.T",
	"T.RRRRR.==.RRRRR.RRRRR==..RRRRR.RRRRR.==.RRRRR.T",
	"T.##D##.==.##D##.##D##==..##D##.##D##.==.##D##.T",
	"T=========H========================C========H==T",
	"T==================C===========H===C===========T",
	"T..............................................T",
	"T......T......T.................O..T..........TT",
	"T....O......O.......T.........T................T",
	"T..............................................T",
	"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
]

const MAPA_3 := [
	"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
	"T.RRRRRL.B.RRRRR...LLLLLLL..RRRRR.RRRRR.MMMM...T",
	"T.RRRRR..T.RRRRRL.T.LLLLLL..RRRRR.RRRRR.MMMM...T",
	"T.RRRRR..B.RRRRR....LLLLLL..RRRRR.RRRRR.==...T.T",
	"T.##D##..B.##D##....LLPLLLL.##D##.##D##.==.....T",
	"T=====L==b=========V========================VV=T",
	"TL=L===V=bV========V======L==L===L===V=L==V====T",
	"T....PL==B...P.L....LLPLLL.L........L.L.==.....T",
	"T......==B....TP....LPLPLL...........LT.==.L.T.T",
	"TLLT...==BT..O...LT.LLLLPL.T..O..T......==..O..T",
	"T...L..L=B..........LLLLLLLL............=L.....T",
	"T.RRRRR=VB.RRRRRLL..LLLLLL..RRRRR.RRRRR.LV.RRRRT",
	"T.RRRRR==B.RRRRR..L.LLLLLL..RRRRR.RRRRR.V=PRRRRT",
	"T.RRRRR==B.RRRRR....LLLPLL..RRRRR.RRRRR.==.RRRRT",
	"TL##D##V=B.##D##..L.LLLLPL..##D##.##D##.==.#D##T",
	"T========b=====V===VLL==========L====VL===V====T",
	"T==L=====bL===LLL============L====L============T",
	"T.......PB..LL......LPLPLL.....................T",
	"T........B.L......T.LLPLLL.........LO..........T",
	"T.PT.....BT...O.....LLLPLL.LT..P.T....T......T.T",
	"T.L......B..........LPLLLLL............L.......T",
	"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
]


static func datos(n: int) -> Dictionary:
	if n == 2:
		return _nivel2()
	if n == 3:
		return _nivel3()
	return _nivel1()


# ------------------------------------------------------------------ NIVEL 1
static func _nivel1() -> Dictionary:
	return {
		"nivel": "NIVEL 1",
		"titulo": "EVACUA A TIEMPO",
		"intro": "Una tormenta inunda el barrio. 
		El agua sube desde la esquina inferior izquierda hasta 
		cubrirlo todo.\nBusca el botiquín, ayuda a tus vecinos oprimiendo la tecla (E) 
		y llega al punto de encuentro verde. 
		Camina hasta el borde de la pantalla para pasar a la 
		siguiente.\n\nEvita el agua. Mover: FLECHAS o WASD",
		"inicio_msg": "ALERTA: Las autoridades ordenan evacuar. Toma el botiquín y ve al punto de encuentro verde.",
		"mapa": MAPA_1,
		"inicio": Vector2i(4, 18),
		"botiquines": [Vector2i(12, 8)],
		"req_botiquin": true,
		"extras": [
			{"tipo": "linterna", "pos": Vector2i(18, 8)},
			{"tipo": "agua_potable", "pos": Vector2i(45, 18)},
			{"tipo": "radio", "pos": Vector2i(14, 18)},
		],
		"personas": [
			{"tipo": "vecino", "pos": Vector2i(10, 18)},
			{"tipo": "vecino", "pos": Vector2i(30, 8)},
			{"tipo": "vecino", "pos": Vector2i(26, 18)},
		],
		"interactivos": [],
		"coches": [],
		"meta": Rect2i(40, 1, 4, 2),
		"agua": {"origen": Vector2(0, 22), "inicio": 10.0},
		"tiempo": 70,
		"lluvia": 120,
		"noche": false,
		"zona": null,
		"espera": 0.0,
		"tareas": 0,
		"avisos": [
			{"t": 4.0, "texto": "RADIO: Se espera crecida del río. Evacúen hacia el punto de encuentro."},
			{"t": 10.0, "texto": "¡El agua empieza a subir desde la esquina inferior izquierda! Aléjate de ella."},
			{"t": 35.0, "texto": "RADIO: El agua avanza por todo el barrio. ¡Evacúen ya!"},
			{"t": 50.0, "texto": "ÚLTIMO AVISO: Quedan 20 segundos antes de que todo quede bajo el agua."},
		],
		"fin_tiempo": "El agua cubrió todo el barrio. Esperaste demasiado: en una inundación, evacuar a tiempo salva vidas.",
	}


# ------------------------------------------------------------------ NIVEL 2
static func _nivel2() -> Dictionary:
	return {
		"nivel": "NIVEL 2",
		"titulo": "NOCHE DE TORMENTA",
		"intro": "Se fue la luz y casi no ves. Con la linterna tu luz llega más lejos.
		\nCuidado con las chispas (cables caídos), las alcantarillas 
		destapadas y los carros arrastrados. El agua sube desde la esquina 
		inferior derecha.\n\nSaca a un niño, un adulto mayor y una mascota (E) y llévalos 
		al refugio verde.",
		"inicio_msg": "Se fue la luz y la tormenta empeora. Saca a tus vecinos y llega al refugio verde.",
		"mapa": MAPA_2,
		"inicio": Vector2i(44, 19),
		"botiquines": [],
		"req_botiquin": false,
		"extras": [
			{"tipo": "linterna", "pos": Vector2i(36, 8)},
			{"tipo": "radio", "pos": Vector2i(24, 19)},
			{"tipo": "agua_potable", "pos": Vector2i(10, 19)},
		],
		"personas": [
			{"tipo": "perro", "pos": Vector2i(41, 18)},
			{"tipo": "nino", "pos": Vector2i(28, 19)},
			{"tipo": "anciano", "pos": Vector2i(12, 8)},
		],
		"interactivos": [],
		"coches": [
			{"fila": 16, "dir": -1, "x": 40},
			{"fila": 5, "dir": 1, "x": 8},
			{"fila": 6, "dir": -1, "x": 30},
		],
		"meta": Rect2i(2, 1, 4, 2),
		"agua": {"origen": Vector2(48, 22), "inicio": 15.0},
		"tiempo": 90,
		"lluvia": 200,
		"noche": true,
		"zona": null,
		"espera": 0.0,
		"tareas": 0,
		"avisos": [
			{"t": 3.0, "texto": "RADIO: Hay cables caídos y alcantarillas destapadas en las calles. ¡Cuidado!", "requiere": "radio"},
			{"t": 7.0, "texto": "Las chispas naranjas son cables caídos con electricidad. ¡No los toques!"},
			{"t": 15.0, "texto": "¡El agua empieza a subir desde la esquina inferior derecha!"},
			{"t": 45.0, "texto": "El agua y la electricidad no se mezclan: aléjate de los cables mojados."},
			{"t": 70.0, "texto": "ÚLTIMO AVISO: Quedan 20 segundos antes de que todo quede bajo el agua."},
		],
		"fin_tiempo": "El agua cubrió todo el barrio. En una emergencia nocturna hay que salir temprano y con luz.",
	}


# ------------------------------------------------------------------ NIVEL 3
static func _nivel3() -> Dictionary:
	return {
		"nivel": "NIVEL 3",
		"titulo": "EL DÍA DESPUÉS",
		"intro": "El agua bajó, pero aún no es seguro. Habla con el rescatista 
		oprimiendo la tecla (E) y espera su autorización.\nCorta la electricidad, vacía los recipientes con agua, tira la 
		comida mojada y hierve agua. Evita lodo, vidrios y 
		charcos sucios. 
		Oprime la tecla Q para usar botiquín.\n\nCuando termines, informa en el puesto verde.",
		"inicio_msg": "El agua bajó, pero aún no es seguro. Habla con el rescatista (E) y espera su autorización.",
		"mapa": MAPA_3,
		"inicio": Vector2i(4, 18),
		"botiquines": [Vector2i(29, 18)],
		"req_botiquin": false,
		"extras": [
			{"tipo": "agua_potable", "pos": Vector2i(5, 19)},
		],
		"personas": [],
		"interactivos": [
			{"tipo": "rescatista", "pos": Vector2i(7, 18)},
			{"tipo": "interruptor", "pos": Vector2i(12, 8)},
			{"tipo": "recipiente", "pos": Vector2i(18, 19)},
			{"tipo": "recipiente", "pos": Vector2i(30, 8)},
			{"tipo": "recipiente", "pos": Vector2i(44, 18)},
			{"tipo": "comida", "pos": Vector2i(18, 8)},
			{"tipo": "comida", "pos": Vector2i(45, 9)},
			{"tipo": "estufa", "pos": Vector2i(35, 9)},
			{"tipo": "reporte", "pos": Vector2i(41, 3)},
		],
		"coches": [],
		"meta": null,
		"agua": null,
		"tiempo": 140,
		"lluvia": 0,
		"noche": false,
		"zona": Rect2i(10, 0, 38, 22),
		"espera": 12.0,
		"tareas": 7,
		"avisos": [
			{"t": 6.0, "texto": "RESCATISTA: Estamos revisando que las estructuras no se caigan. Espera un momento."},
			{"t": 60.0, "texto": "El sol empieza a bajar. Termina las tareas antes de que anochezca."},
			{"t": 120.0, "texto": "ÚLTIMO AVISO: Quedan 20 segundos de luz."},
		],
		"fin_tiempo": "Anocheció antes de terminar. Sin luz es más peligroso moverse entre lodo, vidrios y cables: planifica tus tareas.",
	}
