@tool
extends EditorPlugin

var action_editor_res = preload("res://addons/engine_actions/UI/actions_main_screen.tscn")
var action_editor_instance: Control = null

var record_actions_button_res = preload("res://addons/engine_actions/UI/action_record_button.tscn")
var record_actions_button: Control = null

var engine_commands_autoload_path: String = "res://addons/engine_actions/Actions/engine_commands.gd"
var engine_action_db_autoload_path: String = "res://addons/engine_actions/Actions/engine_action_db.gd"
var action_recorder_path: String = "res://addons/engine_actions/Actions/action_recorder.gd"


func _enter_tree():
	
	add_autoload_singleton("EngineCommands", engine_commands_autoload_path)
	add_autoload_singleton("EngineActionDB", engine_action_db_autoload_path)
	add_autoload_singleton("ActionRecorder", action_recorder_path)
	
	action_editor_instance = action_editor_res.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(action_editor_instance)
	
	action_editor_instance.setup(self)
	action_editor_instance.update_ui()
	action_editor_instance.hide()
	
	record_actions_button = record_actions_button_res.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, record_actions_button)


func _has_main_screen():
	return true


func _build():
	return true


func _apply_changes():
	action_editor_instance.update_ui()


func _make_visible(visible):
	action_editor_instance.visible = visible
	action_editor_instance.update_ui()


func _get_plugin_name():
	return "Actions"


func _get_plugin_icon():
	return preload("res://addons/engine_actions/EngineActionsIcon.png")


func _exit_tree():
	
	action_editor_instance.queue_free()
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, record_actions_button)
	
	remove_autoload_singleton("EngineActionDB")
	remove_autoload_singleton("EngineCommands")
	remove_autoload_singleton("ActionRecorder")
