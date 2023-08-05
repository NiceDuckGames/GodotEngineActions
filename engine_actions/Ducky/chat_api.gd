@tool
extends HTTPRequest

var api_key: String

func _ready() -> void:
	pass

func openai_chat(prompt: String) -> void:
	# Currently this leverages the OpenAI Chat API
	# In the future we will likely want to abstract this to go through
	# our own API which may use a fine-tuned model.
	var data = {
		"model": "gpt-3.5-turbo",
		"max_tokens": 1500,
		"messages": [{
			"role": "system", 
			"content": Prompts.task_mapping_prompt.format({"prompt": prompt})
		}]
	}

	var headers = [
		"Content-Type: application/json",
		# todo: create options UI to set api key
		"Authorization: Bearer %s" % api_key 
	]
	var json = JSON.stringify(data)
	print(data)
	self.request("https://api.openai.com/v1/chat/completions", headers, HTTPClient.METHOD_POST, json)	
