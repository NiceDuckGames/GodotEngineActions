@tool
extends EditorPlugin

var indicator_res = preload("res://addons/godot_sense/ui/Indicator.tscn")
var indicator: Control
var godot_sense_path = "res://addons/godot_sense/godot_sense.gd"

func _enter_tree():
	
	add_autoload_singleton("GodotSense", godot_sense_path)
	
	indicator = indicator_res.instantiate()
	indicator.setup(self)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, indicator)


func show_indicator():
	indicator.show()


func hide_indicator():
	indicator.hide()


func _exit_tree():
	
	remove_autoload_singleton("GodotSense")
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, indicator)

