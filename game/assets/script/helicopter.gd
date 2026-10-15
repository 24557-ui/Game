extends Node3D

@export var move_speed := 8.0
@export var vertical_speed := 5.0
@export var rotor_speed := 18.0

enum CameraMode { THIRD, FIRST }

@onready var first_camera: Camera3D = $first_pv_camera/Camera3D_1
@onready var third_camera: Camera3D = $third_pv_camera/Camera3D
@onready var rotors: Array[Node3D] = [$Node3D, $Node3D2]

var is_active := false
var camera_mode: CameraMode = CameraMode.THIRD


func _ready() -> void:
	visible = false
	first_camera.current = false
	third_camera.current = false

	visibility_changed.connect(_on_visibility_changed)
	_set_rotor_speed(rotor_speed)
	_set_rotors_spinning(false)


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	var direction := Vector3.ZERO

	if Input.is_action_pressed("w"):
		direction -= global_transform.basis.z
	if Input.is_action_pressed("s"):
		direction += global_transform.basis.z
	if Input.is_action_pressed("a"):
		direction -= global_transform.basis.x
	if Input.is_action_pressed("d"):
		direction += global_transform.basis.x

	if direction != Vector3.ZERO:
		global_position += direction.normalized() * move_speed * delta

	if Input.is_physical_key_pressed(KEY_UP):
		global_position += Vector3.UP * vertical_speed * delta
	if Input.is_physical_key_pressed(KEY_DOWN):
		global_position -= Vector3.UP * vertical_speed * delta


func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed("change_camera"):
		switch_camera_mode((camera_mode + 1) % 2 as CameraMode)

	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func set_helicopter_active(active: bool) -> void:
	is_active = active
	_set_rotors_spinning(active)

	if active:
		switch_camera_mode(CameraMode.THIRD)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		first_camera.current = false
		third_camera.current = false


func switch_camera_mode(mode: CameraMode) -> void:
	camera_mode = mode
	first_camera.current = mode == CameraMode.FIRST
	third_camera.current = mode == CameraMode.THIRD


func _on_visibility_changed() -> void:
	_set_rotors_spinning(visible)


func _set_rotor_speed(speed: float) -> void:
	for rotor in rotors:
		if rotor.has_method("set_rotor_speed"):
			rotor.call("set_rotor_speed", speed)


func _set_rotors_spinning(spinning: bool) -> void:
	for rotor in rotors:
		if spinning:
			if rotor.has_method("start_spin"):
				rotor.call("start_spin")
		else:
			if rotor.has_method("stop_spin"):
				rotor.call("stop_spin")
