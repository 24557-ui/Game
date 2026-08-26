extends CanvasLayer

@onready var camera_3d: Camera3D = $PanelContainer/SubViewportContainer/SubViewport/Camera3D
@export var sojourner: VehicleBody3D

func _process(delta: float) -> void:
	camera_3d.position.x = sojourner.position.x
	camera_3d.position.z = sojourner.position.z
	camera_3d.position.y = 30
