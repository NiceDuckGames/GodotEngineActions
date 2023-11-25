@tool
extends VBoxContainer

## Index of this parameter in the command's param list
var param_index: int = 0

signal value_changed(new_value, index)

@onready var int_editor: SpinBox = $Int
@onready var str_editor: LineEdit = $String
var float_editor: EditorSpinSlider
#var resource_editor: EditorResourcePicker


func _ready():
	
	float_editor = EditorSpinSlider.new()
	add_child(float_editor)
	float_editor.connect("value_changed", self._on_float_editor_value_changed)
	
#	resource_editor = EditorResourcePicker.new()
#	add_child(resource_editor)


func set_type(type: int):
	
	match type:
		
		TYPE_FLOAT:
			
#			resource_editor.visible = false
			float_editor.visible = true
			int_editor.visible = false
			str_editor.visible = false
		
		TYPE_STRING:
			
#			resource_editor.visible = false
			float_editor.visible = false
			int_editor.visible = false
			str_editor.visible = true
		
		TYPE_INT:
			
#			resource_editor.visible = false
			float_editor.visible = false
			int_editor.visible = true
			str_editor.visible = false
		
		TYPE_OBJECT:
			
#			resource_editor.visible = true
			float_editor.visible = false
			int_editor.visible = false
			str_editor.visible = false
		
		_:
			
#			resource_editor.visible = false
			float_editor.visible = false
			int_editor.visible = false
			str_editor.visible = true


## Set the `text` property of this param's LineEdit
func set_value(param_value: Variant):
	
	match typeof(param_value):
		
		TYPE_INT:
			int_editor.set_value_no_signal(param_value)
			int_editor.get_line_edit().text = str(param_value)
		
		TYPE_FLOAT:
			float_editor.set_value_no_signal(param_value)
		
		TYPE_STRING:
			str_editor.text = param_value


## Set up the ui for this param item
func set_data(param_name: String, index: int):
	$Label.text = param_name + ": "
	param_index = index
	$String.text = ""


## Called when this parameter's LineEdit value is changed
## Start of the callback chain that ends in ActionsTab.gd
func _on_line_edit_text_changed(new_text):
	emit_signal("value_changed", new_text, param_index)


func _on_int_value_changed(value):
	emit_signal("value_changed", int(value), param_index)


func _on_float_editor_value_changed(value):
	emit_signal("value_changed", value, param_index)
