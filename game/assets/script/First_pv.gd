extends Node3D

@export var sensitivity := 0.005
@export_range(-90, 0, 0.1, "radians_as_degrees") var L_rotation: float = deg_to_rad(-90)
@export_range(0, 90, 0.1, "radians_as_degrees") var R_rotation: float = deg_to_rad(90)
@export var pitch_limit: float = deg_to_rad(89)
@onready var cam: Camera3D =$Camera3D_1 #$Camera3D for trail

var pitch := 0.0
var angle := 0.0


func _ready() -> void:
	#print("Camera script loaded!") debug
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		angle = clamp(angle - event.relative.x * sensitivity, L_rotation, R_rotation)
		rotation.y = angle
		pitch = clamp(pitch - event.relative.y * sensitivity, -pitch_limit, pitch_limit)
		cam.rotation.x = pitch
		#print(event.relative.x) debug		
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE	
	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
