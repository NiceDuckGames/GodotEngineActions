@tool
extends TextureButton


func _input(event):
	
	if event is InputEventKey && event.pressed:
		
		var code = OS.get_keycode_string(event.get_key_label_with_modifiers())
		
		match code:
			
			"Shift+Ctrl+Space":
				
				if ActionRecorder.is_recording:
					
					ActionRecorder.stop_recording()
					self.set_pressed_no_signal(false)
				else:
					
					ActionRecorder.start_recording()
					self.set_pressed_no_signal(true)


func _on_toggled(pressed):
	if pressed:
		
		ActionRecorder.start_recording()
	else:
		
		ActionRecorder.stop_recording()
