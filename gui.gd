extends Node2D

# Pegando as referências das balas (ajustado para o seu caminho da imagem)
@onready var Bala1 = get_node_or_null("GuiMuniçao/container_balas/Bala1")
@onready var Bala2 = get_node_or_null("GuiMuniçao/container_balas/Bala2")
@onready var Bala3 = get_node_or_null("GuiMuniçao/container_balas/Bala3")

func _ready() -> void:
	# Conecta ao seu sinal global
	Manager.mudar_a_sprite.connect(mudar_sprite)

func mudar_sprite(quantidade_balas):
	# Verificação de segurança para não dar erro de 'null instance'
	if Bala1 == null or Bala2 == null or Bala3 == null:
		return

	#opacidade (Alpha)
	var visivel = 1.0
	var transparente = 0.2
	
	# Se a quantidade de balas for maior ou igual ao número do slot, 
	# a bala fica visível (1.0). Caso contrário, fica transparente (0.2).
	
	Bala1.modulate.a = visivel if quantidade_balas >= 1 else transparente
	Bala2.modulate.a = visivel if quantidade_balas >= 2 else transparente
	Bala3.modulate.a = visivel if quantidade_balas >= 3 else transparente
	

	print("balas visíveis.")
