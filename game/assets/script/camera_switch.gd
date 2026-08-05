extends Node3D

@onready var third_pv = $Sojourner/SpringArm3D/Camera3D_3
@onready var first_pv = $first_pv_camera/Camera3D_1


func _ready():
	third_pv.current = true
	first_pv.current = false

func _input(event):
	if event.is_action_pressed("ui_accept"):
		third_pv.current = false
		first_pv.current = true
		#print("The camera view was successfully switched to third person.") for debug
