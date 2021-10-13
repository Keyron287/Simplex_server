## Loads resources stored as name/path record inside
## a dictionary
extends Node
class_name Resource_manager


signal loaded_resource(resource_name, loaded_resource)


var resources = {}

# Adds the resources to the list
func add_resource(resource_name:String, resource_path:String):
	resources[resource_name] = resource_path


# Lists all the resurces in the dictionary
func list_resources():
	var ret: = "Resource_list\n"
	for r in resources.keys():
		ret += r +" : "+resources[r]
	return ret 


# Loads a resource istance, and emits a signal
func get_resource(resource_name):
	if resources.has(resource_name):
		var ins = load(resources[resource_name]).instance()
		emit_signal("loaded_resource", resource_name, ins)
		return ins
