extends Node

var player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var cache: Dictionary = {}
var current_world := -1

func _ready() -> void:
	player = AudioStreamPlayer.new()
	music_player = AudioStreamPlayer.new()
	add_child(player)
	add_child(music_player)
	player.volume_db = -8.0
	music_player.volume_db = -19.0

func tone(name: String) -> void:
	if not Save.data.get("sfx", true):
		return
	if not cache.has(name):
		var specs := {"tap": [560.0, 0.08], "turn": [390.0, 0.17], "crystal": [840.0, 0.19], "hurt": [190.0, 0.25], "win": [660.0, 0.52], "buy": [700.0, 0.32], "near": [960.0, 0.12], "spring": [470.0, 0.24]}
		var spec: Array = specs.get(name, [500.0, 0.1])
		cache[name] = make_wave(float(spec[0]), float(spec[1]), false, 0)
	player.stream = cache[name]
	player.play()

func music(world: int) -> void:
	if not Save.data.get("music", true):
		music_player.stop()
		return
	if world == current_world and music_player.playing:
		return
	current_world = world
	var key := "music_%d" % world
	if not cache.has(key):
		cache[key] = make_wave(220.0, 8.0, true, world)
	music_player.stream = cache[key]
	music_player.play()

func make_wave(frequency: float, length: float, loop: bool, world: int) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * length)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var melody := [0, 4, 7, 12, 7, 4, 2, 7]
	for i in count:
		var t := float(i) / rate
		var sample: float
		if loop:
			var beat := int(t * 2.0) % melody.size()
			var note: int = melody[(beat + world * 2) % melody.size()]
			var f := frequency * pow(2.0, float(note) / 12.0)
			var envelope := 0.45 + 0.55 * exp(-fmod(t * 2.0, 1.0) * 4.0)
			sample = (sin(TAU * f * t) * 0.32 + sin(TAU * f * 0.5 * t) * 0.18) * envelope
		else:
			var env := pow(1.0 - t / length, 2.0)
			sample = (sin(TAU * (frequency + 90.0 * t / length) * t) + 0.25 * sin(TAU * frequency * 2.0 * t)) * env * 0.38
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = value & 255
		bytes[i * 2 + 1] = (value >> 8) & 255
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = count
	return wav
