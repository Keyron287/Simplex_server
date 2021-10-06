extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1987
var max_players = 10

var sync_nodes: Dictionary = {}
var start_id = 255

var player_info = {}

var server_controls = preload("res://src/scn/Main.tscn").instance()


func _ready():
	add_child(server_controls)
	_get_my_ip()
	start_server()
	update_clients()
	update_syncs()


func update_clients():
	$Main.update_clients(player_info)


func update_syncs():
	$Main.update_syncs(sync_nodes)


func add_to_log(sender:String, message:String):
	$Main.add_to_log(sender, message)


func _log(message):
	add_to_log(self.name, message)


## Connessione al server
func start_server():
	var error = network.create_server(port, max_players)
	if error: _log("Error code: "+ error)
	get_tree().set_network_peer(network)
	
	_log("SERVER STARTED")
	
	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")


func _peer_connected(player_id):
	_log(">>> User " + str(player_id) + " connected")
	player_info[player_id] = {"nickname": "Player_"+str(player_id), "unit": null}
	update_clients()


func _peer_disconnected(player_id):
	_log(">>> User " + str(player_id) + " disconnected")
	player_info.erase(player_id)
	update_clients()
	# Despawna personaggi


func _get_my_ip(result=null, response_code=null, headers=null, body=null):
	if result == null:
		var req = HTTPRequest.new()
		req.name = "ip_req"
		add_child(req)
		req.connect("request_completed", self, "_get_my_ip")
		req.request("https://api.ipify.org")
		return
	elif body != null:
		_log("Public IP: " + body.get_string_from_utf8())
	else:
		_log("Shit happened when retriving ip")
	if has_node("ip_req"):
		remove_child(get_node("ip_req"))


func add_to_sync_nodes(node) -> String:
	var new_id = ""
	for key in sync_nodes.keys():
		if not is_instance_valid(sync_nodes[key]):
			new_id = key
	if new_id == "":
		start_id += 1
		new_id = str(start_id)
	sync_nodes[new_id] = node
	update_syncs()
	return str(new_id)
	# TODO il server chiede ai peer se hanno un corrisettivo sennò lo crea, "in spawn sync"


func remove_from_sync_nodes(node):
	update_syncs()
	sync_nodes.erase(node.id)


func _is_valid_sync(id:String)-> bool:
	if sync_nodes.has(id) and is_instance_valid(sync_nodes[id]):
		return true
	else:
		return false


func _get_id_by_path(node_path:NodePath):
	for id in sync_nodes.keys():
		if _is_valid_sync(id):
			var check_node = sync_nodes[id].get_path() == node_path
			if check_node:
				return id
	return null


remote func ask_id(node_path):
	var player_id = get_tree().get_rpc_sender_id()
	var id = _get_id_by_path(node_path)
	assert(id != null)
	rpc_id(player_id, "return_id", node_path, id)


### Sincronizzazione trasforms
remote func ask_mastery(node_id, request):
	var player_id = get_tree().get_rpc_sender_id()
	if _is_valid_sync(node_id):
		sync_nodes[node_id].ask_mastery(player_id,request)


func mastery_response(player_id, node_name, response, current_master):
	rpc_id(player_id,"receive_mastery", node_name, response, current_master)


remote func receive_sync(node_id, variable):
	if _is_valid_sync(node_id):
		sync_nodes[node_id].receive_sync(variable)
		send_sync(node_id, variable)


remote func receive_update(node_id, variable):
	if _is_valid_sync(node_id):
		sync_nodes[node_id].receive_sync(variable)


func send_sync(node_id, variable):
	rpc_id(0, "receive_sync", node_id, variable)


func send_update(node_id, variable):
	rpc_unreliable_id(0, "receive_sync", node_id, variable)
