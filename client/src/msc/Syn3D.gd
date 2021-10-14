extends Node
class_name Syn3D, "res://src/ast/Syncro.svg"

signal id_response(id)
signal mastery_response(response)
signal received_sync(var_name, var_value)


export (Dictionary) var data = {}
export (bool) var sync_parent_transform = false setget process_physics
export (bool) var is_player = false

var id:String = ""
var is_master = false
var resource_name = ""

var buffer = []
var last_transform


###################################################
############### Getter and Setter #################
###################################################


func process_physics(enable):
	sync_parent_transform = enable
	set_physics_process(enable)


###################################################
############### Node functions ####################
###################################################


func _exit_tree():
	if self.is_queued_for_deletion():
		remove_from_sync_nodes()


###################################################
############### Syncro functions ##################
###################################################


func initialize(new_data):
	self.sync_parent_transform = sync_parent_transform
	self.id = new_data["id"]
	self.is_player = new_data["is_player"]
	self.resource_name = new_data["resource_name"]
	self.sync_parent_transform = new_data["sync_parent_transform"]
	self.is_master = new_data["my_master"] == get_tree().get_network_unique_id()
	self.data = new_data["data"]
	if new_data["global_transform"] != null and get_parent() is Spatial:
		last_transform = get_parent().global_transform
		get_parent().global_transform = new_data["global_transform"]
	Server.add_to_sync_nodes(self)


# Removes the node from the syncronized nodes
func remove_from_sync_nodes():
	Server.remove_from_sync_nodes(self)


func ask_mastery(request: bool):
	Server.ask_mastery(self.id, request)


func receive_mastery(response, current_master):
	is_master = response
	emit_signal("mastery_response", response, current_master)


func sync_data(is_reliable, variable):
	if is_master:
		Server.sync_data(is_reliable, id, variable)


func receive_sync(variable):
	if not is_master:
		if variable[0] is int:
			process_update(variable)
		else:
			process_sync(variable)


###################################################
########## Data syncronization functions ##########
###################################################


## Data syncronization
func register_var(var_name, var_initial_value = null):
	data[var_name] = var_initial_value


func get_(var_name):
	return data[var_name]


func set_(var_name, new_value):
	data[var_name] = new_value
	sync_data(true, [var_name, new_value])


func process_sync(variable):
	prints(data[variable[0]], variable[1])
	assert(typeof(variable) == TYPE_ARRAY)
	if data.has(variable[0]) and variable[1] != data[variable[0]]:
		data[variable[0]] = variable[1]
		emit_signal("received_sync", variable[0], variable[1])


###################################################
########### Transform syncronization ##############
###################################################


#Transform syncronization
func _physics_process(delta):
	if sync_parent_transform and get_parent() is Spatial:
		var tr = get_parent().global_transform
		if tr != last_transform:
			last_transform = tr
			sync_data(false, [OS.get_system_time_msecs(), tr])


func process_update(var_value):
	assert(typeof(var_value) == TYPE_ARRAY)
	if get_parent() is Spatial:
		if buffer.size() == 0 or buffer[-1][0] < var_value[0]:
			buffer.append(var_value)
			if buffer.size() > 4:
				buffer.pop_front()
			_interpolate()
			_extrapolate()
			get_parent().global_transform = var_value[1]


func _interpolate():
	pass


func _extrapolate():
	pass

