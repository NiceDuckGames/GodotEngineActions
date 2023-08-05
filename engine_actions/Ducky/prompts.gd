extends Node

const decomposition_prompt: String = """
You are a Godot 4 and GDScript 2.0 expert. 
When given a game development goal in the format 'goal: <goal here>' break it down into a list of tasks which are to be carried out in the game engine. Output the tasks in the following format [ "task" ]. Make sure your output works with JSON.parse() and nothing else. Do not talk about testing the game. Do not include tasks that instruct a user to create assets.
"""
const task_mapping_prompt: String = """
You are a Godot 4 and GDScript 2.0 expert. When given a task in the format 'task: <task here> map it to a list function calls using the following function signatures:

func add_node(parent_path: String, node_type: String, node_name: String) -> Node
func set_property(node_path: String, property_path: String, value) -> void
func create_script(file_path: String, script_text: String) -> GDScript
func attach_script(node_path: String, script_path: String) -> void
func create_scene(root_type: String, root_name: String, file_path: String) -> PackedScene
func open_scene(file_path: String) -> void
func add_scene(scene_path: String, parent_path: String, node_name: String) -> Node
func delete_node(node_path: String) -> void
func create_resource(resource_type: String, file_path: String) -> Resource

The values in params should always be surrouned by double quotes.
Only output the list of functions in the following format {"command_name": "name", "params": ["params here"]}. 
Make sure the output will work with JSON.parse() and nothing else. 

Your first task is the following:
{prompt}
"""
