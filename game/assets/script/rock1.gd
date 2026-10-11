extends Node3D

var researched: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is VehicleBody3D:
		print("true")
	
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is VehicleBody3D:
		print("false")
