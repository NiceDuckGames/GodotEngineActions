@tool
extends Node

## EngineActionDB handles the loading and saving
## of action templates created by the user, and provides
## some access functions to fetch information about them.

## File path to the .json file that stores action templates.
var templates_path: String = "res://addons/engine_actions/Actions/action_templates.json"
## Cached template data that has been loaded from disk.
var templates: Dictionary = {}

## Emitted when the action templates are finished loading from disk.
signal actions_loaded


func _ready():
	load_templates()


## Loads all the saved action templates from disk
## and parses them using the GDVN format.
func load_templates():
	
	var fa: FileAccess = FileAccess.open(templates_path, FileAccess.READ)
	
	var file_str = fa.get_as_text()
	
	var decoded: Variant = GDVN.parse_string(file_str)
	
	if !(decoded is Dictionary): 
		fa.close()
		return
	
	templates = GDVN.parse_string(file_str)
	
	fa.close()
	
	emit_signal("actions_loaded")


## Get a new EngineAction object based on a saved action
func get_engine_action(template_name: String) -> EngineAction:
	
	var command_list: Array = []
	
	if templates.has(template_name):
		command_list = templates[template_name]
	
	var action: EngineAction = EngineAction.new(command_list)
	return action


## Saves an EngineAction called `action_name` to disk using the GDVN format.
## If `overwrite` is true, an action with the same name will be overwritten if there is one.
func save_engine_action(action: EngineAction, action_name: String, overwrite: bool = false) -> void:
	
	if overwrite:
		var encoded = GDVN.parse_variant_strings(action.get_command_array())
		templates[action_name] = encoded
		save_templates()
		
	else:
		
		if !templates.has(action_name):
			var encoded = GDVN.parse_variant_strings(action.get_command_array())
			templates[action_name] = encoded
			save_templates()
			
		else:
			printerr("Action `" + action_name + "` already exists!")


func delete_engine_action(action_name: String):
	
	templates.erase(action_name)
	save_templates()


## Save all the current templates to disk using GDVN format.
func save_templates() -> void:
	
	var fa: FileAccess = FileAccess.open(templates_path, FileAccess.WRITE)
	
	# We need to duplicate the templates here because Dictionaries are passed by reference
	var templates_dup = templates.duplicate(true)
	var gdvn: String = GDVN.stringify(templates_dup)
	
	fa.store_string(gdvn)
	fa.close()


## Utility function for fetching the corresponding 
## Variant.TYPE enum value from a String
static func type_enum_from_string(type_string: String):
	
	match type_string:
		
		"String":
			return TYPE_STRING
		"Vector2":
			return TYPE_VECTOR2
		"int":
			return TYPE_INT
		"float":
			return TYPE_FLOAT
		"Dictionary":
			return TYPE_DICTIONARY
		"Array":
			return TYPE_ARRAY
		"bool":
			return TYPE_BOOL
		"Variant":
			return TYPE_NIL


## Get the value of a parameter `param_name` for the command at `command_index` in action `action_name`
func get_action_param_value(action_name: String, command_index: int, param_name: String):
	
	var command_list = templates[action_name]
	var command = command_list[command_index]
	
	var command_template = EngineCommands.get_command_template(command.command_name)
	
	for i in command_template.params.size():
		if command_template.params[i].name == param_name:
			return command.params[i]
	
	return ""


func _exit_tree():
	save_templates()
