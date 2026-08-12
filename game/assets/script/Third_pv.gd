extends SpringArm3D

@export var sensitivity := 0.005
@export_range(-90, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/2
@export_range(0.0, 90, 0.1, "radians_as_degrees") var max_vertical_angle: float = PI/4
@export_range(0.0, 20, 0.1) var spring_length_max: float = 10
@export_range(0.0, 20, 0.1) var spring_length_min: float = 0.5



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= sensitivity * event.relative.x
		rotation.y = wrapf(rotation.y, 0.0, TAU)	
		rotation.x -= sensitivity * event.relative.y
		rotation.x = clamp(rotation.x, min_vertical_angle, max_vertical_angle)
		spring_length = clamp(spring_length, spring_length_min, spring_length_max)	
	if event.is_action_pressed("wheel_up") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			spring_length+=1		
	if event.is_action_pressed("wheel_down") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			spring_length-=1
	'''if event.is_action_pressed("toggle_mouse_capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)'''
			
