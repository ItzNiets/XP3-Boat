extends Node3D

# --- CONFIGURAÇÕES ---
@export var enemy_scene: PackedScene
@export var spawn_distance: float = 60.0     # Distância de spawn ao redor do navio
@export var spawn_interval: float = 1.5       # Intervalo entre spawns individuais

var _navio: Node3D
var _spawn_timer: Timer
var _inimigos_para_spawnar := 0
var _onda_atual := 0

func _ready():
	# Timer para spawn em rajadas
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.timeout.connect(_spawn_one)
	add_child(_spawn_timer)

	# Conectar aos sinais do Manager
	Manager.onda_iniciada.connect(_on_onda_iniciada)
	Manager.fase_terminada.connect(_on_fase_terminada)

	# Encontrar o navio
	call_deferred("_find_navio")

func _find_navio() -> void:
	var root = get_tree().current_scene
	_navio = _search_navio(root)

func _search_navio(node: Node) -> Node3D:
	if node is ShipBuoyancy:
		return node
	for c in node.get_children():
		var result = _search_navio(c)
		if result:
			return result
	return null

func _on_onda_iniciada(numero: int) -> void:
	_onda_atual = numero
	_inimigos_para_spawnar = Manager.inimigos_na_onda
	print("Spawner: Preparando ", _inimigos_para_spawnar, " inimigos para onda ", numero)
	_spawn_timer.start()

func _on_fase_terminada(_vitoria: bool) -> void:
	_spawn_timer.stop()
	_inimigos_para_spawnar = 0

func _spawn_one() -> void:
	if _inimigos_para_spawnar <= 0:
		_spawn_timer.stop()
		return

	if not enemy_scene:
		print("Erro: Cena do inimigo não configurada!")
		return

	_inimigos_para_spawnar -= 1

	var inimigo = enemy_scene.instantiate()
	get_tree().root.add_child(inimigo)

	# Calcular posição de spawn À FRENTE e aos lados do navio
	var spawn_pos = _calcular_posicao_spawn()
	inimigo.global_position = spawn_pos

	print("Inimigo spawnado! Restantes: ", _inimigos_para_spawnar)

	if _inimigos_para_spawnar <= 0:
		_spawn_timer.stop()

func _calcular_posicao_spawn() -> Vector3:
	var centro := Vector3.ZERO
	var direcao_frente := Vector3.FORWARD  # Default

	if _navio and is_instance_valid(_navio):
		centro = _navio.global_position
		# Pegar a direção que o navio está andando (basis.z)
		direcao_frente = _navio.global_transform.basis.z.normalized()

	# Spawnar PREDOMINANTEMENTE à frente e aos lados do navio
	# Ângulo: -90° a +90° em relação à frente (semicírculo frontal)
	# Isso garante que os inimigos apareçam onde o navio está indo
	var angulo_offset = randf_range(-PI * 0.7, PI * 0.7)  # -126° a +126° (amplo mas frontal)

	# Calcular direção de spawn rotacionada
	var direcao_spawn = direcao_frente.rotated(Vector3.UP, angulo_offset)

	# Variar a distância
	var dist = spawn_distance + randf_range(-15.0, 15.0)

	var pos = centro + direcao_spawn * dist
	pos.y = 0.5  # Ligeiramente acima da água

	return pos
