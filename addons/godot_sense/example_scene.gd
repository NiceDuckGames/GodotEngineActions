@tool
extends Node

## This example demonstrates a basic use case of one
## of the default GodotSense listeners. All listener signals
## can be connected to through the GodotSense singleton.
## 
## GodotSense can be activated by pressing the GodotSense
## icon in the top right of the editor. Signals will not
## be emitted unless the icon is activated.

## When the GodotSense icon is activated, changing
## any property in the inspector will emit the
## "property_changed" signal from the plugin listener.


## Change this property in the inspector while GodotSense is active
## to test the plugin.
@export var change_me: bool = false


func _ready():
	
	GodotSense.connect("property_changed", self._on_listener_event)


func _on_listener_event(node: Node, property_path: String, current_value: Variant, property_type: int):
	
	# This filters out changes to this script, just so it doesn't print this source code
	if property_path == "script:source_code" || property_path == "script:script/source": return
	
	print("Property \'" + property_path + "\'" + " changed to: " + str(current_value))
