@tool
extends Listener


var current_fs_profile: Dictionary = {}
var previous_fs_profile: Dictionary = {}

var forbidden_dirs = ["res://.godot", "res://.gitattributes", "res://.gitignore"]
var forbidden_extensions = ["godot", "import"]

# Signal signatures
signal resource_created(curr_file_path: String, resource: Resource)
signal resource_deleted(curr_file_path: String, resource: Resource)
signal resource_changed(prev_file_path: String)


func begin():
	
	update_fs_profile()
	
	is_listening = true


func end():
	
	is_listening = false


func get_listener_name() -> String:
	
	return "File System Listener"


func get_listener_signals() -> Array[Signal]:
	
	var signals: Array[Signal] = [
		resource_changed,
		resource_created,
		resource_deleted
	]
	
	return signals


func update():
	
	if !is_listening: return
	
	update_fs_profile()
	diff_fs()


func update_fs_profile():
	
	previous_fs_profile.clear()
	previous_fs_profile = current_fs_profile.duplicate(true)
	
	current_fs_profile.clear()
	
	update_current_fs("res://")


func update_current_fs(dir: String):
	
	var da: DirAccess = DirAccess.open(dir)
	
	if da:
		
		da.list_dir_begin()
		
		var file_name = da.get_next()
		
		while file_name != "":
			
			var file_path
			
			if dir == "res://": 
				file_path = dir + file_name
			else:
				file_path = dir + "/" + file_name
			
			if da.dir_exists_absolute(file_path) && !forbidden_dirs.has(file_path):
				update_current_fs(file_path)
			
			if file_path.get_extension() != "" && !forbidden_extensions.has(file_path.get_extension()):
				current_fs_profile[file_path] = {
					"md5": FileAccess.get_md5(file_path),
					"modified_time": FileAccess.get_modified_time(file_path)
				}
			
			file_name = da.get_next()


func diff_fs():
	
	for curr_file_path in current_fs_profile:
		
		var curr_file_data = current_fs_profile[curr_file_path]
		
		if !previous_fs_profile.has(curr_file_path):
			
			var resource: Resource = ResourceLoader.load(curr_file_path)
			emit_signal("resource_created", [curr_file_path, resource])
		
		else:
			
			var prev_file_data = previous_fs_profile[curr_file_path]
			
			if curr_file_data.modified_time != prev_file_data.modified_time:
				
				var resource: Resource = ResourceLoader.load(curr_file_path)
				emit_signal("resource_changed", [curr_file_path, resource])
	
	for prev_file_path in previous_fs_profile:
		
		var file_data = previous_fs_profile[prev_file_path]
		
		if !current_fs_profile.has(prev_file_path):
			
			emit_signal("resource_deleted", [prev_file_path]) 
	
	



