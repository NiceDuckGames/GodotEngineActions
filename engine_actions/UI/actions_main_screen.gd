@tool
extends Control

@onready var prompt_edit: TextEdit = $TabContainer/Chat/HBoxContainer/TextEdit
@onready var chat_box: RichTextLabel = $TabContainer/Chat/RichTextLabel
@onready var action_editor: MarginContainer = $TabContainer/Actions


func _ready():
	
	GPTAssistant.connect("assistant_response", self._on_assistant_response)


## Pass-through for the plugin object
func setup(editor_plugin: EditorPlugin):
	
	EngineCommands.editor_interface = editor_plugin.get_editor_interface()
	ActionRecorder.setup(editor_plugin)


## Update the ui elements of the action editor.
## Refreshes the editor's Commands and Actions lists.
func update_ui():
	action_editor.update_ui()


func _on_assistant_response(response: String):
	chat_box.add_text(response + "\n")
	
	# action_editor.add_command_list(command_list)


func _on_button_pressed():
	
	var prompt: String = prompt_edit.text
	
	if prompt.length() > 0:
		
		GPTAssistant.submit_prompt(prompt)

