extends Node
class_name Server_interface


signal server_message(message)
signal is_player_ready


var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1987

var sync_nodes = {}
var waiting_id = {}

var message_buffer = []


###################################################
############### Server connection #################
###################################################


func connect_to_server():
	network.create_client(ip,port)
	get_tree().set_network_peer(network)
	
	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("connection_failed", self, "_on_connection_failed")


func _on_connection_succeeded():
	print(">>> Successfully connected")


func _on_connection_failed():
	print(">>> Failed to connect")


###################################################
############# Sync nodes management ###############
###################################################


func add_to_sync_nodes(node):
	sync_nodes[node.id] = node 


func remove_from_sync_nodes(node, delete = false):
	sync_nodes.erase(node.id)
	if delete:
		node.queue_free()


remote func remote_remove_sync(node_id, delete):
	remove_from_sync_nodes(sync_nodes[node_id], delete)


func _is_valid_sync(id:String)-> bool:
	if sync_nodes.has(id) and is_instance_valid(sync_nodes[id]):
		return true
	else:
		return false


func sync_of(node):
	for c in node.get_children():
		if c is Syn3D:
			return c
	assert(false, "No Syncro node in "+ node.name)


func is_syncro(node) -> bool:
	for c in node.get_children():
		if c is Syn3D:
			return true
	return false


###################################################
########## Change scene and sync spawn ############
###################################################


remote func change_scene(scene_name):
	print("change_scene")
	var scene = ResourceManager.get_resource(scene_name)
	get_tree().change_scene(scene)
	get_tree().set_pause(true)
	player_is_ready()


remote func start_current_scene():
	print("start current scene")
	if 1 == get_tree().get_rpc_sender_id():
		get_tree().set_pause(false)


remote func spawn_sync(syn_par: Dictionary):
	print("spawn: ",syn_par)
	if 1 == get_tree().get_rpc_sender_id():
		var unit = ResourceManager.get_instance(syn_par["resource_name"])
		var parent = get_node(syn_par["parent_path"])
		assert(is_instance_valid(parent), str(syn_par["parent_path"]) + " is not a valid path")
		parent.add_child(unit)
		sync_of(unit).initialize(syn_par)


###################################################
############# Node mastery management #############
###################################################


func ask_mastery(node_id, request: bool):
	rpc_id(1, "ask_mastery", node_id, request)


remote func receive_mastery(node_id, response, current_master):
	if _is_valid_sync(node_id):
		sync_nodes[node_id].receive_mastery(response, current_master)


###################################################
############## Messaging functions ################
###################################################


func send_message(message):
	rpc_id(1, "receive_message", message)


remote func receive_message(message):
	message_buffer.append(message)
	emit_signal("server_message", message)


remote func ask_ready():
	emit_signal("is_player_ready")


func player_is_ready():
	rpc_id(1, "player_is_ready")


###################################################
############ Syncronization functions #############
###################################################


func sync_data(reliable, id, variable):
	if reliable:
		rpc_id(1, "receive_sync", id, variable)
	else:
		rpc_unreliable_id(1, "receive_update", id, variable)


remote func receive_sync(id, variable):
	if sync_nodes.has(id):
		sync_nodes[id].receive_sync(variable)
