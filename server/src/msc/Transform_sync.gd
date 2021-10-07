## Transform_sync automatically syncronize the transform of his parent
## each _physic_process iteration

extends Syncronizer
class_name Transform_sync, "res://src/ast/Transform_sync.svg"


var buffer = []
var last_transform
var freq_counter = 0


func _ready():
	is_reliable = false
	last_transform = get_parent().global_transform


func _physics_process(delta):
	var tr = get_parent().global_transform
	if tr != last_transform:
		last_transform = tr
		.sync_data([OS.get_system_time_msecs(), get_parent().global_transform])


# warning-ignore:unused_argument
func process_sync(var_value):
	assert(typeof(var_value) == TYPE_ARRAY)
	if buffer.size() == 0 or buffer[-1][0] < var_value[0]:
		buffer.append(var_value)
		if buffer.size() > 1:
			buffer.pop_front()
		get_parent().global_transform = var_value[1]
