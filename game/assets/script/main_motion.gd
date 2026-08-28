extends VehicleBody3D

@onready var third_pv = $Sojourner/SpringArm3D/Camera3D_3
@onready var first_pv = $first_pv_camera/Camera3D_1
@export var steering_cons:float = 0.5
@export var engine_cons:float = 200




func _ready():
	third_pv.current = true
	first_pv.current = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _input(event):
	
	if event.is_action_pressed("change_camera"):
		if third_pv.current:
			third_pv.current = false
			first_pv.current = true
		else:
			third_pv.current = true
			first_pv.current = false
	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("d"):
		rotation.y += deg_to_rad(20)
	if event.is_action_pressed("s"):
		rotation.y += -deg_to_rad(20)


func _physics_process(delta):
	var turn_input = Input.get_axis("d","a")
	steering = turn_input * steering_cons
	var forward_input = Input.get_axis("s","w")
	engine_force = forward_input * engine_cons
	rotate_y(steering * delta)
	
