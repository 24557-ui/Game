extends Node3D

@export var rotor_speed := 18.0
@export var spin_direction := 1.0
@export var animation_name: StringName = &"RotorSpin"

var _animation_player: AnimationPlayer
var _selected_animation: StringName = &""


func _ready() -> void:
	_animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation_player == null:
		push_warning("Rotor AnimationPlayer was not found; the rotor will stay static.")
		return

	_selected_animation = _find_animation()
	if _selected_animation == &"":
		push_warning("RotorSpin animation was not imported from rotor.blend.")
		return

	var animation := _animation_player.get_animation(_selected_animation)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR
	_update_playback_speed()


func set_rotor_speed(speed: float) -> void:
	rotor_speed = maxf(speed, 0.0)
	_update_playback_speed()


func set_spinning(spinning: bool) -> void:
	if _animation_player == null or _selected_animation == &"":
		return

	if spinning:
		if spin_direction < 0.0:
			_animation_player.play_backwards(_selected_animation)
		else:
			_animation_player.play(_selected_animation)
	else:
		_animation_player.pause()


func _find_animation() -> StringName:
	if _animation_player.has_animation(animation_name):
		return animation_name

	for candidate in _animation_player.get_animation_list():
		var candidate_text := String(candidate).to_lower()
		if candidate_text.contains("rotor") and candidate_text.contains("spin"):
			return candidate

	return &""


func _update_playback_speed() -> void:
	if _animation_player == null or _selected_animation == &"":
		return

	var animation := _animation_player.get_animation(_selected_animation)
	if animation == null or is_zero_approx(animation.length):
		return

	# The imported clip is exactly one full revolution. Convert the exported
	# angular speed from radians/second to AnimationPlayer speed_scale.
	_animation_player.speed_scale = rotor_speed * animation.length / TAU
