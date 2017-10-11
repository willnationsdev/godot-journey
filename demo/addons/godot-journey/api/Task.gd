tool
extends Node

signal task_completed()
signal task_reversed()

const JourneyEditor = preload("JourneyEditor.gd")

var task_subscriber = null

func _enter_tree():
	var config = ConfigFile.new()
	config.load("res://journey_config.cfg")
	if Engine.is_editor_hint():
		var ancestor = get_parent()
		while ancestor and not ancestor is load(config.get_value("editor", "script")):
			ancestor = ancestor.get_parent()
		if ancestor:
			task_subscriber = ancestor
	else:
		task_subscriber = get_tree().get_root().get_node(config.get_value("singleton", "name"))
	connect("task_completed", task_subscriber, "on_task_completed")
	connect("task_reversed", task_subscriber, "on_task_reversed")
