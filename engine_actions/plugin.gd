@tool
extends EditorPlugin

var chat_box_res = preload("res://addons/engine_actions/UI/actions_main_screen.tscn")
var chat_box_instance: Control = null

var command_palette_res = preload("res://addons/engine_actions/UI/ducky_command_palette.tscn")
var command_palette_instance: Control = null

var record_actions_button_res = preload("res://addons/engine_actions/UI/action_record_button.tscn")
var record_actions_button: Control = null

var engine_commands_autoload_path: String = "res://addons/engine_actions/Actions/engine_commands.gd"
var engine_action_db_autoload_path: String = "res://addons/engine_actions/Actions/engine_action_db.gd"
var assistant_autoload_path: String = "res://addons/engine_actions/Ducky/assistant_autoload.gd"
var chat_api_autoload_path: String = "res://addons/engine_actions/Ducky/chat_api.gd"
var prompts_autoload_path: String = "res://addons/engine_actions/Ducky/prompts.gd"
var action_recorder_path: String = "res://addons/engine_actions/Actions/action_recorder.gd"


func _enter_tree():
	
	add_autoload_singleton("ChatAPI", chat_api_autoload_path)
	add_autoload_singleton("Prompts", prompts_autoload_path)
	add_autoload_singleton("EngineCommands", engine_commands_autoload_path)
	add_autoload_singleton("EngineActionDB", engine_action_db_autoload_path)
	add_autoload_singleton("GPTAssistant", assistant_autoload_path)
	add_autoload_singleton("ActionRecorder", action_recorder_path)
	
	chat_box_instance = chat_box_res.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(chat_box_instance)
	
	chat_box_instance.setup(self)
	chat_box_instance.update_ui()
	chat_box_instance.hide()
	
	record_actions_button = record_actions_button_res.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, record_actions_button)
	
	command_palette_instance = command_palette_res.instantiate()
	command_palette_instance.editor_command_palette = get_editor_interface().get_command_palette()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, command_palette_instance)


func _has_main_screen():
	return true


func _build():
	return true


func _apply_changes():
	chat_box_instance.update_ui()


func _make_visible(visible):
	chat_box_instance.visible = visible
	chat_box_instance.update_ui()


func _get_plugin_name():
	return "Ducky"


func _exit_tree():
	
	chat_box_instance.queue_free()
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, command_palette_instance)
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, record_actions_button)
	
	remove_autoload_singleton("GPTAssistant")
	remove_autoload_singleton("EngineActionDB")
	remove_autoload_singleton("EngineCommands")
	remove_autoload_singleton("ActionRecorder")
