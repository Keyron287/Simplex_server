extends KinematicBody


onready var timer:Timer = $Timer

export (float) var speed = 100
export (float) var change_dir_time = 2

var direction = Vector3.ZERO


func _physics_process(delta):
	
	direction = Vector3.ZERO
	
	if Input.is_key_pressed(KEY_UP):
		direction.z = clamp(direction.x-1,-1,1)
	if Input.is_key_pressed(KEY_DOWN):
		direction.z = clamp(direction.x+1,-1,1)
	if Input.is_key_pressed(KEY_RIGHT):
		direction.x = clamp(direction.x+1,-1,1)
	if Input.is_key_pressed(KEY_LEFT):
		direction.x = clamp(direction.x-1,-1,1)
	direction = direction.normalized()
	
	move_and_slide(direction * speed * delta)
