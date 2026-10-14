extends VehicleBody3D

@onready var third_pv = $Sojourner/SpringArm3D/Camera3D_3
@onready var first_pv = $first_pv_camera/Camera3D_1
@export var steering_cons:float = 0.5
@export var engine_cons:float = 200
@export var mini_ca: Camera3D 


enum CameraMode{THIRD, FIRST, MAP}
var current_mode: int = CameraMode.THIRD

func switch_camera_mode(mode: int):
	if mini_ca != null:
		mini_ca.current = false
	third_pv.current = false
	first_pv.current = false
	match mode:
		CameraMode.THIRD:
			third_pv.current = true
		CameraMode.FIRST:
			first_pv.current = true
		CameraMode.MAP:
			if mini_ca != null:
				mini_ca.current = true
			else:
				push_error("mini_ca is not assigned and no ../mini_camera sibling was found.")


func _ready():
	if mini_ca == null:
		mini_ca = get_node_or_null("../mini_camera") as Camera3D
	switch_camera_mode(CameraMode.THIRD)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)		

func _input(event):
	if event.is_action_pressed("change_camera"):
		current_mode = (current_mode + 1) % 2
		switch_camera_mode(current_mode)
	if event.is_action_pressed("map"):
		if current_mode != CameraMode.MAP:
			current_mode = CameraMode.MAP
			switch_camera_mode(CameraMode.MAP)
		else:
			current_mode = CameraMode.THIRD
			switch_camera_mode(CameraMode.THIRD)
	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("d"):
		rotation.y += deg_to_rad(20)
	if event.is_action_pressed("a"):
		rotation.y += -deg_to_rad(20)


func _physics_process(delta):
	var turn_input = Input.get_axis("d","a")
	steering = turn_input * steering_cons
	var forward_input = Input.get_axis("s","w")
	engine_force = forward_input * engine_cons
	rotate_y(steering * delta)
