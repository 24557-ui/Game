extends Node3D
@onready var research_cutscene: Control = $CanvasLayer/research_cutscene
@onready var research_ui = $CanvasLayer/research_ui
@onready var research_button_do = $CanvasLayer/research_ui/do
@onready var label_do = $CanvasLayer/research_ui/Label
@onready var research_button_notdo = $"CanvasLayer/research_ui/not do"
@onready var rover: Node3D = $rover
@onready var equipment: Node3D = $rover/equipment
@onready var equipment_detection_area: Area3D = $rover/equipment/EquipmentDetectionArea
@onready var research_cutscene_player: AnimationPlayer = $ResearchCutsceneAnimationPlayer
@onready var scan_cutscene_camera: Camera3D = $rover/ScanCutsceneCamera

var tech_point: int = 0
var current_rock: Node3D = null
var research_prompt: String
var scanning_rock: Node3D = null
var rover_process_mode_before_cutscene: int = Node.PROCESS_MODE_INHERIT
var camera_before_research_cutscene: Camera3D = null

func _get_rock_from_detection_body(body: Node3D) -> Node3D:
	var rock := body.get_parent() as Node3D
	if rock != null and rock.get("researched") != null:
		return rock
	return null

func _on_equipment_detection_body_entered(_body: Node3D) -> void:
	_refresh_research_detection()

func _on_equipment_detection_body_exited(_body: Node3D) -> void:
	_refresh_research_detection()

func _physics_process(_delta: float) -> void:
	_refresh_research_detection()

func _refresh_research_detection() -> void:
	if scanning_rock != null:
		return

	var detected_rocks: Array[Node3D] = []
	var distances: Dictionary = {}
	for body in equipment_detection_area.get_overlapping_bodies():
		var rock := _get_rock_from_detection_body(body)
		if rock == null or not is_instance_valid(rock):
			continue
		if not detected_rocks.has(rock):
			detected_rocks.append(rock)
			distances[rock] = equipment.global_position.distance_squared_to(rock.global_position)

	var next_rock: Node3D = null
	# Keep the active target while it is still researchable. If it has already
	# been researched, prioritize another unresearched rock in the forward area.
	if current_rock != null and is_instance_valid(current_rock) and detected_rocks.has(current_rock) and not bool(current_rock.get("researched")):
		next_rock = current_rock

	if next_rock == null:
		var closest_distance := INF
		for rock in detected_rocks:
			if bool(rock.get("researched")):
				continue
			var distance := distances[rock] as float
			if distance < closest_distance:
				closest_distance = distance
				next_rock = rock

	# Only fall back to an already-researched rock when no new target is present.
	if next_rock == null and current_rock != null and is_instance_valid(current_rock) and detected_rocks.has(current_rock):
		next_rock = current_rock
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

func show_current_research():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	research_ui.visible = true
	research_button_do.visible = not current_rock.researched
	research_button_do.disabled = scanning_rock != null
	if current_rock.researched:
		label_do.text = "doing the research, blablabla"
	else:
		label_do.text = research_prompt

func button_do_clicked():
	if current_rock == null or current_rock.researched or scanning_rock != null or not research_ui.visible:
		return
	scanning_rock = current_rock
	research_ui.visible = false
	enter_research_cutscene()
	research_cutscene_player.play("research_cutscene")

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
	@warning_ignore("int_as_enum_without_cast")
	rover.process_mode = rover_process_mode_before_cutscene

func _on_research_cutscene_finished(_animation_name: StringName) -> void:
	var scanned_rock := scanning_rock
	scanning_rock = null
	exit_research_cutscene()
	if scanned_rock != null and not scanned_rock.researched:
		scanned_rock.researched = true
		tech_point += 5
		print(tech_point)
	_refresh_research_detection()

func button_exist_clicked():
	research_ui.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ready():
	research_cutscene.visible = false
	research_ui.visible = false
	research_prompt = label_do.text
	research_button_do.pressed.connect(button_do_clicked)
	research_button_notdo.pressed.connect(button_exist_clicked)
