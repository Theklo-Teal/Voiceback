extends Node

var main : Node

#region Audio Handling
enum IS{
	IDLE,
	PLAY,
	RCRD,
}
var mode : IS = IS.IDLE :
	set(val):
		match val:
			IS.IDLE:
				main.get_node("%End").disabled = false
				main.get_node("%Home").disabled = false
				main.get_node("%VU_Left").hide()
				main.get_node("%VU_Right").hide()
				main.get_node("%VU_Meter/Label").text = "Record <<[Paused]>> Play"
				main.go_idle()
			IS.PLAY:
				main.get_node("%End").disabled = true
				main.get_node("%VU_Left").show()
				main.get_node("%VU_Meter").fill_mode = ProgressBar.FILL_END_TO_BEGIN
				main.get_node("%VU_Meter/Label").text = "Pause <<[Playing]"
				main.go_play()
			IS.RCRD:
				main.get_node("%End").disabled = true
				main.get_node("%Home").disabled = true
				main.get_node("%Seek").reset_chevron()
				main.get_node("%VU_Right").show()
				main.get_node("%VU_Meter").fill_mode = ProgressBar.FILL_BEGIN_TO_END
				main.get_node("%VU_Meter/Label").text = "[Recording]>> Stop"
				main.go_record()
		mode = val
		main.get_node("%Seek").queue_redraw()

var leng : float = 0 :
	set(val):
		leng = max(val, 0)
		main.get_node("%End").text = get_time_string(leng)
		curr = curr

var curr : float = 0 :
	set(val):
		curr = clamp(val, 0, leng)
		main.get_node("%Home").text = get_time_string(curr)
		main.get_node("%Seek").queue_redraw()


func get_time_string(val:float) -> String:
	var parts = Time.get_time_dict_from_unix_time(round(val))
	if parts.hour > 0:
		return str(parts.hour).pad_zeros(2) + ":" + str(parts.minute).pad_zeros(2) + ":" + str(parts.second).pad_zeros(2)
	else:
		var msec = fmod(val, 1.0) * 100
		msec = roundi(msec)
		return str(parts.hour).pad_zeros(2) + ":" + str(parts.second).pad_zeros(2) + "." + str(msec).pad_zeros(2)
#endregion


#region Note Handling
var notes : Array[float]
#endregion


#region File Handling
@export_storage var active_file : String
var active_audio : PackedByteArray
var files : Array[Dictionary]

func setup(who:Node) -> void:
	main = who
	
	var rec_dir = "res://Records/"
	if OS.has_feature("android"):
		rec_dir = "user://"
	
	for each in DirAccess.get_files_at(rec_dir):
		if each.get_extension() == "cfg":
			var conf = ConfigFile.new()
			conf.load(rec_dir + each)
			var data = {
				"path": rec_dir + each.get_basename() + ".wav",
				"created": conf.get_value("Metadata", "created", Time.get_unix_time_from_system()),
				"modified": conf.get_value("Metadata", "modified", Time.get_unix_time_from_system()),
				}
			if FileAccess.file_exists(data.path):
				files.append(data)
			else:
				DirAccess.remove_absolute(rec_dir + each)
	
	files.sort_custom(func(a, b):
		return a.created > b.created
		)
	
	for n in range(files.size()):
		var entry = preload("res://audio_entry.tscn").instantiate()
		entry.set_track(n)
		main.get_node("%Track_List").add_child(entry)
	
	#if files.is_empty():
	#	main.get_node("%Player").stream = AudioStreamWAV.new()
	#	create_new_recording()
	#if active_file.is_empty():
	#	active_file = files.back()

func load_active_file(fl_path : String = ""):
	if not fl_path.is_empty():
		active_file = fl_path
	main.get_node("%Player").stream = AudioStreamWAV.load_from_file(fl_path)
	leng = main.get_node("%Player").stream.get_length()

func create_new_recording():
	if main.get_node("%Player").stream != null:
		var fl_path : String = main.get_node("%Filename").validate_filename()
		main.get_node("%Filename").text = fl_path
		main.get_node("%Player").stream.save_to_wav(fl_path + ".wav")

func rename_recording():
	pass
#endregion
