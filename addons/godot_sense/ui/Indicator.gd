@tool
extends TextureButton


func _ready():
	
	$ManageListeners.update_list()


func setup(ep: EditorPlugin):
	
	GodotSense.editor_plugin = ep
	GodotSense.setup()
	
	GodotSense.connect("start_listening", self._on_godot_sense_start)
	GodotSense.connect("stop_listening", self._on_godot_sense_stop)


func _on_godot_sense_start():
	self.set_pressed_no_signal(true)

func _on_godot_sense_stop():
	self.set_pressed_no_signal(false)


func _gui_input(event):
	
	if event is InputEventMouseButton:
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			
			var rect = self.get_global_rect()
			rect.position += Vector2(0.0, 80.0)
			
			$PopupMenu.popup(rect)


func _on_toggled(button_pressed):
	
	if button_pressed:
		GodotSense.begin()
	else:
		GodotSense.end()


func _on_popup_menu_index_pressed(index):
	
	$ManageListeners.popup_centered()
