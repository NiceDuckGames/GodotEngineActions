@tool
extends VBoxContainer

const supported_types: Dictionary = {
	TYPE_BOOL: "Bool",
	TYPE_INT: "Integer",
	TYPE_FLOAT: "Float",
	TYPE_STRING: "String",
	TYPE_OBJECT: "Object",
	TYPE_VECTOR2: "Vector2",
	TYPE_VECTOR2I: "Vector2i",
	TYPE_VECTOR3: "Vector3",
	TYPE_VECTOR3I: "Vector3i"
}

## Index of this parameter in the command's param list
var param_index: int = 0

var param_type: int = TYPE_NIL

signal value_changed(new_value, index)

@onready var bool_editor: CheckBox = $Bool
@onready var int_editor: SpinBox = $Int
@onready var str_editor: LineEdit = $Default/String
@onready var type_select: MenuButton = $Default/TypeSelect

@onready var vec_editor: MarginContainer = $Vector
@onready var vec_x_container: HBoxContainer = $Vector/VBoxContainer/XContainer
var vec_x_editor: EditorSpinSlider
@onready var vec_y_container: HBoxContainer = $Vector/VBoxContainer/YContainer
var vec_y_editor: EditorSpinSlider
@onready var vec_z_container: HBoxContainer = $Vector/VBoxContainer/ZContainer
var vec_z_editor: EditorSpinSlider

var float_editor: EditorSpinSlider
#var resource_editor: EditorResourcePicker


func _ready():
	
	float_editor = EditorSpinSlider.new()
	float_editor.step = 0.001
	float_editor.hide_slider = true
	float_editor.connect("value_changed", self._on_float_editor_value_changed)
	float_editor.visible = false
	
	add_child(float_editor)
	
	vec_x_editor = EditorSpinSlider.new()
	vec_x_editor.step = 0.001
	vec_x_editor.hide_slider = true
	vec_x_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vec_x_editor.connect("value_changed", self._on_x_value_changed)
#	vec_x_editor.visible = false
	
	vec_x_container.add_child(vec_x_editor)
	
	vec_y_editor = EditorSpinSlider.new()
	vec_y_editor.step = 0.001
	vec_y_editor.hide_slider = true
	vec_y_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vec_y_editor.connect("value_changed", self._on_y_value_changed)
#	vec_y_editor.visible = false
	
	vec_y_container.add_child(vec_y_editor)
	
	vec_z_editor = EditorSpinSlider.new()
	vec_z_editor.step = 0.001
	vec_z_editor.hide_slider = true
	vec_z_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vec_z_editor.connect("value_changed", self._on_z_value_changed)
#	vec_z_editor.visible = false
	
	vec_z_container.add_child(vec_z_editor)
	
	for type in supported_types:
		type_select.get_popup().add_item(supported_types[type], type)
	
	type_select.get_popup().connect("id_pressed", self._on_type_select_id_pressed)
	
#	resource_editor = EditorResourcePicker.new()
#	add_child(resource_editor)


func set_type(type: int):
	
	match type:
		
		TYPE_BOOL:
			
			param_type = type
			
#			resource_editor.visible = false
			type_select.visible = false
			bool_editor.visible = true
			float_editor.visible = false
			int_editor.visible = false
			str_editor.visible = false
			vec_editor.visible = false
		
		TYPE_FLOAT:
			
			param_type = type
			
#			resource_editor.visible = false
			type_select.visible = false
			bool_editor.visible = false
			float_editor.visible = true
			int_editor.visible = false
			str_editor.visible = false
			vec_editor.visible = false
		
		TYPE_STRING:
			
			param_type = type
			
#			resource_editor.visible = false
			type_select.visible = false
			bool_editor.visible = false
			float_editor.visible = false
			int_editor.visible = false
			str_editor.visible = true
			type_select.visible = false
			vec_editor.visible = false
		
		TYPE_INT:
			
			param_type = type
			
#			resource_editor.visible = false
			type_select.visible = false
			bool_editor.visible = false
			float_editor.visible = false
			int_editor.visible = true
			str_editor.visible = false
			vec_editor.visible = false
		
		TYPE_OBJECT:
			
			param_type = type
			
#			resource_editor.visible = true
			type_select.visible = false
			bool_editor.visible = false
			float_editor.visible = false
			int_editor.visible = false
			str_editor.visible = false
			vec_editor.visible = false
		
		TYPE_VECTOR2:
			
			param_type = type
			
			type_select.visible = false
			bool_editor.visible = false
			float_editor.visible = false
			int_editor.visible = false
			str_editor.visible = false
			vec_editor.visible = true
			
			vec_x_container.visible = true
			vec_y_container.visible = true
			vec_z_container.visible = false
		
		TYPE_VECTOR2I:
			
			param_type = type
			
			type_select.visible = false
			bool_editor.visible = false
			float_editor.visible = false
			int_editor.visible = false
			str_editor.visible = false
			vec_editor.visible = true
			
			vec_x_container.visible = true
			vec_x_editor.rounded = true
			vec_y_container.visible = true
			vec_y_editor.rounded = true
			vec_z_container.visible = false
		
		TYPE_VECTOR3:
			
			param_type = type
			
			type_select.visible = false
			bool_editor.visible = false
			float_editor.visible = false
			int_editor.visible = false
			str_editor.visible = false
			vec_editor.visible = true
			
			vec_x_container.visible = true
			vec_y_container.visible = true
			vec_z_container.visible = true
			
		TYPE_VECTOR3I:
			
			param_type = type
			
			type_select.visible = false
			bool_editor.visible = false
			float_editor.visible = false
			int_editor.visible = false
			str_editor.visible = false
			vec_editor.visible = true
			
			vec_x_container.visible = true
			vec_x_editor.rounded = true
			vec_y_container.visible = true
			vec_y_editor.rounded = true
			vec_z_container.visible = true
			vec_z_editor.rounded = true
		
		_:
			
			param_type = TYPE_NIL
			
#			resource_editor.visible = false
			bool_editor.visible = false
			float_editor.visible = false
			int_editor.visible = false
			str_editor.visible = false
			type_select.visible = true
			vec_editor.visible = false


## Set the `text` property of this param's LineEdit
func set_value(param_value: Variant):
	
	match typeof(param_value):
		
		TYPE_BOOL:
			bool_editor.set_pressed_no_signal(param_value)
		
		TYPE_INT:
			int_editor.set_value_no_signal(param_value)
			int_editor.get_line_edit().text = str(param_value)
		
		TYPE_FLOAT:
			float_editor.set_value_no_signal(param_value)
		
		TYPE_STRING:
			str_editor.text = param_value
		
		TYPE_VECTOR2:
			vec_x_editor.set_value_no_signal(param_value.x)
			vec_y_editor.set_value_no_signal(param_value.y)
		
		TYPE_VECTOR2I:
			vec_x_editor.set_value_no_signal(param_value.x)
			vec_y_editor.set_value_no_signal(param_value.y)
		
		TYPE_VECTOR3:
			vec_x_editor.set_value_no_signal(param_value.x)
			vec_y_editor.set_value_no_signal(param_value.y)
			vec_z_editor.set_value_no_signal(param_value.z)
		
		TYPE_VECTOR3I:
			vec_x_editor.set_value_no_signal(param_value.x)
			vec_y_editor.set_value_no_signal(param_value.y)
			vec_z_editor.set_value_no_signal(param_value.z)
		
		_:
			print("unknown param type")


func get_value():
	
	match param_type:
		
		TYPE_BOOL:
			return bool_editor.button_pressed
		
		TYPE_INT:
			return int_editor.value
		
		TYPE_FLOAT:
			return float_editor.value
		
		TYPE_STRING:
			return str_editor.text
		
		TYPE_VECTOR2:
			var vec: Vector2 = Vector2(vec_x_editor.value, vec_y_editor.value)
			return vec
		
		TYPE_VECTOR2I:
			var vec: Vector2i = Vector2i(vec_x_editor.value, vec_y_editor.value)
			return vec
		
		TYPE_VECTOR3:
			var vec: Vector3 = Vector3(vec_x_editor.value, vec_y_editor.value, vec_z_editor.value)
			return vec
		
		TYPE_VECTOR3I:
			var vec: Vector3i = Vector3i(vec_x_editor.value, vec_y_editor.value, vec_z_editor.value)
			return vec
		
		_:
			return str_editor.text


## Set up the ui for this param item
func set_data(param_name: String, index: int):
	$Label.text = param_name + ": "
	param_index = index
	$Default/String.text = ""


## Called when this parameter's LineEdit value is changed
## Start of the callback chain that ends in ActionsTab.gd
func _on_line_edit_text_changed(new_text):
	emit_signal("value_changed", get_value(), param_index)


func _on_int_value_changed(value):
	emit_signal("value_changed", get_value(), param_index)


func _on_float_editor_value_changed(value):
	emit_signal("value_changed", get_value(), param_index)


func _on_x_value_changed(value: float) -> void:
	emit_signal("value_changed", get_value(), param_index)


func _on_y_value_changed(value: float) -> void:
	emit_signal("value_changed", get_value(), param_index)


func _on_z_value_changed(value: float) -> void:
	emit_signal("value_changed", get_value(), param_index)


func _on_type_select_id_pressed(id: int) -> void:
	set_type(id)


func _on_bool_toggled(value: bool) -> void:
	bool_editor.text = "True" if value else "False"
	emit_signal("value_changed", get_value(), param_index)
