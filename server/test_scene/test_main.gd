extends Node

var ready_players


func _enter_tree():
	Server.connect("server_booting", self, "start_game")
	Server.connect("client_message", self, "client_response")


func client_response(id, message):
	pass


func wait_for_players():
	Server.ask_ready()
	ready_players = 0
	while ready_players < Server.player_info.keys().size():
		yield(Server,"player_ready")
		ready_players += 1


func start_game(step):
	if step == Server.server_boot_up_steps.SERVER_ACTIVE:
		# Waits_for players
		wait_for_players()
		# Changes the scene
		Server.load_scene("test")
		while Server.server_status["loading_scene"] < Server.loading_scene_steps.LOADING_FINISHED:
			yield(Server,"loading_scene")
	
