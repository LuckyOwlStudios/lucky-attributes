@tool
class_name AttributeReaderProgressBar
extends ProgressBar

@export var attribute: Attribute:
	set(new_node):
		# Disconnect from old node first
		if attribute:
			if attribute.value_changed.is_connected(value_changed):
				attribute.value_changed.disconnect(value_changed)
			if attribute.max_value_changed.is_connected(max_value_changed):
				attribute.max_value_changed.disconnect(max_value_changed)
		attribute = new_node
		if attribute:
			attribute.value_changed.connect(value_changed)
			attribute.max_value_changed.connect(max_value_changed)
		update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not attribute:
		warnings.append("No attribute assigned. Please assign an Attribute node.")
	return warnings

func value_changed(previous_value: float, current_value: float, change_amount: float):
	value = current_value

func max_value_changed(previous_max_value: float, current_max_value: float, change_amount: float):
	max_value = current_max_value

func _enter_tree() -> void:
	custom_minimum_size.x = 200
