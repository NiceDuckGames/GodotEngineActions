@tool
extends VBoxContainer

## Index of this parameter in the command's param list
var param_index: int = 0

signal value_changed(new_value, index)


## Set the `text` property of this param's LineEdit
func set_value(param_value: String):
	$LineEdit.text = param_value


## Set up the ui for this param item
func set_data(param_name: String, index: int):
	$Label.text = param_name + ": "
	param_index = index
	$LineEdit.text = ""


## Called when this parameter's LineEdit value is changed
## Start of the callback chain that ends in ActionsTab.gd
func _on_line_edit_text_changed(new_text):
	emit_signal("value_changed", new_text, param_index)
