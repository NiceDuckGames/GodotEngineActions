@tool
extends Node

## A reference to the plugin's EditorInterface.
## Is used in command functions to interact with different parts of the editor.
var editor_interface: EditorInterface

## The list of command templates. 
## A command template contains the command name, and the name and type of its parameters.
## Its structure is as follows:
##
## {
##     "command_name": "test_name",
##     "params": [
##         {"name": "param1", "type": "String"},
##         {"name": "param2", "type": "int"}
##     ]
## }
var command_templates: Array = []

## Emitted when the command is finished executing
## and its wait timer times out.
signal command_complete

## Emitted when the templates are finished loading from disk.
signal templates_loaded

## The length of time to wait between each command execution.
var command_wait_interval: float = 0.1

## A reference to the EngineAction that is currently being executed.
## Is `null` if no action is being executed.
var currently_executing_action: EngineAction = null

## The editor's SceneTreeDock node.
var scene_tree_dock: Control = null


func _ready():
	
	scene_tree_dock = get_scene_tree_dock()
	
	load_templates()


## Recursively searches the editor's scene tree and returns the SceneTreeDock Node.
func get_scene_tree_dock(root: Node = get_tree().root):
	
	for child in root.get_children():
		
		if child.get_class() != "SceneTreeDock":
			
			if child.get_children().size() > 0:
				
				var i = get_scene_tree_dock(child)
				
				if i:
					return i
		
		else:
			
			return child


## Loads all the command templates from disk.
func load_templates():
	var fa: FileAccess = FileAccess.open("res://addons/engine_actions/Actions/command_templates.json", FileAccess.READ)
	
	var text = fa.get_as_text()
	command_templates = GDVN.parse_string(text)
	
	fa.close()
	
	emit_signal("templates_loaded")


## Returns the template for command `command_name`.
## Returns `null` if the command doesn't exist.
func get_command_template(command_name: String):
	for template in command_templates:
		if template.command_name == command_name:
			return template


## Factory function that takes in command data and
## returns it in a format that is compatible with EngineActions.
func generate_command(command_name: String, param_values: Array):
	
	var command = {}
	command["command_name"] = command_name
	command["params"] = param_values
	
	return command


## Called by an EngineAction when `EngineAction.execute()` is called.
## Used to keep more than one EngineAction from executing at the same time.
func begin_action_execution(action: EngineAction):
	currently_executing_action = action


## Called by an executing EngineAction when all commands have completed.
func end_action_execution():
	currently_executing_action = null


func is_action_executing():
	if currently_executing_action != null:
		return true
	return false


## Start the command wait timer. The calling EngineAction will not
## resume execution until the timer has elapsed.
func wait(length: float = 0.1):
	
	var wait_time = length if length != 0.1 else command_wait_interval
	
	get_tree().create_timer(wait_time).connect("timeout", self._on_wait_timer_timeout)


func _on_wait_timer_timeout():
	emit_signal("command_complete")


######### Commands #########


## Sets the indexed property at `property_path` on the node at `node_path`
## in the currently edited scene tree.
func set_property(node_path: String, property_path: String, value) -> void:
	
	var context = editor_interface.get_edited_scene_root()
	var target_node = context.get_node(node_path)
	
	target_node.set_indexed(property_path, value)
	
	wait()


## Returns the Resource property at `property_path` of the Node at
## `node_path` in the currently edited scene tree.
func get_builtin_resource(node_path: String, property_path: String) -> Resource:
	var path = node_path + ":" + property_path
	var res = editor_interface.get_edited_scene_root().get_node_and_resource(path)[1]
	
	wait()
	
	return res


## Creates and saves a new script at `file_path` in the res:// directory.
## The source code of the script is set to `script_text` verbatim.
func create_script(file_path: String, script_text: String) -> GDScript:
	
	var script: GDScript = GDScript.new()
	script.source_code = script_text
	
	ResourceSaver.save(script, file_path)
	
	wait()
	
	return script


## Attaches the script at `script_path` to the node
## at `node_path` in the current edited scene tree.
func attach_script(node_path: String, script_path: String) -> void:
	
	var context = editor_interface.get_edited_scene_root()
	
	var target_node = context.get_node(node_path)
	var script = ResourceLoader.load(script_path)
	target_node.set_script(script)
	
	wait()


## Creates and saves a scene at `file_path` with a root node
## of type `root_type` named `root_name`.
func create_scene(root_type: String, root_name: String, file_path: String) -> PackedScene:
	
	var packed_scene = PackedScene.new()
	var root_node
	
	if root_type != "":
		
		root_node = ClassDB.instantiate(root_type)
		root_node.name = root_name
		
	packed_scene.pack(root_node)
	
	ResourceSaver.save(packed_scene, file_path)
	
	wait()
	
	return packed_scene


## Opens the scene at `file_path` for editing.
func open_scene(file_path: String) -> void:
	
	editor_interface.open_scene_from_path(file_path)
	editor_interface.call_deferred("set_main_screen_editor", "Actions")
	
	wait(1.0)


## Saves the current scene to disk
func save_scene(file_path: String = "") -> void:
	
	if file_path == "":
		
		var scene_path: String = editor_interface.get_edited_scene_root().scene_file_path
		var packed: PackedScene = PackedScene.new()
		
		packed.pack(editor_interface.get_edited_scene_root())
		ResourceSaver.save(packed, scene_path)
		
#		editor_interface.save_scene()
	else:
		
		var packed: PackedScene = PackedScene.new()
		
		packed.pack(editor_interface.get_edited_scene_root())
		ResourceSaver.save(packed, file_path)
		
#		editor_interface.save_scene_as(file_path)
	
	wait(1.0)


## Loads and adds the scene at `scene_path` as a child of
## the node at `parent_path` in the currently edited scene tree.
## Names the new node `node_name`
func add_scene(scene_path: String, parent_path: String, node_name: String) -> Node:
	
	var context = editor_interface.get_edited_scene_root()
	
	var parent_node = context.get_node(parent_path)
	var parent_owner: Node
	
	if parent_node == context:
		parent_owner = context
	else:
		parent_owner = parent_node.get_owner()
	
	var scene: PackedScene = ResourceLoader.load(scene_path)
	var new_node = scene.instantiate()
	new_node.name = node_name
	
	parent_node.add_child(new_node)
	new_node.set_owner(parent_owner)
	
	wait()
	
	return new_node


## Adds a node called `node_name`, of type `node_type`, to the currently edited scene tree.
## The node is placed as a child of the node at `parent_path`, which is a node path
## from the scene's root node.
func add_node(parent_path: String, node_type: String, node_name: String) -> Node:
	
	var context = editor_interface.get_edited_scene_root()
	
	var parent_node = context.get_node(parent_path)
	var parent_owner
	
	if parent_node == context:
		parent_owner = context
	else:
		parent_owner = parent_node.get_owner()
	
	var new_node = ClassDB.instantiate(node_type)
	new_node.name = node_name
	
	parent_node.add_child(new_node)
	new_node.set_owner(parent_owner)
	
	wait()
	
	return new_node


## Moves the node at `from_path` to `to_path`
## in the currently edited scene tree.
func move_node(from_path: String, to_path: String) -> void:
	
	var context = editor_interface.get_edited_scene_root()
	
	var move_node = context.get_node(from_path)
	
	var from_parent = move_node.get_parent()
	from_parent.remove_child(move_node)
	
	var path_split: PackedStringArray = to_path.split("/")
	path_split.remove_at(-1)
	
	var to_parent_path = ""
	
	for substr in path_split:
		to_parent_path += substr + "/"
	
	var to_parent = context.get_node(to_parent_path)
	to_parent.add_child(move_node)
	
	wait()


## Deletes the node at `node_path` in the currently edited scene.
func delete_node(node_path: String) -> void:
	
	var context = editor_interface.get_edited_scene_root()
	
	var target_node = context.get_node(node_path)
	target_node.queue_free()
	
	wait()


## Changes the type of the Node at `node_path` in the currently
## edited scene to type `to_type`.
func change_node_type(node_path: String, to_type: String):
	
	var context = editor_interface.get_edited_scene_root()
	
	var node = context.get_node(node_path)
	var new_node = ClassDB.instantiate(to_type)
	
	scene_tree_dock.replace_node(node, new_node, true, true)
	
	wait()


## Creates and returns a new Resource of type `resource_type`
func create_resource(resource_type: String) -> Resource:
	
	var resource = ClassDB.instantiate(resource_type)
	wait()
	
	return resource


## Saves Resource `resource` to `file_path` in
## the res:// directory
func save_resource(file_path: String, resource: Resource) -> void:
	
	ResourceSaver.save(resource, file_path)
	wait()


## Opens a Resource in the inspector and edits one property
func edit_resource(resource: Resource, property_path: String, value):
	editor_interface.edit_resource(resource)
	resource.set_indexed(property_path, value)
	
	wait()


## Opens the resource at `file_path` in the inspector, and
## sets property `property_path` to value `value`.
func edit_resource_from_path(resource_path: String, property_path: String, value):
	var resource = ResourceLoader.load(resource_path)
	editor_interface.edit_resource(resource)
	resource.set_indexed(property_path, value)
	
	wait()


## Load and returns the resource at `file_path`.
func load_resource(file_path: String) -> Resource:
	var res = load(file_path)
	
	wait()
	
	return res


## Opens the script at `script_path` for editing at the `line` and `column` specified,
## and changes the main screen tab to the script editor.
func edit_script(script_path: String, line: int = -1, column: int = 0):
	
	var script: Script = load(script_path)
	editor_interface.edit_script(script, line, column)
	
	wait(1.0)


## Sets the source of the currently edited script to `script_text`.
func set_current_script_text(script_text: String):
	
	var script_text_edit: TextEdit = editor_interface.get_script_editor().get_current_editor().get_base_editor()
	script_text_edit.clear()
	script_text_edit.set_caret_line(0)
	script_text_edit.set_caret_column(0)
	script_text_edit.insert_text_at_caret(script_text)
	
	wait()


## Appends `append_text` to the end of the currently edited script.
func append_to_current_script(append_text: String):
	
	var script_text_edit: TextEdit = editor_interface.get_script_editor().get_current_editor().get_base_editor()
	
	script_text_edit.text += "\n".c_unescape()
	script_text_edit.text += append_text.c_unescape()
	
	wait()


## Connects signal `signal_name` on the Node at `from_path`
## to the method `method_name` on the Node at `to_path`
## in the currently edited scene tree.
func connect_signal(from_path: String, to_path: String, signal_name: String, method_name: String):
	
	var context = editor_interface.get_edited_scene_root()
	
	var from_node: Node = context.get_node(from_path)
	var to_node: Node = context.get_node(to_path)
	
	if !is_instance_valid(from_node) || !is_instance_valid(to_node):
		return
	
	from_node.connect(signal_name, Callable(to_node, method_name), CONNECT_PERSIST)
	
	scene_tree_dock.get_tree_editor().update_tree()
	
	var d = get_tree().root.find_child("Signals", true, false)
	d.update_tree()
	
	wait()


## Runs the project's main scene as defined in the Project Settings.
func run_project():
	editor_interface.play_main_scene()


## Runs the scene that is currently being edited.
func run_current_scene():
	editor_interface.play_current_scene()


## Runs a scene from a file.
func run_scene_from_file(file_path: String):
	editor_interface.play_custom_scene(file_path)
