tool
extends Node
class_name Syn2D, "res://src/ast/Syncro.svg"

signal id_response(id)
signal mastery_response(response)

export (String) var resource_name
export (bool) var sync_parent_transform = false setget process_physics
export (bool) var is_player = false

var id:String = ""
var my_master = 1 # 1 can be controlled / 0 cannot be controlled

var data = {}
var buffer = []
var last_transform
var start_syncronize = false


###################################################
############### Getter and Setter #################
###################################################


func process_physics(enable):
	sync_parent_transform = enable
	set_physics_process(enable)


###################################################
############### Node functions ####################
###################################################


func _get_configuration_warning():
	if resource_name == "":
		return "resource_name is needed for client syncronization"
	else:
		return ""


func _enter_tree():
	# If enters in the three while the scene is loading
	# waits until the scene asks for syncro initialization
	if Server.loading_scene_step < 2 :
		Server.connect("loading_scene",self,"initialize")
	else:
		initialize(Server.loading_scene_step)


func _exit_tree():
	if self.is_queued_for_deletion():
		remove_from_sync_nodes(true)


###################################################
############### Syn3D functions ##################
###################################################


# Adds the syncro to the list of syncronized nodes
func initialize(step: int):
	if step >= 2:
		id = Server.add_to_sync_nodes(self)


# Manages who controls the node the master can modify data and transform
func ask_mastery(player_id, request: bool):
	if my_master == 1 and request:
		my_master = player_id
		Server.mastery_response(player_id, id, true, my_master)
	elif my_master == player_id and not request:
		my_master = 1
		Server.mastery_response(player_id, id, false, my_master)
	else:
		Server.mastery_response(player_id, id, false, my_master)


# Removes the node from the syncronized nodes
func remove_from_sync_nodes(delete = false):
	Server.remove_from_sync_nodes(self, delete)


# clones the data from and set them in the syncro
func set_sync(new_data, new_transform):
	self.data = new_data
	self.last_transform = new_transform
	get_parent().global_transform = new_transform


# main function that sends the data
func sync_data(is_reliable, variable):
	if my_master <= 1:
		if is_reliable:
			Server.send_sync(id, variable)
		else:
			Server.send_update(id, variable)


# main function that receives the data
# and send them to the relative function to process them
func receive_sync(variable):
	if my_master > 1:
		if variable[0] is int:
			process_update(variable)
		else:
			process_sync(variable)


func get_sync_properties() -> Dictionary:
	return {
		"id":id,
		"is_player": is_player,
		"resource_name": resource_name,
		"sync_parent_transform" : sync_parent_transform,
		"my_master": my_master,
		"data": data,
		"global_transform" : get_parent().global_transform if get_parent() is Spatial else null,
		"parent_path": get_parent().get_path()
	}


###################################################
########## Data syncronization functions ##########
###################################################


# Register variables that have to be maintained syncronized
func register_var(var_name, var_initial_value = null):
	data[var_name] = var_initial_value


# Return the value of the variable that has to be maintained syncronize
func get_(var_name):
	return data[var_name]


# Sets the new value and send the update of the variable
func set_(var_name, new_value):
	data[var_name] = new_value
	sync_data(true, [var_name, new_value])


# Receives updated variables, update the local one and 
# Notify the node that the variable is updated
# notifies the other nodes of the same thing
func process_sync(variable):
	assert(typeof(variable) == TYPE_ARRAY)
	if data.has(variable[0]) and variable[1] != data[variable[0]]:
		data[variable[0]] = variable[1]
		sync_data(true,variable)
		emit_signal("received_sync", variable[0], variable[1])


###################################################
########### Transform syncronization ##############
###################################################


# Sends constant updates of the parent's transform in an unreliable way
func _physics_process(delta):
	if sync_parent_transform and get_parent() is Spatial:
		var tr = get_parent().global_transform
		if tr != last_transform:
			last_transform = tr
			sync_data(false, [OS.get_system_time_msecs(), tr])


# Receives the updated position of the parent_transform and updates it
func process_update(var_value):
	assert(typeof(var_value) == TYPE_ARRAY)
	if buffer.size() == 0 or buffer[-1][0] < var_value[0]:
		buffer.append(var_value)
		if buffer.size() > 1:
			buffer.pop_front()
		get_parent().global_transform = var_value[1]
