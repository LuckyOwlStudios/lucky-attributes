@tool
@icon("uid://cygjdq2euqqs1")
## An [Attribute] that represents the oxygen level of an object.
## Oxygen depletes while the object is submerged or in an oxygen-deprived environment,
## and regenerates passively when oxygen is available.
## When oxygen is empty, damage is dealt at a configurable rate via [member suffocation_rate].
class_name OxygenAttribute
extends Attribute

## Whether this object has unlimited oxygen and cannot suffocate
@export var unlimited: bool = false

@export_group("Passive Regeneration")
## Whether oxygen should regenerate passively when in an oxygen-rich environment
@export var passive_regen: bool = true
## How quickly oxygen regenerates when available
@export var passive_regen_rate: float = 20.0

@export_group("Suffocation")
## The rate at which damage is dealt when oxygen is empty (per second)
@export var suffocation_rate: float = 5.0
## Emitted every time suffocation damage is dealt
signal suffocating(damage: float)

## Whether the object is currently in an oxygen-deprived environment
var deprived: bool = false

func _ready() -> void:
	super._ready()
	base_rate_of_change = 0.0

func _process(delta: float) -> void:
	if unlimited:
		return

	if deprived:
		# Drain oxygen while deprived
		if not is_empty():
			decrease(passive_regen_rate * delta)
		else:
			# No oxygen left — deal suffocation damage
			var damage := suffocation_rate * delta
			suffocating.emit(damage)
	else:
		# Regenerate oxygen when not deprived
		if not is_full():
			increase(passive_regen_rate * delta)

## Call this to notify the attribute that the object has entered an oxygen-deprived environment
func enter_deprived_environment() -> void:
	deprived = true

## Call this to notify the attribute that the object has left an oxygen-deprived environment
func exit_deprived_environment() -> void:
	deprived = false

func _get_modifier_targets() -> String:
	return super._get_modifier_targets() + ",suffocation_rate,passive_regen_rate"

func recalculate_attributes() -> void:
	super.recalculate_attributes()

	var new_suffocation_rate := suffocation_rate
	var new_passive_regen_rate := passive_regen_rate

	for modifier_value in modifiers:
		if modifier_value == null:
			continue
		var modifier: AttributeModifier = modifier_value
		match modifier.target_variable:
			"suffocation_rate":
				match modifier.operation:
					AttributeModifier.OPERATION_TYPE.ADD_VALUE:
						new_suffocation_rate += modifier.value
					AttributeModifier.OPERATION_TYPE.ADD_MULTIPLIED_BASE:
						new_suffocation_rate += suffocation_rate * (modifier.value / 100.0)
					AttributeModifier.OPERATION_TYPE.ADD_MULTIPLIED_TOTAL:
						new_suffocation_rate += new_suffocation_rate * (modifier.value / 100.0)
			"passive_regen_rate":
				match modifier.operation:
					AttributeModifier.OPERATION_TYPE.ADD_VALUE:
						new_passive_regen_rate += modifier.value
					AttributeModifier.OPERATION_TYPE.ADD_MULTIPLIED_BASE:
						new_passive_regen_rate += passive_regen_rate * (modifier.value / 100.0)
					AttributeModifier.OPERATION_TYPE.ADD_MULTIPLIED_TOTAL:
						new_passive_regen_rate += new_passive_regen_rate * (modifier.value / 100.0)

	suffocation_rate = new_suffocation_rate
	passive_regen_rate = new_passive_regen_rate
