@tool
extends Listener


var editor_inspector: EditorInspector

var edited_object: Object = null
var properties_changed: Array = []

# Signal signatures
signal resource_property_changed(edited_object: Object, value: Variant, object_path: String, \
								node_path: String, prop_path: String, property_name: String)


func begin():
	
	editor_inspector = editor_plugin.get_editor_interface().get_inspector()
	
	if !editor_inspector.is_connected("property_edited", self._on_inspector_property_edited):
		editor_inspector.connect("property_edited", self._on_inspector_property_edited)
	if !editor_inspector.is_connected("edited_object_changed", self._on_edited_object_changed):
		editor_inspector.connect("edited_object_changed", self._on_edited_object_changed)
	
	is_listening = true


func end():
	
	is_listening = false


func get_listener_name() -> String:
	
	return "Inspector Listener"


func get_listener_signals() -> Array[Signal]:
	
	var signals: Array[Signal] = [
		resource_property_changed
	]
	
	return signals


func update():
	
	if !is_listening: return
	
	if edited_object is Resource:
		
		for property_name in properties_changed:
			
			var object_path: String = edited_object.resource_path
			var value: Variant = edited_object.get_indexed(property_name)
			var prop_path: String
			
			var edited_node = editor_plugin.get_editor_interface().get_selection().get_selected_nodes()[0]
			
			if !is_instance_valid(edited_node): continue
			
			var node_path = editor_plugin.get_editor_interface().get_edited_scene_root().get_path_to(edited_node)
			
			for prop in edited_node.get_property_list():
				
				var val = edited_node.get_indexed(prop.name)
				
				if val is Resource:
					if val == edited_object:
						prop_path = prop.name
						break
			
			emit_signal("resource_property_changed", [edited_object, value, object_path, node_path, prop_path, property_name])
		
		properties_changed.clear()


func _on_edited_object_changed():
	
	update()
	
	edited_object = get_edited_object()


func _on_inspector_property_edited(property_name: String):
	
	if !properties_changed.has(property_name):
		properties_changed.push_back(property_name)

func get_edited_object():
	
	var inspector_vbox = editor_inspector.get_child(0)
	
	for child in inspector_vbox.get_children():
		if child is VBoxContainer:
			for prop in child.get_children():
				if prop is EditorProperty:
					return prop.get_edited_object()


func is_resource_saved(resource: Resource):
	
	var object_path: String = resource.resource_path
	var split_check = object_path.split("::", false)
	
	if split_check.size() == 1:
		return true
	else:
		return false



