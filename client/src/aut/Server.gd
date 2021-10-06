extends Node
class_name Server_interface


var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1987

var sync_nodes = {}
var waiting_id = {}

## Connection to server
func connect_to_server():
	network.create_client(ip,port)
	get_tree().set_network_peer(network)
	
	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("connection_failed", self, "_on_connection_failed")


func _on_connection_succeeded():
	print(">>> Successfully connected")


func _on_connection_failed():
	print(">>> Failed to connect")


### Syncronization manager
func add_to_sync_nodes(node):
	if node.id == "":
		waiting_id[node.get_path()] = node
		rpc_id(1, "ask_id", node.get_path())
	else:
		sync_nodes[node.id] = node 


func return_id(node_path, id):
	sync_nodes[id] = waiting_id[node_path]
	waiting_id.erase(node_path)
	sync_nodes[id].receive_id(id)


func remove_from_sync_nodes(node):
	sync_nodes.erase(node.id)


func _is_valid_sync(id:String)-> bool:
	if sync_nodes.has(id) and is_instance_valid(sync_nodes[id]):
		return true
	else:
		return false


func ask_mastery(node_id, request: bool):
	rpc_id(1, "ask_mastery", node_id, request)


remote func receive_mastery(node_id, response, current_master):
	if _is_valid_sync(node_id):
		sync_nodes[node_id].receive_mastery(response, current_master)


### Syncronization functions ###
func sync_data(reliable, id, variable):
	if reliable:
		rpc_id(1, "receive_sync", id, variable)
	else:
		rpc_unreliable_id(1, "receive_update", id, variable)


remote func receive_sync(id, variable):
	sync_nodes[id].receive_sync(variable)
