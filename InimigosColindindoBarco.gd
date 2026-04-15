extends StaticBody3D

func receber_dano_navio(valor: int):
	# get_owner() encontra o nó raiz da cena onde este script está salvo
	var navio = get_owner()
	
	if navio and navio.has_method("receber_dano_navio"):
		navio.receber_dano_navio(valor)
	else:
		# DEBUG: Isso vai te dizer exatamente quem o Godot está achando que é o dono
		print("Dono da cena: ", navio.name if navio else "Nenhum")
		print("Erro: Método 'receber_dano_navio' não encontrado em: ", navio.name if navio else "Raiz")
