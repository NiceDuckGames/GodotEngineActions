@tool
extends Node

var editor_plugin: EditorPlugin

var listener_priority_queue: Array[Listener] = []

var is_listening: bool = false
var update_interval: float = 0.25

var file_system_listener_path = preload("res://addons/godot_sense/listeners/file_system_listener.gd")
var inspector_listener_path = preload("res://addons/godot_sense/listeners/inspector_listener.gd")
var scene_tree_listener_path = preload("res://addons/godot_sense/listeners/scene_tree_listener.gd")
var selection_listener_path = preload("res://addons/godot_sense/listeners/selection_listener.gd")
var shortcut_listener_path = preload("res://addons/godot_sense/listeners/shortcut_listener.gd")


signal start_listening
signal stop_listening


func begin():
	
	for listener in listener_priority_queue:
		listener.begin()
	
	is_listening = true
	
	emit_signal("start_listening")


func end():
	
	for listener in listener_priority_queue:
		listener.end()
	
	is_listening = false
	
	emit_signal("stop_listening")


func _process(delta):
	update()


func update():
	
	if !is_listening: return
	
	for listener in listener_priority_queue:
		
		listener.update()


func setup():
	
	register_listener(file_system_listener_path.new(editor_plugin), 0)
	register_listener(scene_tree_listener_path.new(editor_plugin), 1)
	register_listener(selection_listener_path.new(editor_plugin), 2)
	register_listener(inspector_listener_path.new(editor_plugin), 3)
	register_listener(shortcut_listener_path.new(editor_plugin), 4)


func register_listener(listener: Listener, priority: int):
	
	var listener_events: Array[Signal] = listener.get_listener_signals()
	
	for sig in listener_events:
		
		if !is_signal_bound(sig):
			
			sig.connect(_on_listener_event.bind(sig.get_name()))
			
			if self.has_user_signal(sig.get_name()): continue
			
			add_user_signal(sig.get_name())
	
	listener_priority_queue.insert(priority, listener)
	
	add_child(listener)


func deregister_listener(listener: Listener):
	
	var listener_events: Array[Signal] = listener.get_listener_signals()
	
	for sig in listener_events:
		
		if is_signal_bound(sig):
			
			sig.disconnect(_on_listener_event)
	
	listener_priority_queue.erase(listener)
	
	listener.queue_free()


func get_listener(index: int) -> Listener:
	
	if listener_priority_queue.size() > 0 && abs(index) < listener_priority_queue.size():
		
		return listener_priority_queue[index]
	
	return null


func is_signal_bound(sig: Signal) -> bool:
	
	var connections = sig.get_connections()
	
	for conn in connections:
		if conn.callable.get_object() == self:
			return true
	
	return false


func _on_listener_event(args: Array, signal_name: StringName):
	
	var sigs: Array[Dictionary] = get_signal_connection_list(signal_name)
	
	var emit_with_args: Callable = emit_signal.bindv(args)
	emit_with_args.call(signal_name)

