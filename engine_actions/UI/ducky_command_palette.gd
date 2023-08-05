@tool
extends Control

var editor_command_palette: EditorCommandPalette

@onready var popup_window: Popup = $Popup
@onready var response_label: RichTextLabel = $Popup/PanelContainer/MarginContainer/VSplitContainer/RichTextLabel
@onready var input_line_edit: LineEdit = $Popup/PanelContainer/MarginContainer/VSplitContainer/PromptInput


func _ready():
	editor_command_palette.add_command("prompt", "Ducky/Prompt", self._on_popup_command, "Ctrl+Alt+D")


func _on_popup_command():
	popup_window.popup_centered()
	input_line_edit.grab_focus()


func _exit_tree():
	editor_command_palette.remove_command("Ducky/Prompt")


func _on_prompt_input_text_submitted(new_text):
	GPTAssistant.submit_prompt(new_text)
