extends CharacterBody3D

@export var speed = 25.0
@export var gravidade = 14.0

var _vel := Vector3.ZERO
var _initialized := false
var _tempo_vida := 0.0

func _ready():
	collision_layer = 4
	collision_mask = 2

func _physics_process(delta):
	# Capturar direção no primeiro frame (lado B = +Z)
	if not _initialized:
		_vel = global_transform.basis.z * speed
		_initialized = true

	_vel.y -= gravidade * delta
	velocity = _vel

	move_and_slide()

	_tempo_vida += delta
	if global_position.y < -5.0 or _tempo_vida > 8.0:
		queue_free()
		return

	if get_slide_collision_count() > 0:
		var col = get_slide_collision(0)
		var body = col.get_collider()

		if body.has_method("levar_dano"):
			body.levar_dano(1)
		elif body.get_parent() and body.get_parent().has_method("levar_dano"):
			body.get_parent().levar_dano(1)

		queue_free()
