extends Syncronizer
class_name Transform_sync, "res://src/ast/Transform_sync.svg"

const oldest = 0
const last = 1
const interpolate = 1
const extrapolate = 2

var buffer = []

func _ready():
	is_reliable = false


func sync_transform():
	.sync_data([OS.get_system_time_in_msec(),get_parent().global_transform])


# warning-ignore:unused_argument
func process_sync(var_value):
	assert(typeof(var_value) == TYPE_ARRAY)
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
