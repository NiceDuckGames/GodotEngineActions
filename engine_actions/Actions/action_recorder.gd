@tool
extends Node

var editor_plugin: EditorPlugin
var editor_inspector: EditorInspector
var is_recording: bool = false
var current_action_recording: EngineAction = null

var save_action_dialog_res = preload("res://addons/engine_actions/UI/save_action_dialog.tscn")
var save_action_dialog = null


func _ready() -> void:
	
	GodotSense.connect("property_changed", self._on_node_property_changed)
	GodotSense.connect("node_added", self._on_node_created)
	GodotSense.connect("node_moved", self._on_node_moved)
	GodotSense.connect("node_deleted", self._on_node_deleted)
	GodotSense.connect("node_type_changed", self._on_node_type_changed)
	GodotSense.connect("signal_connected", self._on_signal_connected)
	GodotSense.connect("scene_added", self._on_scene_added)
	GodotSense.connect("resource_property_changed", self._on_resource_property_changed)
	GodotSense.connect("resource_changed", self._on_resource_changed)
	GodotSense.connect("resource_created", self._on_resource_created)
	
	save_action_dialog = save_action_dialog_res.instantiate()
	add_child(save_action_dialog)


## Called by the MainScreen "Actions" scene (actions_main_screen.gd)
## in order to provide this script with a reference to the EditorPlugin.
## Is used instead of `_ready()` since the moajority of this script
## relies upon the EditorPlugin reference.
func setup(plugin: EditorPlugin):
	
	editor_plugin = plugin
	editor_inspector = plugin.get_editor_interface().get_inspector()


func start_recording():
	
	print("Recording Actions....")
	
	GodotSense.begin()
	
	editor_plugin.get_editor_interface().get_editor_settings().set_setting("interface/inspector/open_resources_in_current_inspector", false)
	current_action_recording = EngineAction.new([])
	is_recording = true


func stop_recording():
	
	print("Recording Stopped...")
	
	GodotSense.end()
	
	editor_plugin.get_editor_interface().get_editor_settings().set_setting("interface/inspector/open_resources_in_current_inspector", true)
	is_recording = false
	
	save_action_dialog.popup_centered()


func save_current_action(action_name: String):
	
	EngineActionDB.save_engine_action(current_action_recording, action_name, true)


## Checks if a Resource has previously been saved.
func is_resource_saved(resource: Resource):
	
	var object_path: String = resource.resource_path
	var split_check = object_path.split("::", false)
	
	if split_check.size() == 1:
		return true
	else:
		return false


## Gets the path to a Node from the root of the
## currently edited scene tree.
func get_path_to_scene_node(node: Node):
	var scene_root = editor_plugin.get_editor_interface().get_edited_scene_root()
	var node_path = scene_root.get_path_to(node)
	
	return node_path


######### Listeners #########


## Listens for changes in the properties of Nodes in the currently edited scene tree.
func _on_node_property_changed(node: Node, property_path: String, value: Variant, type: int):
	
	if !is_recording: return
	
	var node_path = get_path_to_scene_node(node)
	
	match type:
		
		TYPE_OBJECT:
			
			var obj_type: String
			
			if value == null:
				
				var command = EngineCommands.generate_command("set_property", [node_path, property_path, null])
				current_action_recording.append_command(command)
				
				return
				
			else:
				obj_type = value.get_class()
			
			if is_resource_saved(value):
				var load_command = EngineCommands.generate_command("load_resource", [value.resource_path])
				var command = EngineCommands.generate_command("set_property", [node_path, property_path, "$_"])
				current_action_recording.append_command(load_command)
				current_action_recording.append_command(command)
			else:
				var create_res_command = EngineCommands.generate_command("create_resource", [obj_type])
				var command = EngineCommands.generate_command("set_property", [node_path, property_path, "$_"])
				current_action_recording.append_command(create_res_command)
				current_action_recording.append_command(command)
		
		_:
			
			var command = EngineCommands.generate_command("set_property", [node_path, property_path, value])
			current_action_recording.append_command(command)


## Listens for new resources being created in the file system.
func _on_resource_created(file_path: String, resource: Resource):
	
	if !is_recording: return
	
	if resource is Script:
		
		var command = EngineCommands.generate_command("create_script", [file_path, resource.source_code])
		var edit_command = EngineCommands.generate_command("edit_script", [file_path])
		
		current_action_recording.append_command(command)
		current_action_recording.append_command(edit_command)
	
	elif resource is PackedScene:
		
		var scene: Node = resource.instantiate()
		
		if is_instance_valid(scene):
			
			var command = EngineCommands.generate_command("create_scene", [scene.get_class(), scene.name, file_path])
			current_action_recording.append_command(command)
			
			var open_command = EngineCommands.generate_command("open_scene", [file_path])
			current_action_recording.append_command(open_command)
		
		else:
			var command = EngineCommands.generate_command("create_scene", ["", "", file_path])
			current_action_recording.append_command(command)
	
	else:
		
		var command = EngineCommands.generate_command("create_resource", [resource.get_class()])
		var command2 = EngineCommands.generate_command("save_resource", [file_path, "$_"])
		
		current_action_recording.append_command(command)
		current_action_recording.append_command(command2)


## Listens for changes to resources in the file system.
func _on_resource_changed(file_path: String, resource: Resource):
	
	if !is_recording: return
	
	if resource is Script:
		
		if editor_plugin.get_editor_interface().get_script_editor().get_current_script() == resource:
			
			var command = EngineCommands.generate_command("set_current_script_text", [resource.source_code])
			current_action_recording.append_command(command)
			
		else:
			
			var edit = EngineCommands.generate_command("edit_script", [resource.resource_path, 0, 0])
			var command = EngineCommands.generate_command("set_current_script_text", [resource.source_code])
			
			current_action_recording.append_command(edit)
			current_action_recording.append_command(command)
	
	if resource is PackedScene:
		
		var command = EngineCommands.generate_command("save_scene", [""])
		current_action_recording.append_command(command)


## Listens for changes to the properties of Resources being edited in the Inspector.
func _on_resource_property_changed(object, value, object_path, node_path, prop_path, property_name):
	
	if !is_recording: return
	
	if value is Resource:
		
		if is_resource_saved(value):
			
			var command = EngineCommands.generate_command("edit_resource_from_path", [object_path, property_name, value, value.resource_path])
			current_action_recording.append_command(command)
			
		else:
			
			var create_command = EngineCommands.generate_command("create_resource", [value.get_class()])
			var command = EngineCommands.generate_command("edit_resource", ["$_", property_name, value, value.get_class()])
			current_action_recording.append_command(create_command)
			current_action_recording.append_command(command)
	else:
		
		if is_resource_saved(object):
			
			var command = EngineCommands.generate_command("edit_resource_from_path", [object_path, property_name, value])
			current_action_recording.append_command(command)
			
		else:
			
			var get_res_command = EngineCommands.generate_command("get_builtin_resource", [node_path, prop_path])
			var command = EngineCommands.generate_command("edit_resource", ["$_", property_name, value])
			
			current_action_recording.append_command(get_res_command)
			current_action_recording.append_command(command)


## Listens for Nodes being created in the currently edited scene tree.
func _on_node_created(node: Node):
	
	if !is_recording: return
	
	var node_name = node.name
	var node_type = node.get_class()
	
	var scene_root = editor_plugin.get_editor_interface().get_edited_scene_root()
	
	## If we just created the root node, that means this is a new scene.
	## So we do not record it as a new node.
	if scene_root == node:
		return
	
	if node.scene_file_path != scene_root.scene_file_path:
		return
	
	var parent_node = editor_plugin.get_editor_interface().get_selection().get_selected_nodes()[0].get_parent()
	var parent_path = scene_root.get_path_to(parent_node)
	
	var command = EngineCommands.generate_command("add_node", [parent_path, node_type, node_name])
	current_action_recording.append_command(command)


## Listens for Nodes moving in the currently edited scene tree.
func _on_node_moved(prev_path: String, node: Node):
	
	if !is_recording: return
	
	var context = editor_plugin.get_editor_interface().get_edited_scene_root()
	var new_path = context.get_path_to(node)
	
	var command = EngineCommands.generate_command("move_node", [prev_path, new_path])
	current_action_recording.append_command(command)


## Listens for Node being deleted in the currently edited scene tree.
func _on_node_deleted(node_path: String):
	
	if !is_recording: return
	
	var command = EngineCommands.generate_command("delete_node", [node_path])
	current_action_recording.append_command(command)


## Listens for Nodes having their type changed in the currently edited scene tree.
func _on_node_type_changed(node_path: String, from_type: String, to_type: String):
	
	if !is_recording: return
	
	var command = EngineCommands.generate_command("change_node_type", [node_path, to_type])
	current_action_recording.append_command(command)


## Listens for signals being connected in the currently edited scene tree.
func _on_signal_connected(from_path: String, to_path: String, signal_name: String, method_name: String):
	
	if !is_recording: return
	
	var command = EngineCommands.generate_command("connect_signal", [from_path, to_path, signal_name, method_name])
	current_action_recording.append_command(command)


## Listens for scenes being instanced in the currently edited scene tree.
func _on_scene_added(scene_filepath: String, parent_path: String, node_name: String):
	
	if !is_recording: return
	
	var command = EngineCommands.generate_command("add_scene", [scene_filepath, parent_path, node_name])
	current_action_recording.append_command(command)

