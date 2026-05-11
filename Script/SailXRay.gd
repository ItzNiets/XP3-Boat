extends Node3D
## Torna as velas semi-transparentes quando elas bloqueiam a visão
## da câmera até os jogadores. Adicionar como filho do NodeShip.

@export var transparent_alpha := 0.25           ## Alfa quando a vela está ocluindo
@export var fade_speed := 8.0                    ## Velocidade de transição

# Nomes dos nós de vela dentro do modelo do navio
const SAIL_NAMES := [
	"StylShip_SailBack",
	"StylShip_SailMid1",
	"StylShip_SailMid2",
	"StylShip_SailFront",
	"StylShip_MainFlag",
	"StylShip_Flag1",
	"StylShip_Flag2",
]

# Cache
var _camera: Camera3D
var _players: Array[CharacterBody3D] = []
var _sails: Array[MeshInstance3D] = []
# Original materials por vela (para restaurar)
var _original_materials: Dictionary = {}
# Material transparente clonado por vela
var _transparent_materials: Dictionary = {}
# Estado atual de cada vela (true = deve estar transparente)
var _sail_occluding: Dictionary = {}

func _ready() -> void:
	call_deferred("_setup")

func _setup() -> void:
	# Encontrar a câmera
	_camera = get_viewport().get_camera_3d()

	# Encontrar jogadores
	var root = get_tree().current_scene
	_find_players(root)

	# Encontrar as velas recursivamente no navio
	_find_sails(get_parent())

	# Preparar materiais transparentes para cada vela
	for sail in _sails:
		var orig_mat = sail.get_active_material(0)
		if orig_mat == null:
			continue
		_original_materials[sail] = orig_mat

		# Clonar material e configurar para transparência
		var trans_mat = orig_mat.duplicate() as StandardMaterial3D
		if trans_mat:
			trans_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			trans_mat.albedo_color.a = transparent_alpha
			trans_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			_transparent_materials[sail] = trans_mat

		_sail_occluding[sail] = false

func _find_players(node: Node) -> void:
	if node is CharacterBody3D and "active" in node:
		_players.append(node as CharacterBody3D)
	for c in node.get_children():
		_find_players(c)

func _find_sails(node: Node) -> void:
	if node is MeshInstance3D:
		for sail_name in SAIL_NAMES:
			if node.name == sail_name:
				_sails.append(node as MeshInstance3D)
				break
	for c in node.get_children():
		_find_sails(c)

func _process(delta: float) -> void:
	if not _camera or _players.is_empty() or _sails.is_empty():
		return

	# Determinar quais velas estão entre a câmera e algum jogador
	var occluding_sails: Dictionary = {}
	for sail in _sails:
		occluding_sails[sail] = false

	var space_state = get_world_3d().direct_space_state

	for player in _players:
		if not is_instance_valid(player):
			continue

		var cam_pos = _camera.global_position
		# Ponto alvo = centro do jogador (um pouco acima do chão)
		var player_pos = player.global_position + Vector3(0, 1.0, 0)
		var direction = player_pos - cam_pos
		var distance = direction.length()

		if distance < 0.1:
			continue

		# Verificar AABB de cada vela contra o raio câmera→jogador
		for sail in _sails:
			if not is_instance_valid(sail):
				continue
			if occluding_sails.get(sail, false):
				continue  # Já marcada

			# Pegar AABB global da vela
			var aabb = sail.get_aabb()
			var sail_transform = sail.global_transform
			# Transformar os 8 cantos para world space e criar AABB global
			var global_aabb = _get_global_aabb(sail)

			# Checar se a vela está entre a câmera e o jogador
			# Expandir a AABB um pouco para dar margem
			var expanded_aabb = global_aabb.grow(0.5)

			# Verificar se o segmento câmera→jogador intersecta a AABB da vela
			if _segment_intersects_aabb(cam_pos, player_pos, expanded_aabb):
				occluding_sails[sail] = true

	# Aplicar ou remover transparência suavemente
	for sail in _sails:
		if not is_instance_valid(sail):
			continue
		var should_be_transparent = occluding_sails.get(sail, false)

		if should_be_transparent and sail in _transparent_materials:
			# Tornar transparente
			if sail.material_override != _transparent_materials[sail]:
				sail.material_override = _transparent_materials[sail]
			# Fade in da transparência
			var mat = sail.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color.a = lerpf(mat.albedo_color.a, transparent_alpha, delta * fade_speed)
		else:
			# Restaurar opacidade
			if sail.material_override != null and sail in _transparent_materials:
				var mat = sail.material_override as StandardMaterial3D
				if mat:
					mat.albedo_color.a = lerpf(mat.albedo_color.a, 1.0, delta * fade_speed)
					if mat.albedo_color.a > 0.95:
						sail.material_override = _original_materials[sail]

func _get_global_aabb(mesh: MeshInstance3D) -> AABB:
	var local_aabb = mesh.get_aabb()
	var xform = mesh.global_transform
	# Transformar os 8 cantos
	var min_pos = Vector3(INF, INF, INF)
	var max_pos = Vector3(-INF, -INF, -INF)
	for i in range(8):
		var corner = Vector3(
			local_aabb.position.x if (i & 1) == 0 else local_aabb.end.x,
			local_aabb.position.y if (i & 2) == 0 else local_aabb.end.y,
			local_aabb.position.z if (i & 4) == 0 else local_aabb.end.z,
		)
		var world_corner = xform * corner
		min_pos.x = min(min_pos.x, world_corner.x)
		min_pos.y = min(min_pos.y, world_corner.y)
		min_pos.z = min(min_pos.z, world_corner.z)
		max_pos.x = max(max_pos.x, world_corner.x)
		max_pos.y = max(max_pos.y, world_corner.y)
		max_pos.z = max(max_pos.z, world_corner.z)
	return AABB(min_pos, max_pos - min_pos)

func _segment_intersects_aabb(p1: Vector3, p2: Vector3, aabb: AABB) -> bool:
	# Slab method para interseção segmento-AABB
	var dir = p2 - p1
	var t_min = 0.0
	var t_max = 1.0  # Segmento limitado entre p1 e p2

	for axis in range(3):
		var origin = p1[axis]
		var d = dir[axis]
		var aabb_min = aabb.position[axis]
		var aabb_max = aabb.position[axis] + aabb.size[axis]

		if abs(d) < 1e-8:
			# Raio paralelo ao eixo
			if origin < aabb_min or origin > aabb_max:
				return false
		else:
			var t1 = (aabb_min - origin) / d
			var t2 = (aabb_max - origin) / d
			if t1 > t2:
				var tmp = t1
				t1 = t2
				t2 = tmp
			t_min = max(t_min, t1)
			t_max = min(t_max, t2)
			if t_min > t_max:
				return false

	return true
