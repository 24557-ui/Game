extends Node3D

# This becomes true after the rover has finished researching this rock.
var researched := false

@onready var researched_label: Label3D = $ResearchedLabel


func mark_as_researched() -> void:
	researched = true
	researched_label.visible = true
