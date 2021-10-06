extends Syncronizer
class_name Data_sync, "res://src/ast/Data_sync.svg"


# warning-ignore:unused_signal
signal received_sync(var_name, var_value)


export (Dictionary) var data = {}

func _ready():
	is_reliable = true


func register_var(var_name, var_initial_value = null):
	data[var_name] = var_initial_value


func get_(var_name):
	return data[var_name]


func set_(var_name, new_value):
	data[var_name] = new_value
	sync_data([var_name, new_value])


func sync_data(var_name):
	.sync_data([var_name, data[var_name]])


func process_sync(variable):
	assert(typeof(variable) == TYPE_ARRAY)
	if data.has(variable[0]) and variable[1] != data[variable[0]]:
		data[variable[0]] = variable[1]
		.emit_signal("received_sync", variable[0], variable[1])
