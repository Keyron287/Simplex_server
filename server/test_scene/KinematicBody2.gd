extends KinematicBody


onready var timer:Timer = $Timer

export (float) var speed = 5
export (float) var change_dir_time = 2

var direction = Vector3.RIGHT


func _physics_process(delta):
	
	if Input.is_key_pressed(KEY_UP):
		direction.x = 1
	if Input.is_key_pressed(KEY_DOWN):
		direction.x = -1
	if Input.is_key_pressed(KEY_RIGHT):
		direction.z = 1
	if Input.is_key_pressed(KEY_LEFT):
		direction.z = -1
	
	move_and_slide(direction * speed * delta)
