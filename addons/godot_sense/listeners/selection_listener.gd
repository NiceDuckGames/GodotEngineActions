@tool
extends Listener

var editor_interface: EditorInterface

var current_selection: EditorSelection:
	set = set_selection, get = get_selection

var previous_values: Dictionary = {}

var listen_interval: float = 0.25
var listen_timer: SceneTreeTimer = null

# Signal signatures
signal selection_changed(current_selection: EditorSelection)
signal property_changed(node: Node, property_path: String, current_value: Variant, property_type: int)
signal class_changed(node_path: String, new_class: String)


func begin():
	
	editor_interface = editor_plugin.get_editor_interface()
	
	update_selection()
	check_properties(false)
	
	if !current_selection.is_connected("selection_changed", self._on_editor_selection_changed):
		current_selection.connect("selection_changed", self._on_editor_selection_changed)
	
	is_listening = true


func end():
	
	is_listening = false


func get_listener_name() -> String:
	
	return "Selection Listener"


func get_listener_signals() -> Array[Signal]:
	
	var signals: Array[Signal] = [
		selection_changed,
		property_changed
	]
	
	return signals


func update():
	
	if !is_listening: return
	
	check_properties(true)


func set_selection(selection: EditorSelection):
	current_selection = selection


func get_selection():
	return current_selection


func _on_editor_selection_changed():
	
	update_selection()
	check_properties(false)


func update_selection():
	
	current_selection = editor_interface.get_selection()
	
	previous_values.clear()
	
	for node in current_selection.get_selected_nodes():
		
		previous_values[node.get_instance_id()] = {}
		
		for node_property in node.get_property_list():
			
			if node_property.usage & 4 == 0: continue
			
			var node_property_path = node_property.name
			var type_hint = node_property.hint_string.split(",")
			
			if type_hint[0].length() > 0 && ClassDB.class_exists(type_hint[0]):
				
				if ClassDB.get_parent_class(type_hint[0]) == "Resource":
					
					var res: Resource = node.get_indexed(node_property_path)
					
					if res != null:
						
						for res_property in res.get_property_list():
							
							var res_property_path = res_property.name
							var indexed_property_path = node_property_path + ":" + res_property_path
							
							previous_values[node.get_instance_id()][indexed_property_path] = res.get_indexed(indexed_property_path)
			
			previous_values[node.get_instance_id()][node_property_path] = node.get_indexed(node_property_path)
	
	emit_signal("selection_changed", [current_selection])


func check_properties(emit: bool):
	
	for node_id in previous_values:
		
		if !is_instance_id_valid(node_id): continue
		
		var node = instance_from_id(node_id)
		
		for property_path in previous_values[node_id]:
			
			var previous_value = previous_values[node_id][property_path]
			var current_value: Variant = node.get_indexed(property_path)
			
			# `Object.get_indexed()` returns an error String if the property instance is invalid
			if current_value is String && current_value == "Instance base is null.":
				update_selection()
				return
			
			if previous_value != current_value:
				
				var property_type: int
				
				if current_value is Object || current_value == null:
					property_type = TYPE_OBJECT
				
				else:
					property_type = typeof(current_value)
				
				previous_values[node_id][property_path] = current_value
				
				if emit:
					emit_signal("property_changed", [node, property_path, current_value, property_type])
				
