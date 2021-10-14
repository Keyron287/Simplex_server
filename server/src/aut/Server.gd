extends Node

signal server_booting(step)
signal loading_scene(step)
signal client_message(sender, message)
signal player_ready(sender)


var network = NetworkedMultiplayerENet.new()
var port = 1987
var max_players = 10

var sync_nodes: Dictionary = {}
var start_id = 255

enum server_boot_up_steps {ADD_CONTROLS, GET_IP, START_SERVER, SERVER_ACTIVE}
enum loading_scene_steps {LOAD_SERVER_MAP, LOAD_CLIENT_MAP, PICK_SERVER_SYNCRO, SPAWN_CLIENT_SYNCRO, LOADING_FINISHED}

var server_status = {
	"server_booting": -1,
	"loading_scene": -1
}

var player_info = {}

var server_controls = preload("res://src/scn/Main.tscn").instance()


###################################################
###################### Main #######################
###################################################


func _ready():
	# Adds the interface to the server
	add_child(server_controls)
	_step_signal("server_booting", server_boot_up_steps.ADD_CONTROLS)
	
	# get_the ip via http_request
	_get_my_ip()
	_step_signal("server_booting", server_boot_up_steps.GET_IP)
	
	# starts the server
	start_server()
	_step_signal("server_booting", server_boot_up_steps.START_SERVER)
	
	# updates interface
	update_clients()
	update_syncs()
	
	# notifies the server is ready to everyone and that they can start
	_step_signal("server_booting", server_boot_up_steps.SERVER_ACTIVE)


###################################################
################ Utility functions ################
###################################################


func _step_signal(signal_name, step):
	emit_signal(signal_name, step)
	server_status[signal_name] = step


func update_clients():
	$Server_interface.update_clients(player_info)


func update_syncs():
	$Server_interface.update_syncs(sync_nodes)


func add_to_log(sender:String, message:String):
	$Server_interface.add_to_log(sender, message)


func _log(message):
	add_to_log(self.name, message)


###################################################
############### Server connection #################
###################################################


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
		_log("Public IP: " + body.get_string_from_utf8()+" : "+str(port))
	else:
		_log("Shit happened when retriving ip")
	if has_node("ip_req"):
		remove_child(get_node("ip_req"))


###################################################
############# Sync nodes management ###############
###################################################


func add_to_sync_nodes(node) -> String:
	var new_id = ""
	for key in sync_nodes.keys():
		if not is_instance_valid(sync_nodes[key]):
			new_id = key
	if new_id == "":
		start_id += 1
		new_id = "%04d" % start_id
	sync_nodes[new_id] = node
	update_syncs()
	return str(new_id)


func remove_from_sync_nodes(node, delete):
	sync_nodes.erase(node.id)
	rpc_id(0, "remote_remove_sync", node.id, delete)
	update_syncs()


func _is_valid_sync(id:String)-> bool:
	if sync_nodes.has(id) and is_instance_valid(sync_nodes[id]):
		return true
	else:
		return false


func sync_of(node):
	for c in node.get_children():
		if c is Syn3D or c is Syn2D:
			return c
	assert(false, "No Syncro node in "+ node.name)


func is_syncro(node) -> bool:
	for c in node.get_children():
		if c is Syn3D or c is Syn2D:
			return true
	return false


###################################################
########## Change scene and sync spawn ############
###################################################


func load_scene(scene_name):
	server_status["loading_scene"] = -1
	_log("Loading new scene")
	# Load the scene on the server and pause it to load everything correctly
	var scene = ResourceManager.get_resource(scene_name)
	#var scene = ResourceManager.get_instance(scene_name)
	#assert(is_instance_valid(scene), "Invalid scene instance")
	get_tree().change_scene(scene)
	get_tree().paused = true
	_log("Loaded server map")
	_step_signal("loading_scene", loading_scene_steps.LOAD_SERVER_MAP)
	
	# Asks to clients to load the same scene
	rpc_id(0, "change_scene", scene_name)
	_log("Notified to child to change scene")
	_step_signal("loading_scene", loading_scene_steps.LOAD_CLIENT_MAP)
	
	# Whaits the clients that everyone confirms the load
	_log("Wait for clients to finish load scene")
# warning-ignore:unused_variable
	for n in range(player_info.keys().size()):
		yield(self,"player_ready")
	
	# Notifies all the syncro to register themselves and pick an id
	_log("Picking syncro nodes")
	_step_signal("loading_scene", loading_scene_steps.PICK_SERVER_SYNCRO)
	
	# Spawns every syncro in the client scene
	_log("Spawn syncro nodes in clients")
	_step_signal("loading_scene", loading_scene_steps.SPAWN_CLIENT_SYNCRO)
	for n in sync_nodes.keys():
		var syn:Syn3D = sync_nodes[n]
		spawn_sync_client(syn.get_sync_properties())
	
	# Notifies everyone that the scene is finisced to load
	_log("Scene loading complete")
	_step_signal("loading_scene", loading_scene_steps.LOADING_FINISHED)


func start_current_scene():
	# Tell everyone that the scene can begin
	_log("Starting current scene")
	rpc_id(0, "start_current_scene")
	get_tree().paused = false


func spawn_sync_server(unit_type, unit_transform, is_master = 1, parent_path = false) -> Node:
	# Gets instance from Resouce_manager and the current scene
	var unit = ResourceManager.get_instance(unit_type)
	var parent = get_tree().current_scene
	
	# If parent path is not null add the child under the parent path
	# else under the current_scene node
	if parent_path:
		var check = get_node(parent_path)
		if is_instance_valid(check):
			parent = check
	parent.add_child(unit)
	
	# Syncronizes the transform and the data with the given data 
	unit.global_tranform = unit_transform
	sync_of(unit).my_master = is_master
	return unit


func spawn_sync_client(sync_property):
	rpc_id(0, "spawn_sync", sync_property)


func spawn_sync_all(unit_type, unit_transform, is_master = 1, parent_path = false):
	var unit = spawn_sync_server(unit_type, unit_transform, is_master, parent_path)
	var unit_sync:Syn3D = sync_of(unit)
	spawn_sync_client(unit_sync.get_sync_properties())


###################################################
############# Node mastery management #############
###################################################


remote func ask_mastery(node_id, request):
	var player_id = get_tree().get_rpc_sender_id()
	if _is_valid_sync(node_id):
		sync_nodes[node_id].ask_mastery(player_id,request)


func mastery_response(player_id, node_name, response, current_master):
	rpc_id(player_id,"receive_mastery", node_name, response, current_master)


###################################################
############## Messaging functions ################
###################################################


func send_message(client_id = 0, message = ""):
	rpc_id(client_id, "receive_message", message)


remote func receive_message(message):
	emit_signal("client_message", get_tree().get_rpc_sender_id(), message)


func ask_ready():
	rpc_id(0, "ask_ready")


remote func player_is_ready():
	emit_signal("player_ready", get_tree().get_rpc_sender_id())


###################################################
############ Syncronization functions #############
###################################################


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
