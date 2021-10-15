extends KinematicBody


onready var timer:Timer = $Timer
onready var syn : Syn3D = $Syncro

export (float) var speed = 5
export (float) var change_dir_time = 2

var direction = Vector3.RIGHT


func _ready():
	syn.connect("received_sync", self, "change_color")


func change_color(var_name, color):
	print(var_name, color)
	if var_name == "my_color":
		syn.set_("my_color", color)
		var material = SpatialMaterial.new()
		material.albedo_color = syn.get_("my_color")
		$MeshInstance.set_surface_material(0, material)

