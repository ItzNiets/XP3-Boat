extends Control
class_name IndicatorsSystem

var camera: Camera3D
var navio: ShipBuoyancy

func _ready():
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	queue_redraw()

func _draw():
	if not camera or not is_instance_valid(camera):
		camera = get_viewport().get_camera_3d()
		if not camera: return

	if not navio or not is_instance_valid(navio):
		navio = _find_navio(get_tree().current_scene)

	_draw_enemy_indicators()
	_draw_ship_compass()

func _find_navio(node: Node) -> ShipBuoyancy:
	if node is ShipBuoyancy:
		return node
	for c in node.get_children():
		var result = _find_navio(c)
		if result:
			return result
	return null

func _draw_enemy_indicators():
	var enemies = get_tree().get_nodes_in_group("inimigos")
	var viewport_rect = get_viewport_rect()
	var center = viewport_rect.size / 2.0
	
	# Margem para os indicadores não ficarem colados na borda
	var margin = 60.0
	var bounds = viewport_rect.grow(-margin)

	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		
		var enemy_pos = enemy.global_position
		var is_behind = camera.is_position_behind(enemy_pos)
		var screen_pos = camera.unproject_position(enemy_pos)
		
		# Se estiver fora da tela ou atrás da câmera
		if is_behind or not bounds.has_point(screen_pos):
			var dir = (screen_pos - center).normalized()
			
			if is_behind:
				dir = -dir # Inverte se estiver atrás da câmera
				
			var indicator_pos = _intersect_with_bounds(center, dir, bounds)
			_draw_arrow(indicator_pos, dir, Color(1, 0.2, 0.2, 0.8), 24.0)

func _intersect_with_bounds(center: Vector2, dir: Vector2, bounds: Rect2) -> Vector2:
	if dir == Vector2.ZERO: return center
	
	var half_size = bounds.size / 2.0
	var t_x = INF
	var t_y = INF
	
	if dir.x != 0:
		t_x = half_size.x / abs(dir.x)
	if dir.y != 0:
		t_y = half_size.y / abs(dir.y)
		
	var t = min(t_x, t_y)
	return center + dir * t

func _draw_ship_compass():
	if not navio or not is_instance_valid(navio): return
	
	var viewport_rect = get_viewport_rect()
	# Posição da bússola na tela (centro inferior)
	var center = Vector2(viewport_rect.size.x / 2.0, viewport_rect.size.y - 80.0)
	
	# A direção frontal no Godot é geralmente o eixo Z local do transform da base (se move ao longo dele no _physics_process)
	var forward_3d = navio.global_transform.basis.z.normalized()
	if forward_3d.length_squared() < 0.1: return
	
	var ship_pos = navio.global_position
	var ship_front = ship_pos + forward_3d * 5.0
	
	var screen_ship = camera.unproject_position(ship_pos)
	var screen_front = camera.unproject_position(ship_front)
	
	var dir_2d = (screen_front - screen_ship).normalized()
	
	if dir_2d.length_squared() > 0.1 and not camera.is_position_behind(ship_pos) and not camera.is_position_behind(ship_front):
		# Fundo da bússola
		draw_circle(center, 30.0, Color(0.1, 0.1, 0.1, 0.6))
		draw_arc(center, 30.0, 0, TAU, 32, Color(0.8, 0.8, 0.8, 0.8), 2.0)
		
		# Seta de direção azul ciano indicando o movimento do barco
		_draw_arrow(center + dir_2d * 12.0, dir_2d, Color(0.2, 0.8, 1.0, 1.0), 18.0)

func _draw_arrow(pos: Vector2, dir: Vector2, color: Color, size: float):
	var perp = Vector2(-dir.y, dir.x)
	var p1 = pos + dir * size # Ponta
	var p2 = pos - dir * (size * 0.5) + perp * (size * 0.6) # Base esquerda
	var p3 = pos - dir * (size * 0.5) - perp * (size * 0.6) # Base direita
	
	var pts = PackedVector2Array([p1, p2, p3])
	draw_colored_polygon(pts, color)
