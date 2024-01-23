@tool
extends Window


@onready var item_list: ItemList = $MarginContainer/Panel/VBoxContainer/ScrollContainer
@onready var select_listener_dialog: FileDialog = $MarginContainer/Panel/VBoxContainer/HBoxContainer/AddListener/FileDialog

var listener_icon = preload("res://addons/godot_sense/ui/GodotSenseIconPressed.png")


func _ready():
	
	update_list()


func update_list():
	
	item_list.clear()
	
	for listener in GodotSense.listener_priority_queue:
		
		item_list.add_item(listener.get_listener_name(), listener_icon, true)


func _on_add_listener_pressed():
	
	select_listener_dialog.popup_centered()


func _on_delete_listener_pressed():
	
	var selected_item_index: int = item_list.get_selected_items()[0]
	
	if !selected_item_index:
		printerr("No listener is selected.")
	
	var listener = GodotSense.get_listener(selected_item_index)
	GodotSense.deregister_listener(listener)
	
	update_list()


func _on_file_dialog_file_selected(path):
	
	var script: Resource = load(path)
	
	if !(script is Script): return
	
	var instance = script.new(get_parent().editor_plugin)
	
	if instance is Listener:
		
		GodotSense.register_listener(instance, GodotSense.listener_priority_queue.size())
	
	update_list()


func _on_close_requested():
	hide()


func _on_size_changed():
	$MarginContainer.size = self.size
