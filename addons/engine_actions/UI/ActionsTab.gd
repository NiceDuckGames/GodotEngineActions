@tool
extends MarginContainer

var action_item_res: PackedScene = preload("res://addons/engine_actions/UI/action_command_item.tscn")

## The container for all the selectable action buttons
@onready var actions_container = $HSplitContainer/MarginContainer/TabContainer/Actions/VBoxContainer
## The container for all the selectable command buttons
@onready var commands_container = $HSplitContainer/MarginContainer/TabContainer/Commands/VBoxContainer
## The container that displays the indiviudal commands (action_command_item.tscn) being edited
@onready var editor_item_container = $HSplitContainer/VBoxContainer/ActionViewer/PanelContainer/MarginContainer/HBoxContainer
## Checkbox for whether to overwrite an action with the same name while saving
@onready var overwrite_toggle = $HSplitContainer/VBoxContainer/HBoxContainer/Overwrite
@onready var action_viewer: ScrollContainer = $HSplitContainer/VBoxContainer/ActionViewer

@onready var save_action_name_line_edit = $HSplitContainer/VBoxContainer/HBoxContainer/LineEdit

## List of all the `action_command_item.tscn`s so we can do ui updates by index
var command_item_list: Array = []

## The action template (command list) for the current content of the action editor
var current_action_template: Array = []

## A reference to the EngineAction that is created when playback begins.
var currently_playing_action: EngineAction = null
## The index of the command that `currently_playing_action` is currently executing.
var currently_playing_command_index: int = -1


func _ready():
	
	EngineCommands.connect("templates_loaded", self._on_templates_loaded)


func _on_templates_loaded():
	update_ui()


func update_ui():
	load_actions()
	load_commands()


## Syncs the order of the command item nodes in the editor UI with
## the indices of the command items in `command_item_list`.
func update_command_items():
	
	var command_item_container: VBoxContainer = $HSplitContainer/VBoxContainer/ActionViewer/PanelContainer/MarginContainer/HBoxContainer
	
	for i in range(command_item_list.size()):
		
		command_item_container.move_child(command_item_list[i], i)
		
		command_item_list[i].set_item_index(i)
		command_item_list[i].set_max_index(command_item_list.size() - 1)


## Saves the currently edited action to disk.
## If `overwrite` is true, it will overwrite an action with the same name.
func save_current_action(overwrite: bool):
	
	var action = EngineAction.new(current_action_template)
	EngineActionDB.save_engine_action(action, $HSplitContainer/VBoxContainer/HBoxContainer/LineEdit.text, overwrite)
	
	update_ui()


## Changes the amount of time between each command execution
## for actions being played back from the editor.
func change_playback_speed(new_value: float):
	
	EngineCommands.command_wait_interval = clamp(new_value / 1000.0, 0.1, 5.0)
	$HSplitContainer/VBoxContainer/Toolbar/PlaybackSpeed/Label2.text = "%6.3f" % (new_value / 1000.0)


### Command and Action lists ###


## Refreshes the list of selectable commands
func load_commands():
	
	for child in commands_container.get_children():
		child.queue_free()
	
	for command in EngineCommands.command_templates:
	
		var button: Button = Button.new()
		button.text = command.command_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		
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
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		
		var button_callable: Callable = self._on_button_pressed.bind(action_name, true)
		button.connect("pressed", button_callable)
		
		actions_container.add_child(button)
		button.set_owner(self.owner)


### Action Editor ###


## Delete the command at `command_index` in the currently edited action.
func delete_command(command_index: int):
	
	command_item_list.remove_at(command_index)
	current_action_template.remove_at(command_index)
	
	for i in command_item_list.size():
		command_item_list[i].set_item_index(i)


## Clears the entire command list that is currently being edited.
func clear_command_list():
	
	for item in command_item_list:
		item.queue_free()
	
	command_item_list.clear()
	current_action_template.clear()
	
	save_action_name_line_edit.text = ""


## Changes the index of a command in the list.
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
	
	item.connect("param_value_changed", self._on_param_changed)
	item.connect("command_deleted", self._on_command_deleted)
	item.connect("index_changed", self._on_command_index_changed)
	
	editor_item_container.add_child(item)
	
	item.set_data(command_name, param_templates, command_item_list.size())
	item.set_max_index(command_item_list.size())
	
	for i in command_param_values.size():
		
		var value = GDVN.parse_variant_strings(command_param_values[i])
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


### Playback ###


## Begins playing the action that is being edited.
func play_current_action():
	
	var parsed_command_list = GDVN.parse_variant_strings(current_action_template)
	
	currently_playing_action = EngineAction.new(parsed_command_list)
	
	currently_playing_action.connect("command_complete", _on_action_command_complete)
	currently_playing_action.connect("paused", _on_action_paused)
	currently_playing_action.connect("stopped", _on_action_stopped)
	currently_playing_action.connect("unpause", _on_action_unpaused)
	
	currently_playing_command_index = 0
	
	command_item_list[currently_playing_command_index].is_playing = true
	command_item_list[currently_playing_command_index].playing_highlight()
	
	action_viewer.ensure_control_visible(command_item_list[currently_playing_command_index])
	
	await currently_playing_action.execute_action()
	
	command_item_list[currently_playing_command_index].unhighlight()
	currently_playing_action.free()
	currently_playing_action = null


## Called when the "Pause" button is pressed in the editor.
func pause_current_action():
	
	if !currently_playing_action: return
	
	currently_playing_action.pause()


## Called when the "Stop" button is pressed in the editor.
func stop_current_action():
	
	if !currently_playing_action: return
	
	currently_playing_action.stop()


## Emitted by `currently_playing_action` when the Action pauses.
## Sets the theme of the respective command node to `paused`.
func _on_action_paused():
	
	command_item_list[currently_playing_command_index].paused_highlight()


## Emitted by `currently_playing_action` when the Action stops.
## Sets the theme of the respective command node to `stopped`.
func _on_action_stopped():
	
	command_item_list[currently_playing_command_index].stopped_highlight()


## Emitted by `currently_playing_action` when the Action resumes execution.
## Sets the theme of the respective command node to `playing`.
func _on_action_unpaused():
	
	command_item_list[currently_playing_command_index].playing_highlight()


## Emitted by `currently_playing_action` when a command finishes executing
## and advances to the next one. Advances the visual representation in the UI.
func _on_action_command_complete(command_index):
	
	var new_index = command_index + 1
	
	if new_index >= command_item_list.size():
		command_item_list[currently_playing_command_index].is_playing = false
		return
	
	command_item_list[currently_playing_command_index].is_playing = false
	
	currently_playing_command_index = new_index
	
	command_item_list[currently_playing_command_index].is_playing = true
	
	command_item_list[command_index].unhighlight()
	command_item_list[new_index].playing_highlight()
	
	action_viewer.ensure_control_visible(command_item_list[currently_playing_command_index])


### UI Signals ###


## Saves the data in `current_action_template` with the inputted action name
func _on_save_action_pressed():
	
	save_current_action(overwrite_toggle.button_pressed)


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


## Called when the delete button is pressed on any command item.
func _on_command_deleted(command_index: int):
	
	delete_command(command_index)


## Called when a command's index is changed in the action editor.
func _on_command_index_changed(old_index: int, new_index: int):
	
	move_command(old_index, new_index)


func _on_play_action_pressed():
	
	if currently_playing_action && currently_playing_action.is_paused:
		currently_playing_action.resume()
	else:
		await play_current_action()


func _on_clear_commands_pressed():
	
	clear_command_list()


func _on_playback_speed_value_changed(value):
	
	change_playback_speed(value)


func _on_pause_action_pressed():
	pause_current_action()


func _on_stop_action_pressed():
	stop_current_action()


func _on_delete_action_pressed():
	EngineActionDB.delete_engine_action(save_action_name_line_edit.text)
