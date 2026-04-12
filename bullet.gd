extends CharacterBody3D

@export var speed = 20.0 

func _physics_process(_delta):
	# Define a velocidade baseada na direção frontal (Z negativo)
	var direction = -global_transform.basis.z
	velocity = direction * speed
	
	move_and_slide()
	
	#Verifica se houve colisão após o movimento
	if get_slide_collision_count() > 0:
		# Pega a primeira colisão do frame
		var col = get_slide_collision(0)
		var body = col.get_collider()
		
		
		if body.has_method("levar_dano"):
			body.levar_dano(1)
			print("Bala: Acertei um inimigo!")
		else:
			print("Bala: Bati em algo sem vida.")
			
		
		queue_free()
