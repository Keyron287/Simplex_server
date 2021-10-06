extends Node
class_name Syncronizer, "res://src/ast/Syncronizer.svg"

signal id_response(id)
signal mastery_response(response)

var id:String = ""
var is_master = false
var is_reliable = true


func _enter_tree():
	Server.add_to_sync_nodes(self)


func receive_id(new_id):
	id = new_id
	emit_signal("id_response", new_id)


func ask_mastery(request: bool):
	Server.ask_mastery(self.id, request)


func receive_mastery(response, current_master):
	is_master = response
	emit_signal("mastery_response", response, current_master)


func remove_from_sync_nodes():
	Server.remove_from_sync_nodes(self)


func sync_data(variable):
	if is_master:
		if is_reliable:
			Server.sync_data(true, id, variable)
		else:
			Server.sync_data(false, id, variable)


func receive_sync(variable):
	if not is_master:
		process_sync(variable)


func process_sync(variable):
	pass
