extends KinematicBody


onready var timer:Timer = $Timer

export (float) var speed = 5
export (float) var change_dir_time = 2

var direction = Vector3.RIGHT


func _ready():
	timer.start(change_dir_time)
	timer.connect("timeout", self, "change_direction")


func change_direction():
	direction *= -1


func _physics_process(delta):
	move_and_slide(direction * speed * delta)
