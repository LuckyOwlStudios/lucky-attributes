@tool
class_name AttributeModifier
extends Resource

enum OPERATION_TYPE {
	ADD_VALUE, ## Adds the value
	ADD_MULTIPLIED_BASE, ## Multiplies with the base value
	ADD_MULTIPLIED_TOTAL ## Multiplies at the end with the total
}

# THESE SIGNALS
signal updated

@export var id: String:
	set(value):
		id = value

## The amount we changing the target_variable by
@export var value: float:
	set(f):
		value = f
		updated.emit()
## How the value is applied to the target_variable
@export var operation: OPERATION_TYPE:
	set(op):
		operation = op
		updated.emit()
## [Optional] How long this attribute will last (-1 = infinite)
@export var duration: float = -1

## The variable we are targeting
var target_variable: String:
	set(s):
		target_variable = s
		updated.emit()
var target_variable_hint: String = ""

func _init(_id: String = "", _target_variable: String = "", _value: float = 0, _operation: OPERATION_TYPE = OPERATION_TYPE.ADD_VALUE) -> void:
	if _id.is_empty():
		id = str(get_instance_id())
	if target_variable.is_empty():
		target_variable = _target_variable
	if value == 0:
		value = _value
	operation = _operation

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	
	target_variable_hint
	
	var new_property: Dictionary = {
		"name": "target_variable",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint_string": target_variable_hint
	}
	
	properties.append(new_property)
	
	return properties

## Calculate the final modifier value based on operation type
func calculate_modifier_value(base_value: float, current_total: float) -> float:
	match operation:
		OPERATION_TYPE.ADD_VALUE:
			return value
		OPERATION_TYPE.ADD_MULTIPLIED_BASE:
			return base_value * (value / 100.0)
		OPERATION_TYPE.ADD_MULTIPLIED_TOTAL:
			return current_total * (value / 100.0)
		_:
			return 0.0
