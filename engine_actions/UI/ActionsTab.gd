@tool
extends MarginContainer

var action_item_res: PackedScene = preload("res://addons/engine_actions/UI/action_command_item.tscn")

## The container for all the selectable action buttons
@onready var actions_container = $HSplitContainer/MarginContainer/TabContainer/Actions/VBoxContainer
## The container for all the selectable command buttons
@onready var commands_container = $HSplitContainer/MarginContainer/TabContainer/Commands/VBoxContainer
## The container that displays the indiviudal commands (action_command_item.tscn) being edited
@onready var editor_item_container = $HSplitContainer/VBoxContainer/ActionViewer/PanelContainer/HBoxContainer
## Checkbox for whether to overwrite an action with the same name while saving
@onready var overwrite_toggle = $HSplitContainer/VBoxContainer/HBoxContainer/Overwrite

@onready var save_action_name_line_edit = $HSplitContainer/VBoxContainer/HBoxContainer/LineEdit

## List of all the `action_command_item.tscn`s so we can do ui updates by index
var command_item_list: Array = []

## The action template (command list) for the current content of the action editor
var current_action_template: Array = []

var currently_playing_action: EngineAction = null


func _ready():
	ChatAPI.connect("request_completed", self._on_chat_request_completed)
	EngineCommands.connect("templates_loaded", self._on_templates_loaded)

func _on_chat_request_completed(result, response_code, headers, body) -> void:
	var res_data = JSON.parse_string(body.get_string_from_utf8())
	var command_list = GDVN.parse_string(res_data["choices"][0]["message"]["content"])
	
	add_command_list(command_list)

func _on_templates_loaded():
	update_ui()


func update_ui():
	load_actions()
	load_commands()


func update_command_items():
	
	var command_item_container: HBoxContainer = $HSplitContainer/VBoxContainer/ActionViewer/PanelContainer/HBoxContainer
	
	for i in range(command_item_list.size()):
		
		command_item_container.move_child(command_item_list[i], i)
		
		command_item_list[i].set_item_index(i)
		command_item_list[i].set_max_index(command_item_list.size() - 1)


## Refreshes the list of selectable commands
func load_commands():
	
	for child in commands_container.get_children():
		child.queue_free()
	
	for command in EngineCommands.command_templates:
	
		var button: Button = Button.new()
		button.text = command.command_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var button_callable: Callable = self._on_button_pressed.bind(command.command_name, false)
		button.connect("pressed", button_callable)
		
		commands_container.add_child(button)
		button.set_owner(self.owner)


## Refreshes the list of selectable actions
func load_actions():
	
	for child in actions_container.get_children():
		child.queue_free()
	
	for action_name in EngineActionDB.templates:
		
		var button: Button = Button.new()
		button.text = action_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var button_callable: Callable = self._on_button_pressed.bind(action_name, true)
		button.connect("pressed", button_callable)
		
		actions_container.add_child(button)
		button.set_owner(self.owner)


func move_command(from: int, to: int):
	
	if to > command_item_list.size() - 1: 
		update_command_items()
		return
	if to < 0: 
		update_command_items()
		return
	
	var command_item = command_item_list.pop_at(from)
	command_item_list.insert(to, command_item)
	
	var command_template = current_action_template.pop_at(from)
	current_action_template.insert(to, command_template)
	
	update_command_items()


## Add a single command to the action that is currently being edited
func add_command_item(command_name: String, command_param_values: Array = []):
	
	var command_template = EngineCommands.get_command_template(command_name)
	
	if command_template == null:
		printerr("Command `" + command_name + "` not found!")
		return
	
	var param_templates = command_template.params
	
	var item = action_item_res.instantiate()
	
	item.set_data(command_name, param_templates, command_item_list.size())
	item.set_max_index(command_item_list.size())
	
	item.connect("param_value_changed", self._on_param_changed)
	item.connect("command_deleted", self._on_command_deleted)
	item.connect("index_changed", self._on_command_index_changed)
	
	editor_item_container.add_child(item)
	
	for i in command_param_values.size():
		
		var value = GDVN.stringify(command_param_values[i])
		item.set_param_value(i, value)
	
	command_item_list.push_back(item)
	current_action_template.push_back(item.get_command_template())
	
	update_command_items()


## Add an action's command list to the action that is currently being edited
func add_action_item(action_name: String):
	
	var action: EngineAction = EngineActionDB.get_engine_action(action_name)
	var commands = action.get_command_array()
	
	for command in commands:
		add_command_item(command.command_name, command.params)


## Add a list of commands to the action that is currently being edited
func add_command_list(command_list: Array):
	
	for command in command_list:
		add_command_item(command.command_name, command.params)


func play_current_action():
	
	var parsed_command_list = GDVN.parse_variant_strings(current_action_template)
	
	currently_playing_action = EngineAction.new(parsed_command_list)
	await currently_playing_action.execute_action()
	
	currently_playing_action.free()
	currently_playing_action = null


func pause_current_action():
	
	if !currently_playing_action: return
	
	currently_playing_action.pause()


func stop_current_action():
	
	if !currently_playing_action: return
	
	currently_playing_action.stop()


## Saves the data in `current_action_template` with the inputted action name
func _on_save_action_pressed():
	
	var overwrite = overwrite_toggle.button_pressed
	
	var action = EngineAction.new(current_action_template)
	EngineActionDB.save_engine_action(action, $HSplitContainer/VBoxContainer/HBoxContainer/LineEdit.text, overwrite)
	
	update_ui()

## Called when either an add `Action` or `Command` button is pressed
func _on_button_pressed(action_name: String, is_action: bool):
	
	if is_action:
		
		if command_item_list.size() == 0:
			save_action_name_line_edit.text = action_name
		
		add_action_item(action_name)
	else:
		add_command_item(action_name)


## Called when the value of any parameter is changed. Updates the value in `current_action_template`
func _on_param_changed(param_values, item_index):
	current_action_template[item_index] = command_item_list[item_index].get_command_template()


## Called when the delete button is pressed on any command item. Re-indexes the commands
func _on_command_deleted(command_index: int):
	command_item_list.remove_at(command_index)
	current_action_template.remove_at(command_index)
	
	for i in command_item_list.size():
		command_item_list[i].set_item_index(i)


func _on_command_index_changed(old_index: int, new_index: int):
	
	move_command(old_index, new_index)


func _on_play_action_pressed():
	
	if currently_playing_action && currently_playing_action.is_paused:
		currently_playing_action.resume()
	else:
		await play_current_action()


func _on_clear_commands_pressed():
	
	for item in command_item_list:
		item.queue_free()
	
	command_item_list.clear()
	current_action_template.clear()
	
	save_action_name_line_edit.text = ""


func _on_playback_speed_value_changed(value):
	EngineCommands.command_wait_interval = clamp(value / 1000.0, 0.1, 5.0)
	$HSplitContainer/VBoxContainer/Toolbar/PlaybackSpeed/Label2.text = "%6.3f" % (value / 1000.0)


func _on_pause_action_pressed():
	pause_current_action()


func _on_stop_action_pressed():
	stop_current_action()


func _on_delete_action_pressed():
	EngineActionDB.delete_engine_action(save_action_name_line_edit.text)
