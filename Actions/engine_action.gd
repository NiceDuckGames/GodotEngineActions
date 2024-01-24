@tool
extends Object

## EngineAction is an object that encapsulates
## a list of commands, and handles parsing and
## executing them within the editor.

class_name EngineAction

## The local cache is used the store the return values of commands
## as they are executed. Command params can use a special syntax
## to refer to a previous command's return value
##
## Cache access syntax:
## 
## `$N`          where N is the index of a previous command.
## `$_`          which refers to the previous command's return value.
##
## The keys of the cache are the corresponding command's index
var local_cache: Dictionary = {}

## The list of commands that this action will execute.
## The keys of the command list are the index of the command,
## and the values are the commands themselves, structured like so:
##
## {
##     "command_name": "test_name",
##     "params": [
##         "value1",
##         "value2"
##     ]
## }
var command_list: Dictionary = {}

## The number of commands currently in the action's command list.
## Used to index the commands as they are added.
var num_commands = 0

## The index of the command that is currently being executed.
var current_command_id = 0

## Whether or not the command is paused.
var is_paused: bool = false
## Whether or not the command is scheduled to end execution.
var should_stop: bool = false

signal paused
signal unpause
signal stopped
signal command_complete(command_index)


func _init(commands: Array):
	
	for command in commands:
		append_command(command)


## Appends a single command to the end of this action's command list,
## and allocates space for its return value in the cache
func append_command(command: Dictionary):
	
	command_list[num_commands] = command
	local_cache[num_commands] = null
	
	num_commands += 1


## Iterates the command list, and executes them in order.
## 
## This function is awaitable. 
##
## Each execution of a command waits a set amount of time before
## advancing to the next one so the editor has time to update everything.
func execute_action():
	
	if EngineCommands.is_action_executing(): 
		printerr("Cannot execute more than one EngineAction at a time.")
	
	EngineCommands.begin_action_execution(self)
	
	for command_id in command_list:
		
		current_command_id = command_id
		
		if is_paused:
			emit_signal("paused")
			await unpause
			
		if should_stop:
			emit_signal("stopped")
			return
		
		var command = command_list[current_command_id]
		var params = parse_parameters(command.params)
		
		local_cache[current_command_id] = EngineCommands.callv(command.command_name, params)
		
		await EngineCommands.command_complete
		
		emit_signal("command_complete", current_command_id)
	
	EngineCommands.end_action_execution()


## Schedules the action to pause execution after the next command.
func pause():
	is_paused = true


## Resumes execution if the action is currently paused.
func resume():
	
	if is_paused:
		
		emit_signal("unpause")
		is_paused = false


## Schedules the action to stop execution after the next command.
func stop():
	should_stop = true


func get_current_command() -> Dictionary:
	return command_list[current_command_id]


## Goes through the parameter values for a single command
## and parses out any syntax related to cache access.
func parse_parameters(param_list) -> Array:
	
	var parsed = []
	
	for param in param_list:
		
		if param is String && param.begins_with("$"):
			
			var param_value
			
			if param.length() == 2 && param.ends_with("_"):
				param_value = local_cache[current_command_id - 1]
			
			else:
				param_value = local_cache[param.to_int()]
				
			parsed.push_back(param_value)
		
		elif param is String && param == "<null>":
			
			parsed.push_back(null)
		
		else:
			
			parsed.push_back(param)
	
	return parsed


## Get the command list with param values for this action
func get_command_array() -> Array:
	return command_list.values()
