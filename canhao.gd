extends Node3D

@export var bullet_config: PackedScene

# --- VARIÁVEIS DE ESTADO ---
var esta_operando = false
var player_referencia = null
var player_id := 0

# --- GIRO HORIZONTAL (limitado) ---
var velocidade_giro := 120.0
var angulo_h := 90.0
var limite_esq := 0.0
var limite_dir := 180.0

# --- INCLINAÇÃO VERTICAL ---
var angulo_v := 10.0  # Começa levemente inclinado para cima
var velocidade_inclinacao := 60.0
var limite_cima := 55.0   # Mais alto para arcos longos
var limite_baixo := -5.0

# --- COOLDOWN DE TIRO ---
var pode_atirar := true
var cooldown_tiro := 0.4
const DEADZONE := 0.2

# --- TRAJETÓRIA ---
const BULLET_SPEED := 25.0
const BULLET_GRAVITY := 14.0
const TRAJ_STEPS := 25
const TRAJ_DT := 0.08

var _preview_dots: Array[MeshInstance3D] = []
var _landing_marker: MeshInstance3D
var _is_b_side := false

# SpawnPoint
var spawn_point: Marker3D

func _ready():
	var canhao_body = get_node_or_null("Canhao")
	if canhao_body:
		spawn_point = canhao_body.get_node_or_null("SpawnPoint")
		if not spawn_point:
			spawn_point = canhao_body.get_node_or_null("SpawnPointB")
			_is_b_side = true

	call_deferred("_create_preview")

func _create_preview():
	# Pontos da trajetória (pequenas esferas amarelas)
	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = 0.15
	dot_mesh.height = 0.3

	var dot_mat = StandardMaterial3D.new()
	dot_mat.albedo_color = Color(1, 0.9, 0.2, 0.6)
	dot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for i in range(TRAJ_STEPS):
		var m = MeshInstance3D.new()
		m.mesh = dot_mesh
		m.material_override = dot_mat
		m.top_level = true  # Posição global independente
		m.visible = false
		add_child(m)
		_preview_dots.append(m)

	# Marcador de pouso (disco vermelho no chão)
	var marker_mesh = CylinderMesh.new()
	marker_mesh.top_radius = 1.2
	marker_mesh.bottom_radius = 1.2
	marker_mesh.height = 0.1

	var marker_mat = StandardMaterial3D.new()
	marker_mat.albedo_color = Color(1, 0.15, 0.15, 0.5)
	marker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	_landing_marker = MeshInstance3D.new()
	_landing_marker.mesh = marker_mesh
	_landing_marker.material_override = marker_mat
	_landing_marker.top_level = true
	_landing_marker.visible = false
	add_child(_landing_marker)

func _process(delta):
	if esta_operando:
		_handle_input(delta)
		_update_trajectory()
	else:
		_hide_preview()

func _handle_input(delta):
	var dir_h := 0.0
	var dir_v := 0.0
	var quer_atirar := false

	if player_id == 0:
		if Input.is_key_pressed(KEY_LEFT): dir_h += 1.0
		if Input.is_key_pressed(KEY_RIGHT): dir_h -= 1.0
		if Input.is_key_pressed(KEY_UP): dir_v += 1.0
		if Input.is_key_pressed(KEY_DOWN): dir_v -= 1.0
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER):
			quer_atirar = true
	else:
		var stick_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		var stick_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		if abs(stick_x) > DEADZONE:
			dir_h = -stick_x
		if abs(stick_y) > DEADZONE:
			dir_v = -stick_y
		var trigger = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
		if trigger > 0.5:
			quer_atirar = true
		if Input.is_joy_button_pressed(0, JOY_BUTTON_B):
			quer_atirar = true

	# Inverter controle horizontal nos canhões B (de frente para a câmera)
	# Vertical também precisa inverter pela rotação de 90° da cena
	if _is_b_side:
		dir_h = -dir_h
		dir_v = -dir_v

	# Rotação horizontal
	angulo_h += dir_h * velocidade_giro * delta
	angulo_h = clamp(angulo_h, limite_esq, limite_dir)
	rotation_degrees.y = angulo_h

	# Inclinação vertical
	angulo_v += dir_v * velocidade_inclinacao * delta
	angulo_v = clamp(angulo_v, limite_baixo, limite_cima)
	rotation_degrees.x = angulo_v

	if quer_atirar and pode_atirar:
		atirar()

func _get_launch_velocity() -> Vector3:
	if not spawn_point:
		return Vector3.ZERO
	if _is_b_side:
		return spawn_point.global_transform.basis.z * BULLET_SPEED
	else:
		return -spawn_point.global_transform.basis.z * BULLET_SPEED

func _update_trajectory():
	if not spawn_point:
		return

	var start_pos = spawn_point.global_position
	var vel = _get_launch_velocity()
	var landed = false

	for i in range(TRAJ_STEPS):
		var t = (i + 1) * TRAJ_DT
		var pos = start_pos + vel * t + Vector3(0, -0.5 * BULLET_GRAVITY * t * t, 0)

		_preview_dots[i].visible = not landed
		_preview_dots[i].global_position = pos

		# Checar se atingiu o nível da água (~0.5)
		if pos.y < 0.5 and not landed:
			landed = true
			_landing_marker.global_position = Vector3(pos.x, 0.6, pos.z)
			_landing_marker.visible = true

	if not landed:
		_landing_marker.visible = false

func _hide_preview():
	for dot in _preview_dots:
		if is_instance_valid(dot):
			dot.visible = false
	if is_instance_valid(_landing_marker):
		_landing_marker.visible = false

func atirar():
	if not bullet_config or not player_referencia or not spawn_point:
		return

	if player_referencia.tem_municao():
		pode_atirar = false
		var nova_bala = bullet_config.instantiate()
		get_tree().root.add_child(nova_bala)
		nova_bala.global_transform = spawn_point.global_transform
		player_referencia.gastar_municao()

		get_tree().create_timer(cooldown_tiro).timeout.connect(func(): pode_atirar = true)

func assumir_controle(player):
	esta_operando = true
	player_referencia = player
	if "player_id" in player:
		player_id = player.player_id

func soltar_controle():
	esta_operando = false
	player_referencia = null
	_hide_preview()

func get_navio():
	var parent = get_parent()
	while parent:
		if parent is ShipBuoyancy:
			return parent
		parent = parent.get_parent()
	return null
