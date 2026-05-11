extends Node3D

# --- 1. VARIÁVEIS NO TOPO (Sempre fora das funções) ---
@export var enemy_scene: PackedScene 
@export var spawn_time: float = 5.0  
@export var distancia_minima: float = 25.0

# O @onready procura o player assim que a cena carrega
@onready var player = get_tree().get_first_node_in_group("player")

var timer: Timer

# --- 2. CONFIGURAÇÃO INICIAL ---
func _ready():
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = spawn_time
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout():
	spawn_enemy()

# --- 3. LÓGICA DE SPAWN ---
func spawn_enemy():
	# Verifica se a cena do inimigo foi carregada no Inspetor
	if not enemy_scene:
		print("Erro: Arraste a cena do inimigo para o EnemySpawner!")
		return

	# Pega todos os Marker3D que são filhos deste nó
	var todos_pontos = get_children().filter(func(node): return node is Marker3D)
	
	# Criamos a lista de pontos que estão longe do player
	var pontos_validos = []
	
	if player:
		for p in todos_pontos:
			# Só adiciona o ponto se a distância for maior que a mínima
			if p.global_position.distance_to(player.global_position) > distancia_minima:
				pontos_validos.append(p)
	else:
		# Se não achou o player, usa todos os pontos para não travar o jogo
		pontos_validos = todos_pontos

	# Se achou pontos seguros, spawna!
	if pontos_validos.size() > 0:
		var ponto_escolhido = pontos_validos[randi() % pontos_validos.size()]
		var inimigo = enemy_scene.instantiate()
		
		# Adiciona na raiz (root) para o inimigo ser independente do spawner
		get_tree().root.add_child(inimigo)
		
		# Posiciona o inimigo no Marker escolhido
		inimigo.global_position = ponto_escolhido.global_position
		print("Inimigo spawnado em local seguro: ", ponto_escolhido.name)
