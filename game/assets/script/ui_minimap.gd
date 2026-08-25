extends CanvasLayer

@onready var camera_3d: Camera3D = $PanelContainer/SubViewportContainer/SubViewport/Camera3D
@export var sojourner: VehicleBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	camera_3d.position.x = sojourner.position.x
	camera_3d.position.z = sojourner.position.z
	camera_3d.position.y = 30
