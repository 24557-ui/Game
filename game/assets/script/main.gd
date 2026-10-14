extends Node3D
@onready var research_cutscene: Control = $CanvasLayer/research_cutscene
@onready var research_ui = $CanvasLayer/research_ui
@onready var research_button_do = $CanvasLayer/research_ui/do
@onready var label_do = $CanvasLayer/research_ui/Label
@onready var research_button_notdo = $"CanvasLayer/research_ui/not do"
@onready var rover: VehicleBody3D = $rover
@onready var equipment: Node3D = $rover/equipment
@onready var equipment_detection_area: Area3D = $rover/equipment/EquipmentDetectionArea
@onready var research_cutscene_player: AnimationPlayer = $ResearchCutsceneAnimationPlayer
@onready var scan_cutscene_camera: Camera3D = $rover/ScanCutsceneCamera
@onready var label_tech_point: Label = $CanvasLayer/Label_TP
@onready var opening_screen: Control = $CanvasLayer/OpeningScreen
@onready var start_button: Button = $CanvasLayer/OpeningScreen/StartButton
@onready var introduction_button: Button = $CanvasLayer/OpeningScreen/IntroductionButton
@onready var introduction_screen: Control = $CanvasLayer/IntroductionScreen
@onready var introduction_back_button: Button = $CanvasLayer/IntroductionScreen/IntroductionBackButton
@onready var help_button: Button = $CanvasLayer/HelpButton
@onready var help_panel: Control = $CanvasLayer/HelpPanel
@onready var help_close_button: Button = $CanvasLayer/HelpPanel/Panel/HelpCloseButton
@onready var reset_button: Button = $CanvasLayer/ResetButton
@onready var game_end_popup: AcceptDialog = $CanvasLayer/GameEndPopup
@onready var perseverance_body: Node3D = $rover/Perseverance
@onready var sojourner_body: Node3D = $rover/Sojourner
@onready var equipment_cylinder: Node3D = $rover/equipment/Cylinder
@onready var equipment_arm: Node3D = $rover/equipment/arm2
@onready var helicopter: Node3D = $Ingenuity
@onready var helicopter_button: Button = $CanvasLayer/HelicopterButton
@onready var equipment_scan_particles: GPUParticles3D = $rover/equipment/GPUParticles3D
@onready var upgraded_equipment_scan_particles: GPUParticles3D = $rover/equipment/GPUParticles3D_Upgraded

@onready var first_stage_wheels: Array[Node3D] = [
	$rover/VehicleWheel3D/wheel,
	$rover/VehicleWheel3D2/wheel,
	$rover/VehicleWheel3D4/wheel,
	$rover/VehicleWheel3D5/wheel,
	$rover/VehicleWheel3D3/wheel,
	$rover/VehicleWheel3D6/wheel,
]
@onready var second_stage_wheels: Array[Node3D] = [
	$rover/VehicleWheel3D/wheel2,
	$rover/VehicleWheel3D2/wheel2,
	$rover/VehicleWheel3D4/wheel2,
	$rover/VehicleWheel3D5/wheel2,
	$rover/VehicleWheel3D3/wheel2,
	$rover/VehicleWheel3D6/wheel2,
]
@onready var wheel_holders: Array[Node3D] = [
	$rover/VehicleWheel3D,
	$rover/VehicleWheel3D2,
	$rover/VehicleWheel3D4,
	$rover/VehicleWheel3D5,
	$rover/VehicleWheel3D3,
	$rover/VehicleWheel3D6,
]

# The six Perseverance axle centers, measured from its suspension endpoints.
# Order matches wheel_holders / second_stage_wheels.
var first_stage_wheel_positions: Array[Vector3] = []
var second_stage_wheel_positions: Array[Vector3] = [
	Vector3(0.9014739, -0.4891646, 0.8620539),
	Vector3(0.9014739, -0.4618273, 0.3317768),
	Vector3(-0.9014739, -0.4891646, 0.8620539),
	Vector3(-0.9014739, -0.4891646, -1.0554416),
	Vector3(0.9014739, -0.4891646, -1.0554416),
	Vector3(-0.9014739, -0.4618273, 0.3317768),
]

const ROVER_UPGRADE_TECH_POINT := 25
const GAME_END_TECH_POINT := 50
var rover_upgrade_applied := false
var game_end_popup_shown := false
var helicopter_mode := false
var tech_point: int = 0
var current_rock: Node3D = null
var research_prompt: String
var scanning_rock: Node3D = null
var rover_process_mode_before_cutscene: int = Node.PROCESS_MODE_INHERIT
var rover_process_mode_before_opening: int = Node.PROCESS_MODE_INHERIT
var camera_before_research_cutscene: Camera3D = null
var initial_rover_transform: Transform3D

func _get_rock_from_detection_body(body: Node3D) -> Node3D:
	var rock := body.get_parent() as Node3D
	if rock != null and rock.get("researched") != null:
		return rock
	return null

'''func _on_equipment_detection_body_entered(_body: Node3D) -> void:
	_refresh_research_detection()

func _on_equipment_detection_body_exited(_body: Node3D) -> void:
	_refresh_research_detection()'''

func _physics_process(_delta: float) -> void:
	_refresh_research_detection()
	_refresh_rover_visual_upgrade()

func _refresh_rover_visual_upgrade() -> void:
	var should_apply := tech_point >= ROVER_UPGRADE_TECH_POINT
	if should_apply == rover_upgrade_applied:
		return

	rover_upgrade_applied = should_apply
	perseverance_body.visible = should_apply
	sojourner_body.visible = not should_apply
	equipment_arm.visible = should_apply
	equipment_cylinder.visible = not should_apply
	helicopter.visible = should_apply
	helicopter_button.visible = should_apply
	# Scan particles are enabled by the cutscene animation; select the upgraded copy
	# when a scan starts rather than leaving either emitter running between scans.
	equipment_scan_particles.visible = false
	equipment_scan_particles.emitting = false
	upgraded_equipment_scan_particles.visible = false
	upgraded_equipment_scan_particles.emitting = false
	for wheel_model in first_stage_wheels:
		wheel_model.visible = not should_apply
	for wheel_model in second_stage_wheels:
		wheel_model.visible = should_apply
	_apply_rover_upgrade_wheel_layout(should_apply)

func _apply_rover_upgrade_wheel_layout(use_perseverance_axles: bool) -> void:
	for wheel_index in wheel_holders.size():
		if use_perseverance_axles:
			wheel_holders[wheel_index].position = second_stage_wheel_positions[wheel_index]
		else:
			wheel_holders[wheel_index].position = first_stage_wheel_positions[wheel_index]

func _refresh_research_detection() -> void:
	if helicopter_mode:
		research_ui.visible = false
		return

	var detected_rocks: Array[Node3D] = []
	var distances: Dictionary = {}
	for body in equipment_detection_area.get_overlapping_bodies():
		var rock := _get_rock_from_detection_body(body)
		if rock == null:
			continue
		if not detected_rocks.has(rock):
			detected_rocks.append(rock)
			distances[rock] = equipment.global_position.distance_squared_to(rock.global_position)

	var next_rock: Node3D = null
	var closest_distance := INF
	for rock in detected_rocks:
		if bool(rock.get("researched")):
			continue
		var distance := distances[rock] as float
		if distance < closest_distance:
			closest_distance = distance
			next_rock = rock
	if next_rock == null:
		var closest_any_distance := INF
		for rock in detected_rocks:
			var distance := distances[rock] as float
			if distance < closest_any_distance:
				closest_any_distance = distance
				next_rock = rock

	var target_changed := next_rock != current_rock
	current_rock = next_rock
	if current_rock != null:
		if target_changed or not research_ui.visible:
			show_current_research()
	elif research_ui.visible:
		button_exist_clicked()

func show_current_research() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	research_ui.visible = true
	research_button_do.visible = not current_rock.researched
	research_button_do.disabled = scanning_rock != null
	if current_rock.researched:
		label_do.text = "doing the research, blablabla"
	else:
		label_do.text = research_prompt

func button_do_clicked() -> void:
	if current_rock == null or current_rock.researched or scanning_rock != null or not research_ui.visible:
		return
	scanning_rock = current_rock
	research_ui.visible = false
	_use_upgraded_scan_particles(tech_point >= ROVER_UPGRADE_TECH_POINT)
	enter_research_cutscene()
	research_cutscene_player.play("research_cutscene")

func _use_upgraded_scan_particles(use_upgraded: bool) -> void:
	var target_particles := upgraded_equipment_scan_particles if use_upgraded else equipment_scan_particles
	var unused_particles := equipment_scan_particles if use_upgraded else upgraded_equipment_scan_particles
	unused_particles.visible = false
	unused_particles.emitting = false
	target_particles.visible = false
	target_particles.emitting = false
	_retarget_scan_particle_animation(target_particles)

func _retarget_scan_particle_animation(target_particles: GPUParticles3D) -> void:
	var animation := research_cutscene_player.get_animation(&"research_cutscene")
	if animation == null:
		return

	var target_path := get_path_to(target_particles)
	var original_path := get_path_to(equipment_scan_particles)
	var upgraded_path := get_path_to(upgraded_equipment_scan_particles)
	for track_index in animation.get_track_count():
		var track_path := animation.track_get_path(track_index)
		var node_path := NodePath(track_path.get_concatenated_names())
		if node_path != original_path and node_path != upgraded_path:
			continue

		var new_path_text := str(target_path)
		var property_path := track_path.get_concatenated_subnames()
		if not property_path.is_empty():
			new_path_text += ":" + property_path
		animation.track_set_path(track_index, NodePath(new_path_text))

func enter_research_cutscene() -> void:
	rover_process_mode_before_cutscene = rover.process_mode
	rover.process_mode = Node.PROCESS_MODE_DISABLED

func enter_research_scan_camera() -> void:
	camera_before_research_cutscene = get_viewport().get_camera_3d()
	scan_cutscene_camera.make_current()

func exit_research_scan_camera() -> void:
	if camera_before_research_cutscene != null:
		camera_before_research_cutscene.make_current()
	else:
		scan_cutscene_camera.current = false

func exit_research_cutscene() -> void:
	#@warning_ignore("int_as_enum_without_cast")
	rover.process_mode = rover_process_mode_before_cutscene

func _on_helicopter_button_pressed() -> void:
	if tech_point < ROVER_UPGRADE_TECH_POINT or scanning_rock != null:
		return

	helicopter_mode = not helicopter_mode
	_apply_helicopter_mode()

func _apply_helicopter_mode() -> void:
	if helicopter_mode:
		research_ui.visible = false
		rover.process_mode = Node.PROCESS_MODE_DISABLED
		rover.switch_camera_mode(0)
		helicopter.set_helicopter_active(true)
		helicopter_button.text = "Rover"
	else:
		helicopter.set_helicopter_active(false)
		rover.switch_camera_mode(0)
		rover.process_mode = Node.PROCESS_MODE_INHERIT
		helicopter_button.text = "Helicopter"

func _on_research_cutscene_finished(_animation_name: StringName) -> void:
	var scanned_rock := scanning_rock
	scanning_rock = null
	exit_research_cutscene()
	if scanned_rock != null and not scanned_rock.researched:
		scanned_rock.researched = true
		tech_point += 5
		label_tech_point.text = "Tech point: "+str(tech_point)
		_refresh_rover_visual_upgrade()
		_show_game_end_popup_once()
	_refresh_research_detection()

func _show_game_end_popup_once() -> void:
	if game_end_popup_shown or tech_point < GAME_END_TECH_POINT:
		return

	game_end_popup_shown = true
	game_end_popup.popup_centered()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func button_exist_clicked() -> void:
	research_ui.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_start_button_pressed() -> void:
	opening_screen.visible = false
	introduction_screen.visible = false
	rover.process_mode = rover_process_mode_before_opening
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_introduction_button_pressed() -> void:
	opening_screen.visible = false
	introduction_screen.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_introduction_back_button_pressed() -> void:
	introduction_screen.visible = false
	opening_screen.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_help_button_pressed() -> void:
	help_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_help_close_button_pressed() -> void:
	help_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_reset_button_pressed() -> void:
	_reset_rover()

func _input(event) -> void:
	if event.is_action_pressed("Reset"):
		_reset_rover()

func _reset_rover() -> void:
	rover.engine_force = 0.0
	rover.brake = 0.0
	rover.steering = 0.0
	rover.linear_velocity = Vector3.ZERO
	rover.angular_velocity = Vector3.ZERO
	rover.sleeping = false
	rover.global_transform = initial_rover_transform
	PhysicsServer3D.body_set_state(rover.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, initial_rover_transform)
	rover.reset_physics_interpolation()

func _ready():
	for wheel_holder in wheel_holders:
		first_stage_wheel_positions.append(wheel_holder.position)
	_refresh_rover_visual_upgrade()
	research_cutscene.visible = false
	research_ui.visible = false
	research_prompt = label_do.text
	label_tech_point.text = "Tech point: "+str(tech_point)
	initial_rover_transform = rover.global_transform
	introduction_screen.visible = false
	rover_process_mode_before_opening = rover.process_mode
	rover.process_mode = Node.PROCESS_MODE_DISABLED
	opening_screen.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	help_panel.visible = false
	start_button.pressed.connect(_on_start_button_pressed)
	introduction_button.pressed.connect(_on_introduction_button_pressed)
	introduction_back_button.pressed.connect(_on_introduction_back_button_pressed)
	help_button.pressed.connect(_on_help_button_pressed)
	help_close_button.pressed.connect(_on_help_close_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	helicopter_button.pressed.connect(_on_helicopter_button_pressed)
	research_button_do.pressed.connect(button_do_clicked)
	research_button_notdo.pressed.connect(button_exist_clicked)
