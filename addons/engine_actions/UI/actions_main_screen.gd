@tool
extends Control

@onready var action_editor: MarginContainer = $Actions


## Called by the EngineActions plugin script when the
## MainScreen instance is instantiated. Acts as a
## pass-through for the EditorPlugin reference.
func setup(editor_plugin: EditorPlugin):
	
	EngineCommands.editor_interface = editor_plugin.get_editor_interface()
	ActionRecorder.setup(editor_plugin)


## Update the ui elements of the action editor.
## Refreshes the editor's Commands and Actions lists.
func update_ui():
	action_editor.update_ui()
