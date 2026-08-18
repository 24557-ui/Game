extends VehicleBody3D

@onready var third_pv = $Sojourner/SpringArm3D/Camera3D_3
@onready var first_pv = $first_pv_camera/Camera3D_1


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

const SPEED = 5.0
const JUMP_VELOCITY = 4.5


'''func _physics_process(delta: float) -> void:
	#print($".".is_on_floor())
	#print(self.position.y)
	# Add the gravity.
	if not $".".is_on_floor():
		velocity += $".".get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and $".".is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	$".".move_and_slide()'''
