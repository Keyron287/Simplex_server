extends KinematicBody


onready var timer:Timer = $Timer
onready var syn : Syn3D = $Syncro

export (float) var speed = 5
export (float) var change_dir_time = 2

var direction = Vector3.RIGHT


func _ready():
	timer.start(change_dir_time)
	timer.connect("timeout", self, "change_direction")
	syn.register_var("my_color", Color(0,0,0))


func change_direction():
	
	direction *= -1
	change_color(syn.get_("my_color"))


func change_color(color):
	if color == Color(0,0,1):
		syn.set_("my_color", Color(1,0,0))
	else:
		syn.set_("my_color", Color(0,0,1))
	var material = SpatialMaterial.new()
	material.albedo_color = syn.get_("my_color")
	$MeshInstance.set_surface_material(0, material)


func _physics_process(delta):
	move_and_slide(direction * speed * delta)
