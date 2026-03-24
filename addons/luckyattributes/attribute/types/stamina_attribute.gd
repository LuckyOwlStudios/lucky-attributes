@tool
@icon("uid://wha88l4ir6oc")
class_name StaminaAttribute
extends Attribute
## An [Attribute] that represents the stamina of an object.
## Stamina is consumed at a [member consumption_rate] and regenerates passively after
## a delay defined by [member base_time_before_regen].
## Supports an [member unlimited] mode that disables all consumption and drain.
## Extend [method recalculate_attributes] to add modifiers targeting [member consumption_rate].

## Whether this object has unlimited energy and cannot be drained
@export var unlimited: bool = false

@export_group("Passive Regeneration")
## Whether stamina should regenerate passively when not consuming
@export var passive_regen: bool = true
## How long after consuming stamina does regen begin (in seconds), before attributes
@export var base_time_before_regen: float = 2.0
var time_before_regen: float = base_time_before_regen
# A countdown that begins after the last consumption
var last_consumption_time: float = 0.0
@export var base_consumption_rate: float = 0.0
# The rate in which we are consuming stamina (modified by attributes)
var consumption_rate: float = 0.0
# Whether or not we are consuming stamina
var is_consuming: bool

func _ready() -> void:
	super._ready()
	value_changed.connect(update_last_consume_time)
	base_rate_of_change = 20

## Set hurt time to prevent immediate regen
func update_last_consume_time(_previous_value: float, _current_value: float, change_amount: float):
	if change_amount < 0:
		last_consumption_time = time_before_regen

func _process(delta: float) -> void:
	if unlimited:
		return
	
	# Determine if we are consuming stamina!
	is_consuming = consumption_rate > 0 and value > 0
	
	if is_consuming:
		var consumption_amount = consumption_rate * delta
		decrease(consumption_amount)
	else:
		# Countdown consumption delay timer
		if last_consumption_time > 0.0:
			last_consumption_time = max(last_consumption_time - delta, 0.0)
			return  # Don't regen if recently consumed stamina
		
		# Try and regenerate stamina
		if last_consumption_time == 0:
			# Handle regeneration
			super._process(delta)

func recalculate_attributes():
	# Call parent to handle max_value and rate_of_change
	super.recalculate_attributes()
	
	# Handle consumption_rate modifiers specific to stamina
	var new_consumption_rate = base_consumption_rate
	
	for modifier_value in modifiers:
		if modifier_value == null: continue
		var modifier: AttributeModifier = modifier_value
		if modifier.target_variable == "consumption_rate":
			match modifier.operation:
				AttributeModifier.OPERATION_TYPE.ADD_VALUE:
					new_consumption_rate += modifier.value
				AttributeModifier.OPERATION_TYPE.ADD_MULTIPLIED_BASE:
					new_consumption_rate += base_consumption_rate * (modifier.value / 100.0)
				AttributeModifier.OPERATION_TYPE.ADD_MULTIPLIED_TOTAL:
					new_consumption_rate += new_consumption_rate * (modifier.value / 100.0)
	
	# Update the consumption rate
	consumption_rate = new_consumption_rate

#region Helper Methods
func can_consume(amount: float) -> bool:
	return (value - amount) > 0
#endregion
