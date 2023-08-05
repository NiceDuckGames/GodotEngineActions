@tool
extends Node
class_name Listener


var editor_plugin: EditorPlugin
var is_listening: bool = false

func _init(_editor_plugin: EditorPlugin):
	editor_plugin = _editor_plugin

func begin() -> void: pass
func end() -> void: pass
func update() -> void: pass
func get_listener_name() -> String: return ""
func get_listener_signals() -> Array[Signal]: return []
