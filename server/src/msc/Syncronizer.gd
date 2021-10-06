extends Node
class_name Syncronizer, "res://src/ast/Syncronizer.svg"

signal id_response(id)
signal mastery_response(response)

var id:String = ""
var my_master = 1 # 1 can be controlled / 0 cannot be controlled
var is_reliable = true


func _enter_tree():
	id = Server.add_to_sync_nodes(self)


func ask_mastery(player_id, request: bool):
	if my_master == 1 and request:
		my_master = player_id
		Server.mastery_response(player_id, id, true, my_master)
	elif my_master == player_id and not request:
		my_master = 1
		Server.mastery_response(player_id, id, false, my_master)
	else:
		Server.mastery_response(player_id, id, false, my_master)


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
