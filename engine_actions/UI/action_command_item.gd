@tool
extends MarginContainer

var command_param_res = preload("res://addons/engine_actions/UI/command_item_parameter.tscn")
var normal_theme_res = preload("res://addons/engine_actions/UI/Themes/action_command_item_normal.tres")
var hover_theme_res = preload("res://addons/engine_actions/UI/Themes/action_command_item_hover.tres")
var playing_theme_res = preload("res://addons/engine_actions/UI/Themes/action_command_item_playing.tres")
var paused_theme_res = preload("res://addons/engine_actions/UI/Themes/action_command_item_paused.tres")
var stopped_theme_res = preload("res://addons/engine_actions/UI/Themes/action_command_item_stopped.tres")


@onready var command_name_label: Label
@onready var param_item_container: VBoxContainer
@onready var re_index_spin_box: SpinBox
@onready var re_index_button: Button


## The name of the command associated with this ui element
var command_name_string: String = ""

## List of the ui elements that hold the parameter data
var param_items: Array = []
## List of the values of each parameter
var param_values: Array = []
## The index of this command in the currently edited action's command list
var item_index: int = 0

## Whether this command is currently being executed during playback
## in the action editor. Prevents the user from changing this command
## during execution.
var is_playing: bool = false

## Emitted when the value of a parameter is changed
signal param_value_changed(param_values, index)
## Emitted when this command's delete button is pressed
signal command_deleted(index)
## Emitted when this command's index within the command list is changed
signal index_changed(old_index, new_index)


func _ready():
	focus_mode = Control.FOCUS_ALL


## Called when a parameter text field has its value changed
func _on_param_value_changed(new_text, param_index):
	param_values[param_index] = new_text
	emit_signal("param_value_changed", param_values, item_index)


## Get a representation of this command using the values defined by the user
func get_command_template():
	var template = {
		"command_name": command_name_string,
		"params": param_values
	}
	
	return template


## Update the index of this command in the edited command list
func set_item_index(new_index: int):
	
	item_index = new_index
	re_index_button.text = " " + str(new_index) + " "
	re_index_spin_box.set_value_no_signal(new_index)


## Update the value of the param at the given index
func set_param_value(param_index: int, param_value: Variant):
	
	if param_values.is_empty(): return
	
	param_values[param_index] = param_value
	param_items[param_index].set_value(param_value)


## Set up the ui elements for this command
func set_data(command_name: String, param_templates: Array, index: int):
	
	command_name_label = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/CommandName
	param_item_container = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer
	re_index_spin_box = $MarginContainer/HBoxContainer/ReIndexValue
	re_index_button = $MarginContainer/HBoxContainer/ReIndexButton
	
	item_index = index
	command_name_string = command_name
	
	command_name_label.text = command_name
	re_index_button.text = " " + str(index) + " "
	re_index_spin_box.value = index
	
	var i = 0
	for param in param_templates:
		
		param_values.push_back("")
		
		var param_item = command_param_res.instantiate()
		param_item.set_data(param.name, i)

		param_item.connect("value_changed", self._on_param_value_changed)
		
		param_items.push_back(param_item)
		
		param_item_container.add_child(param_item)
		
		param_item.call_deferred("set_type", EngineActionDB.type_enum_from_string(param.type))
		
		i += 1


## Changes the maximum value of the re-index spinbox in the UI
## to prevent users from setting it out of range.
func set_max_index(max: int):
	re_index_spin_box.max_value = max


func stopped_highlight():
	$MarginContainer["theme_override_styles/panel"] = stopped_theme_res
	grab_focus()

func paused_highlight():
	$MarginContainer["theme_override_styles/panel"] = paused_theme_res
	grab_focus()

func playing_highlight():
	$MarginContainer["theme_override_styles/panel"] = playing_theme_res
	grab_focus()

func hover_highlight():
	$MarginContainer["theme_override_styles/panel"] = hover_theme_res
	grab_focus()

func unhighlight():
	$MarginContainer["theme_override_styles/panel"] = normal_theme_res


## Called when this command's delete button is pressed
func _on_delete_pressed():
	
	if is_playing: return
	
	emit_signal("command_deleted", item_index)
	self.queue_free()


func _on_re_index_button_pressed():
	
	if is_playing: return
	
	re_index_button.visible = false
	re_index_spin_box.visible = true
	re_index_spin_box.grab_focus()


func _on_re_index_value_value_changed(value):
	
	if is_playing: return
	
	var as_int: int = int(value)
	
	re_index_spin_box.visible = false
	re_index_button.visible = true
	
	emit_signal("index_changed", item_index, as_int)


func _on_copy_cache_access_pressed() -> void:
	
	DisplayServer.clipboard_set("$" + str(item_index))


func _on_re_index_value_focus_exited() -> void:
	re_index_spin_box.visible = false
	re_index_button.visible = true
