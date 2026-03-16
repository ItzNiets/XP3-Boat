extends Node
class_name AmbientAudio

## ─── Inspector Tuning ────────────────────────────────────
## Base volume for the waves/ocean layer (dB)
@export_range(-40.0, 0.0) var base_volume_waves: float = -12.0
## Base volume for the wind layer (dB)
@export_range(-40.0, 0.0) var base_volume_wind: float = -16.0
## Maximum modulation swing per layer (dB). ±this value.
@export_range(0.0, 10.0) var modulation_depth_db: float = 3.0
## Modulation speed multiplier (lower = slower breathing)
@export_range(0.1, 3.0) var modulation_speed: float = 1.0

## ─── Internal ────────────────────────────────────────────
var _time: float = 0.0

# Irrational frequency multipliers – overlapping sines that never exactly repeat
const _FREQ_WAVES: Array[float] = [0.047, 0.031, 0.019, 0.0073]
const _FREQ_WIND:  Array[float] = [0.041, 0.027, 0.013, 0.0059]

# Phase offsets so the two layers don't start in sync
const _PHASE_WAVES: Array[float] = [0.0, 1.23, 2.87, 4.56]
const _PHASE_WIND:  Array[float] = [0.71, 3.14, 5.02, 0.39]

@onready var _waves_player: AudioStreamPlayer = $WavesPlayer
@onready var _wind_player: AudioStreamPlayer = $WindPlayer


func _ready() -> void:
	# Randomise start time so each play-through feels different
	_time = randf_range(0.0, 200.0)

	_setup_player(_waves_player, base_volume_waves)
	_setup_player(_wind_player, base_volume_wind)


func _setup_player(player: AudioStreamPlayer, vol_db: float) -> void:
	if not player or not player.stream:
		push_warning("[AmbientAudio] Player or stream missing: %s" % str(player))
		return
	player.volume_db = vol_db
	# Ensure the stream is set to loop (works for mp3 / ogg)
	var stream = player.stream
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	player.play()


func _process(delta: float) -> void:
	_time += delta * modulation_speed

	if _waves_player and _waves_player.playing:
		_waves_player.volume_db = base_volume_waves + _multi_sine(_time, _FREQ_WAVES, _PHASE_WAVES)
	if _wind_player and _wind_player.playing:
		_wind_player.volume_db = base_volume_wind  + _multi_sine(_time, _FREQ_WIND,  _PHASE_WIND)


## Returns a value in [-modulation_depth_db, +modulation_depth_db] using
## overlapping sine waves at irrational frequency ratios.
func _multi_sine(t: float, freqs: Array[float], phases: Array[float]) -> float:
	var total := 0.0
	for i in range(freqs.size()):
		total += sin(TAU * freqs[i] * t + phases[i])
	# Normalize to [-1, 1] then scale to depth
	total /= float(freqs.size())
	return total * modulation_depth_db
