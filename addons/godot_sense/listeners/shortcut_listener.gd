@tool
extends Listener


var activated_shortcuts: Array = []

# Signal signatures
signal shortcut_activated(key_code: String, shortcut: String)


func begin():
	is_listening = true


func end():
	is_listening = false


func get_listener_name() -> String:
	
	return "Shortcut Listener"


func get_listener_signals() -> Array[Signal]:
	
	var signals: Array[Signal] = [
		shortcut_activated
	]
	
	return signals


func update():
	
	if !is_listening: return
	
	for shortcut in activated_shortcuts:
		emit_signal("shortcut_activated", shortcut)
	
	activated_shortcuts.clear()


func _input(event):
	
	if !is_listening: return
	
	if event is InputEventKey && event.pressed:
		
		var code = OS.get_keycode_string(event.get_key_label_with_modifiers())
		
		match code:
			
			"Ctrl+S":
				
				activated_shortcuts.push_back([code, "Save"])
