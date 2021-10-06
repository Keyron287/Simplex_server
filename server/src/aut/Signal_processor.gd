extends Node


# warning-ignore:unused_argument
func _physics_process(delta):
	var global_update = []
	for node_id in Sync_Manager.sync_nodes.keys():
		var node = Sync_Manager.sync_nodes[node_id]
		if is_instance_valid(node) and node.is_class("Sync_transform") and node.transform_buffer.size() > 0:
			var last_transform = node.get_current_state()
			global_update.append(last_transform)
	Sync_Manager.send_global_update(global_update)
