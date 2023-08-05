@tool
extends Node

var action_queue: Array[EngineAction] = []
var openai_config: Dictionary = {}

signal assistant_response(response: String)

var test_act: Array = []

func _ready():
	openai_config = load_openai_config()
	ChatAPI.api_key = openai_config["apikey"]
	ChatAPI.request_completed.connect(self._on_chat_request_completed)


func load_openai_config(config_path: String = "res://addons/engine_actions/Ducky/config.json") -> Dictionary:
	var fa: FileAccess = FileAccess.open(config_path, FileAccess.READ)
	
	var file_str = fa.get_as_text()
	var config = GDVN.parse_string(file_str)
	
	fa.close()
	
	return config


## This function is awaitable
func submit_prompt(prompt: String) -> void:
	
	if prompt.begins_with("action: "):
		
		var prompt_split = prompt.split(": ")
		var action_name = prompt_split[1]
		
		var action: EngineAction = EngineActionDB.get_engine_action(action_name)
		await action.execute_action()
	
	else:
		ChatAPI.openai_chat(prompt)


func _on_chat_request_completed(result, response_code, headers, body) -> void:
	var res_data = JSON.parse_string(body.get_string_from_utf8())
	var command_list = GDVN.parse_string(res_data["choices"][0]["message"]["content"])
	
	print(res_data)
	print(JSON.stringify(GDVN.parse_string(res_data["choices"][0]["message"]["content"]), " "))
	
	var action: EngineAction = EngineAction.new(command_list)
	action.execute_action()
	
