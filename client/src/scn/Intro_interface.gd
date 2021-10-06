extends Control


onready var my_ip = $CenterContainer/VBoxContainer/IP_section
onready var my_port = $CenterContainer/VBoxContainer/door_section
onready var my_warning = $CenterContainer/VBoxContainer/Warning

var next_scene = "res://src/scn/Lobby.tscn"

func _on_Connect_Button_pressed():
	if my_ip.text != "":
		print("my new ip: ",my_ip.text)
		Server.ip = my_ip.text
	if my_port.text != "":
		print("my new port: ", my_port.text)
		Server.port = int(my_port.text)
	Server.network.connect("connection_succeeded", self, "_on_connection_succeeded")
	Server.network.connect("connection_failed", self, "_on_connection_failed")
	Server.connect_to_server()
	get_tree().set_pause(true)


func _on_connection_succeeded():
	my_warning.text = "Successfully connected"
	yield(get_tree().create_timer(0.5),"timeout")
# warning-ignore:return_value_discarded
	get_tree().change_scene(next_scene)


func _on_connection_failed():
	my_warning.text = "Failed to connect"
	get_tree().set_pause(false)

