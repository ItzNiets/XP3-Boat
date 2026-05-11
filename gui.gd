extends Node2D

# Pegando as referências das balas
@onready var Bala1 = get_node_or_null("GuiMuniçao/container_balas/Bala1")
@onready var Bala2 = get_node_or_null("GuiMuniçao/container_balas/Bala2")
@onready var Bala3 = get_node_or_null("GuiMuniçao/container_balas/Bala3")

# Labels criados em runtime
var _onda_label: Label
var _vida_label: Label
var _pontos_label: Label
var _resultado_label: Label
var _aviso_onda_label: Label
var _canvas: CanvasLayer

func _ready() -> void:
	Manager.mudar_a_sprite.connect(mudar_sprite)
	_create_phase_ui()
	Manager.onda_iniciada.connect(_on_onda_iniciada)
	Manager.fase_terminada.connect(_on_fase_terminada)
	Manager.vida_navio_mudou.connect(_on_vida_mudou)
	Manager.inimigo_morreu.connect(_on_inimigo_morreu)

func _create_phase_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 10
	add_child(_canvas)

	# --- ONDA (canto superior direito) ---
	_onda_label = Label.new()
	_onda_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_onda_label.position = Vector2(-250, 10)
	_onda_label.custom_minimum_size = Vector2(240, 30)
	_onda_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_onda_label.add_theme_font_size_override("font_size", 20)
	_onda_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	_onda_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_onda_label.add_theme_constant_override("shadow_offset_x", 2)
	_onda_label.add_theme_constant_override("shadow_offset_y", 2)
	_onda_label.text = ""
	_onda_label.visible = false
	_canvas.add_child(_onda_label)

	# --- VIDA DO NAVIO (canto superior esquerdo) ---
	_vida_label = Label.new()
	_vida_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_vida_label.position = Vector2(20, 10)
	_vida_label.add_theme_font_size_override("font_size", 22)
	_vida_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	_vida_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_vida_label.add_theme_constant_override("shadow_offset_x", 2)
	_vida_label.add_theme_constant_override("shadow_offset_y", 2)
	_vida_label.text = ""
	_vida_label.visible = false
	_canvas.add_child(_vida_label)

	# --- PONTUAÇÃO (centro-superior) ---
	_pontos_label = Label.new()
	_pontos_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_pontos_label.position = Vector2(-100, 10)
	_pontos_label.custom_minimum_size = Vector2(200, 30)
	_pontos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pontos_label.add_theme_font_size_override("font_size", 24)
	_pontos_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_pontos_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_pontos_label.add_theme_constant_override("shadow_offset_x", 2)
	_pontos_label.add_theme_constant_override("shadow_offset_y", 2)
	_pontos_label.text = "0"
	_pontos_label.visible = false
	_canvas.add_child(_pontos_label)

	# --- AVISO DE ONDA (centro, temporário) ---
	_aviso_onda_label = Label.new()
	_aviso_onda_label.set_anchors_preset(Control.PRESET_CENTER)
	_aviso_onda_label.position = Vector2(-250, -80)
	_aviso_onda_label.custom_minimum_size = Vector2(500, 80)
	_aviso_onda_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_onda_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_aviso_onda_label.add_theme_font_size_override("font_size", 52)
	_aviso_onda_label.add_theme_color_override("font_color", Color(1, 0.8, 0.1, 1))
	_aviso_onda_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_aviso_onda_label.add_theme_constant_override("shadow_offset_x", 3)
	_aviso_onda_label.add_theme_constant_override("shadow_offset_y", 3)
	_aviso_onda_label.text = ""
	_aviso_onda_label.visible = false
	_canvas.add_child(_aviso_onda_label)

	# --- RESULTADO FINAL (centro) ---
	_resultado_label = Label.new()
	_resultado_label.set_anchors_preset(Control.PRESET_CENTER)
	_resultado_label.position = Vector2(-300, -60)
	_resultado_label.custom_minimum_size = Vector2(600, 120)
	_resultado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resultado_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_resultado_label.add_theme_font_size_override("font_size", 56)
	_resultado_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_resultado_label.add_theme_constant_override("shadow_offset_x", 3)
	_resultado_label.add_theme_constant_override("shadow_offset_y", 3)
	_resultado_label.text = ""
	_resultado_label.visible = false
	_canvas.add_child(_resultado_label)

func mudar_sprite(quantidade_balas):
	if Bala1 == null or Bala2 == null or Bala3 == null:
		return

	var visivel = 1.0
	var transparente = 0.2

	Bala1.modulate.a = visivel if quantidade_balas >= 1 else transparente
	Bala2.modulate.a = visivel if quantidade_balas >= 2 else transparente
	Bala3.modulate.a = visivel if quantidade_balas >= 3 else transparente

func _on_onda_iniciada(numero: int) -> void:
	_onda_label.visible = true
	_vida_label.visible = true
	_pontos_label.visible = true

	# Atualizar labels fixos
	_onda_label.text = "ONDA " + str(numero)
	_vida_label.text = "♥ 100"
	_pontos_label.text = str(Manager.pontuacao)

	# Mostrar aviso grande no centro
	_aviso_onda_label.visible = true
	if numero == 1:
		_aviso_onda_label.text = "ONDA 1 - PREPARE-SE!"
	else:
		_aviso_onda_label.text = "ONDA " + str(numero) + "!"
		# Mudar cor a cada 5 ondas
		if numero % 5 == 0:
			_aviso_onda_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
			_aviso_onda_label.text = "⚠ ONDA " + str(numero) + " ⚠"
		else:
			_aviso_onda_label.add_theme_color_override("font_color", Color(1, 0.8, 0.1, 1))

	# Esconder aviso após 2.5s
	get_tree().create_timer(2.5).timeout.connect(func():
		if is_instance_valid(_aviso_onda_label):
			_aviso_onda_label.visible = false
	)

func _on_vida_mudou(vida_atual: int, vida_max: int) -> void:
	if is_instance_valid(_vida_label):
		_vida_label.text = "♥ " + str(vida_atual)
		# Mudar cor conforme vida
		var ratio = float(vida_atual) / float(vida_max)
		if ratio <= 0.25:
			_vida_label.add_theme_color_override("font_color", Color(1, 0, 0, 1))
		elif ratio <= 0.5:
			_vida_label.add_theme_color_override("font_color", Color(1, 0.5, 0, 1))
		else:
			_vida_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))

func _on_inimigo_morreu() -> void:
	# Atualizar onda e pontuação
	if is_instance_valid(_onda_label) and Manager.fase_ativa:
		_onda_label.text = "ONDA " + str(Manager.onda_atual) \
			+ "  " + str(Manager.inimigos_mortos_onda) + "/" + str(Manager.inimigos_na_onda)
	if is_instance_valid(_pontos_label):
		_pontos_label.text = str(Manager.pontuacao)

func _on_fase_terminada(_vitoria: bool) -> void:
	if is_instance_valid(_resultado_label):
		_resultado_label.visible = true
		_resultado_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
		_resultado_label.add_theme_font_size_override("font_size", 48)
		_resultado_label.text = "GAME OVER\nOnda: " + str(Manager.onda_atual) \
			+ " | Pontos: " + str(Manager.pontuacao)

