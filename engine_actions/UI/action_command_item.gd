@tool
extends MarginContainer

var command_param_res = preload("res://addons/engine_actions/UI/command_item_parameter.tscn")
var normal_theme_res = preload("res://addons/engine_actions/UI/Themes/action_command_item_normal.tres")
var hover_theme_res = preload("res://addons/engine_actions/UI/Themes/action_command_item_hover.tres")


@onready var command_name_label = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/CommandName
@onready var param_item_container = $MarginContainer/MarginContainer/VBoxContainer

@onready var re_index_spin_box: SpinBox = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/ReIndexValue
@onready var re_index_button: Button = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/ReIndexButton

## The name of the command associated with this ui element
var command_name_string: String = ""

## List of the ui elements that hold the parameter data
var param_items: Array = []
## List of the values of each parameter
var param_values: Array = []
## The index of this command in the currently edited action's command list
var item_index: int = 0

var is_selected: bool = false
var is_hovered: bool = false

## Emitted when the value of a parameter is changed
signal param_value_changed(param_values, index)
## Emitted when this command's delete button is pressed
signal command_deleted(index)

signal index_changed(old_index, new_index)

signal selected(index)


func _ready():
	focus_mode = Control.FOCUS_ALL
	

func _gui_input(event):
	
	if is_hovered && event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && !event.is_pressed():
			
			is_selected = !is_selected
			
			if is_selected:
				emit_signal("selected", item_index)


func _process(delta):
	
	if !$MarginContainer.get_global_rect().has_point(get_global_mouse_position()):
		if is_hovered:
			_on_mouse_exited()
	else:
		if !is_hovered:
			_on_mouse_entered()


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
func set_param_value(param_index: int, param_value: String):
	
	if param_values.is_empty(): return
	
	param_values[param_index] = param_value
	param_items[param_index].set_value(param_value)


## Set up the ui elements for this command
func set_data(command_name: String, param_templates: Array, index: int):
	
	command_name_label = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/CommandName
	param_item_container = $MarginContainer/MarginContainer/VBoxContainer
	re_index_spin_box = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/ReIndexValue
	re_index_button = $MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/ReIndexButton
	
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
		
		i += 1


func set_max_index(max: int):
	re_index_spin_box.max_value = max


## Called when this command's delete button is pressed
func _on_delete_pressed():
	emit_signal("command_deleted", item_index)
	self.queue_free()


func _on_re_index_button_pressed():
	
	re_index_button.visible = false
	re_index_spin_box.visible = true


func _on_re_index_value_value_changed(value):
	
	var as_int: int = int(value)
	
	re_index_spin_box.visible = false
	re_index_button.visible = true
	
	emit_signal("index_changed", item_index, as_int)


func _on_mouse_entered():
	
	is_hovered = true
	$MarginContainer["theme_override_styles/panel"] = hover_theme_res


func _on_mouse_exited():
	
	is_hovered = false
	
	if !is_selected:
	
		$MarginContainer["theme_override_styles/panel"] = normal_theme_res
