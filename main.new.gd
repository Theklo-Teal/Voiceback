extends Node

var rec_bus : int
var rec_fx : AudioEffectCapture
var rec_inst : AudioEffectSpectrumAnalyzerInstance
var ply_inst : AudioEffectSpectrumAnalyzerInstance

func _ready() -> void:
	rec_bus = AudioServer.get_bus_index("Record")
	rec_fx = AudioServer.get_bus_effect(rec_bus, 0)
	rec_inst = AudioServer.get_bus_effect_instance(rec_bus, 2) as AudioEffectSpectrumAnalyzerInstance
	ply_inst = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("Master"), 0) as AudioEffectSpectrumAnalyzerInstance
	G.setup(self)


var rec_start : float
var maxim_start : float
func _process(_delta: float) -> void:
	const FREQ_MAX = 11050
	const MIN_DB = 60
	var aud_energy
	if G.mode == G.IS.RCRD:
		aud_energy = rec_inst.get_magnitude_for_frequency_range(20, FREQ_MAX, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX)
		#G.leng = maxim_start + (Time.get_ticks_msec() - rec_start) / 1000
	elif G.mode == G.IS.PLAY:
		aud_energy = ply_inst.get_magnitude_for_frequency_range(20, FREQ_MAX, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX)
		#G.curr = %Player.get_playback_position()
	if G.mode != G.IS.IDLE:
		aud_energy = max(aud_energy.x, aud_energy.y)
		aud_energy = (MIN_DB + linear_to_db(aud_energy)) / MIN_DB
		aud_energy = inverse_lerp(0, 100, aud_energy * 10000) - 10
		%VU_Meter.value = aud_energy


func go_idle():
	%VU_Meter.value = 0
	if G.mode == G.IS.RCRD:
		var new_rec = rec_fx.get_buffer(rec_fx.get_frames_available())
		%Microphone.stop()
		print(new_rec)
		#%Player.stream = convert_wav(new_rec)
	elif %Player.playing:
		%Player.stop()

func go_play():
	if %Player.stream != null:
		%Player.play()
		%VU_Left.modulate = Color.GREEN
	else:
		%VU_Left.modulate = Color.RED

func go_record():
	rec_fx.clear_buffer()
	%Microphone.play()
	rec_start = Time.get_ticks_msec()
	maxim_start = G.leng


func _on_player_finished() -> void:
	G.mode = G.IS.IDLE
	%Player.seek(G.leng)

func _on_end_pressed() -> void:
	%Player.seek(G.leng)
func _on_home_pressed() -> void:
	%Player.seek(0)


func splice_rec(new_rec:PackedVector2Array):
	return new_rec
	#var new_data : PackedByteArray
	#var old_rec = G.active_audio
	#
	#var old_duration = old_rec.get_length()
	#var old_size = old_rec.data.size()
	#var new_size = new_rec.data.size()
	#
	#var pos_start = remap(G.curr, 0, old_duration, 0, old_size)
	#var pos_resume = pos_start + new_size
	#
	#new_data = old_rec.data.slice(0, pos_start)
	#new_data += new_rec.data
	#if pos_resume < old_size:
		#new_data += old_rec.data.slice(pos_resume)
	#
	#return new_data

func convert_wav(buffer:PackedVector2Array) -> AudioStreamWAV:
	var post_buffer : PackedByteArray
	for sample in buffer:
		var mono = (sample.x + sample.y) / 2 
		post_buffer.append( 0x7fff * mono as int )
	return AudioStreamWAV.load_from_buffer(post_buffer)

func convert_pcm(wav:PackedByteArray) -> PackedVector2Array:
	return []

func _on_new_file_pressed() -> void:
	G.create_new_recording()
