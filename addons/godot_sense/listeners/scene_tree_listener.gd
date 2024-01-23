@tool
extends Listener


var current_root_node: Node

var current_tree: Array[Dictionary]
var previous_tree: Array[Dictionary]

var listen_interval: float = 1.0

# Signal signatures
signal node_deleted(node_path: String)
signal node_added(node: Node)
signal node_moved(prev_path: String, node: Node)
signal node_type_changed(node_path: String, classname: String)
signal signal_connected(from_path: String, to_path: String, signal_name: String, method_name: String)
signal scene_added(scene_filepath: String, parent_path: String, node_name: String)


func begin():
	
	current_tree.clear()
	previous_tree.clear()
	
	update_tree()
	previous_tree = current_tree.duplicate(true)
	
	is_listening = true


func end():
	
	is_listening = false
	
	current_tree.clear()
	previous_tree.clear()


func get_listener_name() -> String:
	
	return "Scene Tree Listener"


func get_listener_signals() -> Array[Signal]:
	
	var signals: Array[Signal] = [
		node_added,
		node_deleted,
		node_moved,
		node_type_changed,
		signal_connected,
		scene_added
	]
	
	return signals


func update():
	
	if !is_listening: return
	
	update_tree()
	diff_tree()


func node_to_template(node: Node):
	
	if !is_instance_valid(node): return {}
	
	var t = {
		"object_id": node.get_instance_id(),
		"node_name": node.name,
		"class_id": node.get_class(),
		"node_path": current_root_node.get_path_to(node),
		"child_index": node.get_index(),
		"signal_connections": node.get_incoming_connections(),
		"file_path": node.scene_file_path
	}
	
	return t


func diff_tree():
	
	if !is_instance_valid(current_root_node) || has_scene_changed(): return
	
	for prev_node in previous_tree:
		
		if !current_tree_has_node_by_id(prev_node.object_id):
			
			if !current_tree_has_node(prev_node.node_path):
				
				emit_signal("node_deleted", [prev_node.node_path])
		
		if current_tree_has_node_by_id(prev_node.object_id):
			
			var curr_version = get_node_from_current_tree_by_id(prev_node.object_id)
			
			if curr_version.node_path != prev_node.node_path:
				
				emit_signal("node_moved", [prev_node.node_path, current_root_node.get_node(curr_version.node_path)])
		
	for curr_node in current_tree:
		
		var prev_node = get_node_from_previous_tree_by_id(curr_node.object_id)
		
		if previous_tree_has_node(curr_node.node_path):
			
			var prev_version = get_node_from_previous_tree(curr_node.node_path)
			
			if curr_node.object_id != prev_version.object_id:
				
				emit_signal("node_type_changed", [curr_node.node_path, prev_version.class_id, curr_node.class_id])
		
		if prev_node.is_empty():
			
			if !previous_tree_has_node(curr_node.node_path):
			
				if curr_node["file_path"] != current_root_node.scene_file_path && curr_node["file_path"].length() > 0:
					
					var parent_path = get_local_path(current_root_node.get_node(curr_node.node_path).get_parent())
					
					emit_signal("scene_added", [curr_node["file_path"], parent_path, curr_node.node_name])
				
				else:
					
					emit_signal("node_added", [current_root_node.get_node(curr_node.node_path)])
		
		elif curr_node["signal_connections"].size() > prev_node["signal_connections"].size():
			
			var new_connection = get_new_connection(prev_node, curr_node)
			
			if new_connection["signal"].get_object() is Node:
			
				emit_signal("signal_connected", [get_local_path(new_connection["signal"].get_object()), curr_node.node_path, new_connection["signal"].get_name(), new_connection["callable"].get_method()])


func get_local_path(node: Node):
	
	var context = editor_plugin.get_editor_interface().get_edited_scene_root()
	var path = context.get_path_to(node)
	
	return path


func has_scene_changed():
	
	if current_tree.size() == 0 || previous_tree.size() == 0: return false
	
	var curr_root = current_tree[0]
	var prev_root = previous_tree[0]
	
	if curr_root.object_id != prev_root.object_id:
		return true
	
	return false


func get_new_connection(prev_node, curr_node) -> Dictionary:
	
	for conn in curr_node.signal_connections:
		if !prev_node.signal_connections.has(conn):
			return conn
	return {}


func current_tree_has_node(node_path: NodePath) -> bool:
	for node in current_tree:
		if node.node_path == node_path:
			return true
	return false


func current_tree_has_node_by_id(object_id: int) -> bool:
	for node in current_tree:
		if node.object_id == object_id:
			return true
	return false


func previous_tree_has_node(node_path: NodePath) -> bool:
	for node in previous_tree:
		if node.node_path == node_path:
			return true
	return false


func previous_tree_has_node_by_id(object_id: int) -> bool:
	for node in previous_tree:
		if node.object_id == object_id:
			return true
	return false


func get_node_from_current_tree(node_path: NodePath) -> Dictionary:
	for node in current_tree:
		if node.node_path == node_path:
			return node
	return {}


func get_node_from_current_tree_by_id(object_id: int) -> Dictionary:
	for node in current_tree:
		if node.object_id == object_id:
			return node
	return {}


func get_node_from_previous_tree(node_path: NodePath) -> Dictionary:
	for node in previous_tree:
		
		if node.node_path == node_path:
			return node
	return {}


func get_node_from_previous_tree_by_id(object_id: int) -> Dictionary:
	for node in previous_tree:
		if node.object_id == object_id:
			return node
	return {}


func update_tree():
	
	current_root_node = editor_plugin.get_editor_interface().get_edited_scene_root()
	
	if !is_instance_valid(current_root_node): return
	
	previous_tree.clear()
	previous_tree = current_tree.duplicate(true)
	
	current_tree.clear()
	current_tree.push_back(node_to_template(current_root_node))
	current_tree.append_array(get_tree_as_list(current_root_node))


func get_tree_as_list(root_node: Node) -> Array[Dictionary]:
	
	var children: Array[Dictionary] = []
	
	for child in root_node.get_children():
		
		children.push_back(node_to_template(child))
		
		if child.get_child_count() > 0:
			
			var grandchildren = get_tree_as_list(child)
			children.append_array(grandchildren)
		
	return children
