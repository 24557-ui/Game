extends Node3D

# One imported Blender animation is exactly one full rotor turn.
# rotor_speed uses radians per second, like the old rotate_y() version.
@export var rotor_speed := 18.0
@export var spin_direction := 1.0
@export var animation_name: StringName = &"RotorSpin-loop"

@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false)


func _ready() -> void:

	var animation := animation_player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR
	_update_speed()


func start_spin() -> void:
	if animation_player == null:
		return

	if spin_direction < 0.0:
		animation_player.play_backwards(animation_name)
	else:
		animation_player.play(animation_name)


func stop_spin() -> void:
	if animation_player != null:
		animation_player.pause()


func set_rotor_speed(new_speed: float) -> void:
	rotor_speed = maxf(new_speed, 0.0)
	_update_speed()


func _update_speed() -> void:
	if animation_player == null:
		return
	if not animation_player.has_animation(animation_name):
		return

	var animation := animation_player.get_animation(animation_name)
	if animation.length == 0.0:
		return

	# The clip is one full turn, so:
	# normal speed = radians per second / one full turn (TAU)
	animation_player.speed_scale = rotor_speed * animation.length / TAU
