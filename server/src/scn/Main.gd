extends Control


onready var peer_tree: Tree = $Panel/HSplitContainer/VBoxContainer/Peer
onready var sync_tree: Tree = $Panel/HSplitContainer/VBoxContainer/Syncronizer
onready var server_log: RichTextLabel = $Panel/HSplitContainer/RichTextLabel


func _process(delta):
	if Input.is_key_pressed(KEY_SPACE):
		self.visible = not self.visible


func update_clients(data:Dictionary):
	_update_tree(peer_tree, "Clients", data)


func update_syncs(data:Dictionary):
	_update_tree(sync_tree, "Syncs", data)


func _update_tree(tree:Tree, root_name:String, data:Dictionary):
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, root_name)
	__draw_branch(tree, root, data)


func __draw_branch(tree:Tree, parent:TreeItem, data:Dictionary):
	for k in data.keys():
		var n = tree.create_item(parent)
		n.set_text(0,str(k))
		var d = data[k]
		if typeof(d) == TYPE_DICTIONARY:
			__draw_branch(tree, n, d)
		else:
			n.set_text(1, str(d))


func add_to_log(sender:String, message:String):
	var format = "[%02d:%02d:%02d]"
	var time = OS.get_time()
	time = format % [time["hour"], time["minute"], time["second"]]
	server_log.text += "\n"+time+"  "+sender+" - "+message

