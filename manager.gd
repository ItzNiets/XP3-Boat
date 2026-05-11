extends Node

signal mudar_a_sprite(numero_balas)
signal fase_iniciada
signal fase_terminada(vitoria: bool)
signal onda_iniciada(numero: int)
signal inimigo_morreu
signal vida_navio_mudou(vida_atual: int, vida_max: int)

# Referências aos piratas
var p1_node = null
var p2_node = null

# Controla se cada jogador já entrou
var p1_joined := false
var p2_joined := false

# --- Sistema de Fase (Ondas Infinitas) ---
var fase_ativa := false
var onda_atual := 0
var inimigos_na_onda := 0
var inimigos_mortos_onda := 0
var entre_ondas := false

# Dificuldade escalante
var inimigos_base := 3
var incremento_por_onda := 2
var max_inimigos_onda := 30

# Pontuação
var pontuacao := 0

var lobby_label: Label

# --- Pause ---
var _pause_canvas: CanvasLayer
var _pause_panel: Control
var _pause_selection := 0  # 0 = Continuar, 1 = Reiniciar, 2 = Menu
var _pause_labels: Array[Label] = []
var _jogo_acabou := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Manager funciona mesmo pausado
	_setup_inputs()
	_reset_state()
	call_deferred("_find_pirates")
	call_deferred("_create_lobby_ui")
	call_deferred("_create_pause_menu")

func _reset_state():
	p1_node = null
	p2_node = null
	p1_joined = false
	p2_joined = false
	fase_ativa = false
	onda_atual = 0
	inimigos_na_onda = 0
	inimigos_mortos_onda = 0
	entre_ondas = false
	pontuacao = 0
	_jogo_acabou = false
	_pause_selection = 0

func _setup_inputs() -> void:
	var defs = [
		["p1_up",   true,  KEY_W,    -1, -1,   0.0 ],
		["p1_down", true,  KEY_S,    -1, -1,   0.0 ],
		["p1_left", true,  KEY_A,    -1, -1,   0.0 ],
		["p1_right",true,  KEY_D,    -1, -1,   0.0 ],
		["p1_jump", true,  KEY_SPACE,-1, -1,   0.0 ],
		["p2_up",   false, -1,        0, JOY_AXIS_LEFT_Y, -1.0],
		["p2_down", false, -1,        0, JOY_AXIS_LEFT_Y,  1.0],
		["p2_left", false, -1,        0, JOY_AXIS_LEFT_X, -1.0],
		["p2_right",false, -1,        0, JOY_AXIS_LEFT_X,  1.0],
		["p2_jump", false, -1,        0, -1,   0.0 ],
	]
	for d in defs:
		var action = d[0]
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action)
		if d[1]:
			var ev = InputEventKey.new()
			ev.physical_keycode = d[2]
			InputMap.action_add_event(action, ev)
		else:
			if d[4] != -1:
				var ev = InputEventJoypadMotion.new()
				ev.device = d[3]
				ev.axis = d[4]
				ev.axis_value = d[5]
				InputMap.action_add_event(action, ev)
			else:
				var ev = InputEventJoypadButton.new()
				ev.device = d[3]
				ev.button_index = JOY_BUTTON_A
				InputMap.action_add_event(action, ev)

func _find_pirates() -> void:
	_search(get_tree().root)

func _search(node: Node) -> void:
	if node.name == "NodePirate" and "active" in node:
		p1_node = node
	elif node.name == "NodePirate2" and "active" in node:
		p2_node = node
	for c in node.get_children():
		_search(c)

func _create_lobby_ui() -> void:
	# Limpar lobby anterior se existir
	var old = get_node_or_null("LobbyCanvas")
	if old:
		old.queue_free()

	var canvas = CanvasLayer.new()
	canvas.name = "LobbyCanvas"
	add_child(canvas)
	lobby_label = Label.new()
	lobby_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lobby_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby_label.add_theme_font_size_override("font_size", 22)
	lobby_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))
	lobby_label.text = "Jogador 1: Aperte ESPACO   |   Jogador 2: Aperte A no Controle"
	canvas.add_child(lobby_label)

# --- Pause Menu ---

func _create_pause_menu() -> void:
	var old = get_node_or_null("PauseCanvas")
	if old:
		old.queue_free()

	_pause_canvas = CanvasLayer.new()
	_pause_canvas.name = "PauseCanvas"
	_pause_canvas.layer = 100
	_pause_canvas.visible = false
	_pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_canvas)

	# Fundo escuro
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.6)
	_pause_canvas.add_child(bg)

	# Painel central
	_pause_panel = VBoxContainer.new()
	_pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	_pause_panel.position = Vector2(-150, -120)
	_pause_panel.custom_minimum_size = Vector2(300, 240)
	_pause_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_pause_canvas.add_child(_pause_panel)

	# Título
	var titulo = Label.new()
	titulo.text = "PAUSADO"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 42)
	titulo.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	titulo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	titulo.add_theme_constant_override("shadow_offset_x", 2)
	titulo.add_theme_constant_override("shadow_offset_y", 2)
	_pause_panel.add_child(titulo)

	# Espaço
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	_pause_panel.add_child(spacer)

	# Opções
	_pause_labels.clear()
	var opcoes = ["▶  Continuar", "✕  Sair do Jogo"]
	for i in range(opcoes.size()):
		var lbl = Label.new()
		lbl.text = opcoes[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 26)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		_pause_panel.add_child(lbl)
		_pause_labels.append(lbl)

	_update_pause_selection()

func _update_pause_selection():
	for i in range(_pause_labels.size()):
		if i == _pause_selection:
			_pause_labels[i].add_theme_color_override("font_color", Color(1, 1, 0.3, 1))
		else:
			_pause_labels[i].add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 0.8))

func _toggle_pause():
	if _jogo_acabou:
		return
	var is_paused = get_tree().paused
	get_tree().paused = not is_paused
	_pause_canvas.visible = not is_paused
	_pause_selection = 0
	_update_pause_selection()

func _confirm_pause_option():
	match _pause_selection:
		0:  # Continuar
			_toggle_pause()
		1:  # Sair do Jogo
			get_tree().quit()

# --- Input ---

func _input(event: InputEvent) -> void:
	# --- PAUSE: ESC ou Start ---
	if event.is_pressed() and not event.is_echo():
		var is_pause_key = (event is InputEventKey and event.keycode == KEY_ESCAPE)
		var is_pause_btn = (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START)

		if is_pause_key or is_pause_btn:
			if get_tree().paused:
				_toggle_pause()  # Despausar
			elif not _jogo_acabou:
				_toggle_pause()  # Pausar
			return

	# --- Navegação do menu de pause ---
	if get_tree().paused and _pause_canvas.visible:
		if event.is_pressed() and not event.is_echo():
			# Cima
			var up = (event is InputEventKey and event.keycode == KEY_UP) \
				or (event is InputEventKey and event.keycode == KEY_W) \
				or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_DPAD_UP)
			# Baixo
			var down = (event is InputEventKey and event.keycode == KEY_DOWN) \
				or (event is InputEventKey and event.keycode == KEY_S) \
				or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_DPAD_DOWN)
			# Confirmar
			var confirm = (event is InputEventKey and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)) \
				or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A)

			if up:
				_pause_selection = max(0, _pause_selection - 1)
				_update_pause_selection()
			elif down:
				_pause_selection = min(_pause_labels.size() - 1, _pause_selection + 1)
				_update_pause_selection()
			elif confirm:
				_confirm_pause_option()
		return  # Não processar outros inputs enquanto pausado



	# --- Lobby: jogadores entram ---
	var current_scene = get_tree().current_scene
	if not current_scene or current_scene.name != "World":
		return

	if not p1_joined and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			p1_joined = true
			if p1_node:
				p1_node.active = true
			_update_lobby_label()

	if not p2_joined and event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_A and event.device == 0:
			p2_joined = true
			if p2_node:
				p2_node.active = true
			_update_lobby_label()

func _update_lobby_label() -> void:
	if p1_joined and p2_joined:
		lobby_label.text = "PARTIDA INICIADA!"
		get_tree().create_timer(3.0).timeout.connect(_iniciar_fase)
		get_tree().create_timer(2.0).timeout.connect(func(): if is_instance_valid(lobby_label): lobby_label.hide())
	elif p1_joined:
		lobby_label.text = "Jogador 1 conectado!   |   Jogador 2: Aperte A no Controle"
	elif p2_joined:
		lobby_label.text = "Jogador 2 conectado!   |   Jogador 1: Aperte ESPACO"

# --- Sistema de Fase (Infinito) ---

func _iniciar_fase() -> void:
	if fase_ativa:
		return
	fase_ativa = true
	onda_atual = 0
	pontuacao = 0
	fase_iniciada.emit()
	_proxima_onda()

func _calcular_inimigos_onda(onda: int) -> int:
	var qtd = inimigos_base + (onda - 1) * incremento_por_onda
	return mini(qtd, max_inimigos_onda)

func _proxima_onda() -> void:
	if not fase_ativa:
		return

	entre_ondas = true
	onda_atual += 1
	inimigos_na_onda = _calcular_inimigos_onda(onda_atual)
	inimigos_mortos_onda = 0

	print("=== ONDA ", onda_atual, " — ", inimigos_na_onda, " inimigos ===")
	onda_iniciada.emit(onda_atual)
	entre_ondas = false

func registrar_morte_inimigo() -> void:
	inimigos_mortos_onda += 1
	pontuacao += 10 * onda_atual
	inimigo_morreu.emit()

	if inimigos_mortos_onda >= inimigos_na_onda:
		var pausa = maxf(3.0, 6.0 - onda_atual * 0.3)
		get_tree().create_timer(pausa).timeout.connect(_proxima_onda)

func navio_destruido() -> void:
	if fase_ativa:
		_fim_de_fase()

func _fim_de_fase() -> void:
	fase_ativa = false
	_jogo_acabou = true
	fase_terminada.emit(false)
	print("=== FIM DE JOGO! Onda: ", onda_atual, " | Pontuação: ", pontuacao, " ===")
	
	# Recarregar cena após delay
	get_tree().create_timer(6.0).timeout.connect(func():
		get_tree().reload_current_scene()
	)
