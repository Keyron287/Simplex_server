extends Node


func _ready():
	ResourceManager.add_resource("livello_test", "res://test_scene/test.tscn")
	ResourceManager.add_resource("unit_test", "res://test_scene/Test_unit.tscn")
	ResourceManager.add_resource("player_test", "res://test_scene/Test_player.tscn")
	Server.network.connect("connection_succeeded", self, "begin")

func begin():
	Server.player_is_ready()
	yield(Server, "server_message")
	var m = Server.message_buffer.pop_front()
	if m == "choose_character":
		Server.send_message("player_test")
