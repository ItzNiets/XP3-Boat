extends Camera3D

## Câmera que segue o ponto médio entre os dois jogadores,
## mantendo a mesma perspectiva elevada isométrica.

# Offset relativo ao alvo (posição inicial da câmera em relação ao navio)
@export var offset := Vector3(7.0, 18.0, 0.0)
@export var follow_speed := 3.0

var _players: Array[Node3D] = []
var _navio: Node3D

func _ready() -> void:
	call_deferred("_find_targets")

func _find_targets() -> void:
	var root = get_tree().current_scene
	_search(root)

func _search(node: Node) -> void:
	if node is ShipBuoyancy:
		_navio = node
	if node is CharacterBody3D and "active" in node:
		_players.append(node)
	for c in node.get_children():
		_search(c)

func _process(delta: float) -> void:
	# Calcular ponto alvo
	var target_pos := Vector3.ZERO

	if _players.size() >= 2 and is_instance_valid(_players[0]) and is_instance_valid(_players[1]):
		# Ponto médio entre os dois jogadores
		target_pos = (_players[0].global_position + _players[1].global_position) / 2.0
	elif _players.size() >= 1 and is_instance_valid(_players[0]):
		target_pos = _players[0].global_position
	elif _navio and is_instance_valid(_navio):
		target_pos = _navio.global_position
	else:
		return

	# Mover a câmera suavemente para o alvo + offset
	var desired_pos = target_pos + offset
	global_position = global_position.lerp(desired_pos, delta * follow_speed)
