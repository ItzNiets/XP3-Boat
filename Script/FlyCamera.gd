extends Camera3D

## Movement speed
@export var move_speed: float = 20.0
## Fast movement speed (holding Shift)
@export var fast_speed: float = 60.0
## Mouse sensitivity
@export var mouse_sensitivity: float = 0.002

var _yaw: float = 0.0
var _pitch: float = 0.0
var _captured := false

func _ready() -> void:
	# Start with mouse captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_captured = true
	# Initialize rotation from current transform
	_yaw = rotation.y
	_pitch = rotation.x

func _unhandled_input(event: InputEvent) -> void:
	# Toggle mouse capture with Escape
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if _captured:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				_captured = false
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				_captured = true
	
	# Mouse look
	if event is InputEventMouseMotion and _captured:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, -PI * 0.49, PI * 0.49)

func _process(delta: float) -> void:
	if not _captured:
		return
	
	# Apply rotation
	rotation = Vector3(_pitch, _yaw, 0)
	
	# Movement direction
	var input_dir := Vector3.ZERO
	
	if Input.is_key_pressed(KEY_W):
		input_dir.z -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.z += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_CTRL):
		input_dir.y -= 1
	
	input_dir = input_dir.normalized()
	
	# Speed
	var speed := fast_speed if Input.is_key_pressed(KEY_SHIFT) else move_speed
	
	# Move in local space
	var move := global_transform.basis * input_dir * speed * delta
	global_position += move
