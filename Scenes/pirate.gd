extends CharacterBody3D

@export var SPEED : float = 5.0
@export var JUMP_VELOCITY : float = 4.5

const DEADZONE := 0.2

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var player_id := 0
var active := false
var _jump_requested := false

# --- Canhão / Navio ---
var usando_canhao = false
var navio_referencia = null
var objeto_interagido = null
var municao_player = 3
var max_municao = 3

# --- Recarga automática ---
var _recarga_timer: Timer

func _ready() -> void:
	# Identidade por nome do nó, sem depender de export/inspector
	player_id = 1 if name == "NodePirate2" else 0

	# Timer de recarga automática
	_recarga_timer = Timer.new()
	_recarga_timer.wait_time = 2.0
	_recarga_timer.one_shot = false
	_recarga_timer.timeout.connect(_recarregar_uma_bala)
	add_child(_recarga_timer)

func _input(event: InputEvent) -> void:
	if not active:
		return

	# --- Pulo separado por hardware ---
	if player_id == 0:
		if event is InputEventKey and event.physical_keycode == KEY_SPACE \
				and event.pressed and not event.echo:
			_jump_requested = true
	else:
		if event is InputEventJoypadButton and event.device == 0 \
				and event.button_index == JOY_BUTTON_A and event.pressed:
			_jump_requested = true

	# --- Interação com canhão (separada por hardware) ---
	if player_id == 0:
		if event is InputEventKey and event.physical_keycode == KEY_X \
				and event.pressed and not event.echo:
			_handle_interact()
	else:
		if event is InputEventJoypadButton and event.device == 0 and event.pressed:
			if event.button_index == JOY_BUTTON_X:
				_handle_interact()

func _handle_interact():
	if usando_canhao:
		sair_do_canhao()
	else:
		interagir_com_objetos()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if not active:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		return

	# Se usando canhão, não se move
	if usando_canhao:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# --- Pulo ---
	if _jump_requested and is_on_floor():
		velocity.y = JUMP_VELOCITY
	_jump_requested = false

	# --- Entrada de movimento lida direto do hardware ---
	var input_dir := _read_input()

	# --- Direção relativa à câmera ---
	# A câmera olha para baixo em direção a -X.
	# Screen "up" = world -X, Screen "right" = world -Z
	var direction := Vector3(input_dir.y, 0, -input_dir.x).normalized()

	if direction.length_squared() > 0.001:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_at(global_position + direction, Vector3.UP)
		rotation.x = 0.0
		rotation.z = 0.0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _read_input() -> Vector2:
	if player_id == 0:
		# Jogador 1: leitura direta de teclado (sem InputMap)
		var x := (1.0 if Input.is_key_pressed(KEY_D) else 0.0) \
			   - (1.0 if Input.is_key_pressed(KEY_A) else 0.0)
		var y := (1.0 if Input.is_key_pressed(KEY_S) else 0.0) \
			   - (1.0 if Input.is_key_pressed(KEY_W) else 0.0)
		return Vector2(x, y)
	else:
		# Jogador 2: leitura direta do joystick device 0 (sem InputMap)
		var v := Vector2(
			Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		)
		return v if v.length() > DEADZONE else Vector2.ZERO

# --- Interações com objetos ---
func interagir_com_objetos():
	var sensor = $AreaInteracao
	var areas = sensor.get_overlapping_areas()

	for area in areas:
		var alvo = encontrar_script_por_metodo(area, "assumir_controle")
		if alvo:
			if "esta_operando" in alvo and alvo.esta_operando:
				continue
				
			if alvo.has_method("get_navio"):
				navio_referencia = alvo.get_navio()

			alvo.assumir_controle(self)
			objeto_interagido = alvo
			usando_canhao = true
			return

func sair_do_canhao():
	usando_canhao = false
	navio_referencia = null

	if objeto_interagido:
		if objeto_interagido.has_method("soltar_controle"):
			objeto_interagido.soltar_controle()
		objeto_interagido = null

func encontrar_script_por_metodo(no_inicial, metodo):
	var atual = no_inicial
	while atual != null:
		if atual.has_method(metodo):
			return atual
		atual = atual.get_parent()
	return null

func tem_municao() -> bool:
	return municao_player > 0

func gastar_municao():
	if municao_player > 0:
		municao_player -= 1
		Manager.mudar_a_sprite.emit(municao_player)
		# Iniciar recarga automática se não estiver rodando
		if _recarga_timer and not _recarga_timer.is_stopped():
			pass  # Já está recarregando
		elif _recarga_timer:
			_recarga_timer.start()

func _recarregar_uma_bala():
	if municao_player < max_municao:
		municao_player += 1
		Manager.mudar_a_sprite.emit(municao_player)
		if municao_player >= max_municao:
			_recarga_timer.stop()
	else:
		_recarga_timer.stop()
