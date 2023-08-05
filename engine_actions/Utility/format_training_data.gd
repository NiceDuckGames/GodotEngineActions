@tool
extends Node

## TO USE: Open the .tscn file with the same name, 
##         and click the "Activate" boolean to format
##         and export the training data.

@export var activate: bool = false:
	set = set_activate, get = get_activate

@export var templates_file_path: String = ""
@export var new_file_name: String = ""


func get_activate():
	return activate

func set_activate(value: bool):
	format_action_templates()


func format_action_templates():
	
	if templates_file_path.length() == 0: printerr("You must provide a path to the templates.")
	if new_file_name.length() == 0: printerr("You must provide a path to the new file.")
	
	var fa: FileAccess = FileAccess.open(new_file_name, FileAccess.WRITE)
	
	if !fa: printerr("Failed to access file.")
	
	var templates = EngineActionDB.templates.duplicate(true)
	
	for action_name in templates:
		
		var line_dict: Dictionary = {
			"prompt": action_name,
			"response": templates[action_name]
		}
		
		var line_string: String = GDVN.stringify(line_dict, "")
		
		fa.store_line(line_string)
	
