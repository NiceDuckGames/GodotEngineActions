@tool
extends ConfirmationDialog

@onready var action_name_line_edit = $MarginContainer/HBoxContainer/LineEdit


func _ready():
	
	register_text_enter(action_name_line_edit)

func _on_confirmed():
	
	ActionRecorder.save_current_action(action_name_line_edit.text)
