extends Node


var ready_players


func _enter_tree():
	Server.connect("server_booting", self, "start_game")


func _ready():
	ResourceManager.add_resource("livello_test", "res://test_scene/test.tscn")
	ResourceManager.add_resource("unit_test", "res://test_scene/Test_unit.tscn")
	ResourceManager.add_resource("player_test", "res://test_scene/Test_player.tscn")


func start_game(step):
	if step == Server.server_boot_up_steps.SERVER_ACTIVE:
		# Waits_for players
		Server.ask_ready()
		ready_players = 1
		while ready_players > 0:
			yield(Server,"player_ready")
			ready_players -= 1
		yield(get_tree().create_timer(2), "timeout")
		# Changes the scene
		yield(Server.load_scene("livello_test"), "completed")
		Server.start_current_scene()

