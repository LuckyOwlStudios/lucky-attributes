@tool
@icon("uid://bt6cp2afg0u1")
class_name HealthAttribute
extends Attribute
## An [Attribute] that represents the health of an object.
## Supports invincibility, passive regeneration after a delay, and an injured state
## based on a configurable health percentage threshold.
## Emits [signal entered_injured_state] and [signal exited_injured_state] when crossing that threshold.

## Emitted when this object is considered injured
signal entered_injured_state
## Emitted when this object is not longer considered injured
signal exited_injured_state

## Whether this object is invincible and can't be hurt
@export var invincible: bool = false

@export_group("Passive Regeneration")
## Whether the object should regenerate passively
@export var passive_regen: bool = true
## The percentage in which wthe object is:
## [br] - Considered [method HealthContainer.is_very_hurt] is true.
## [br] - When passive regeneration begins to kick in
@export_range(0.0, 1.0) var hurt_percentage: float = .25
## How long after taking damage does regen begin (in seconds)
@export var max_time_before_health_regen: float = 5.0
## The rate in which the object passively heals
@export var passive_regen_rate: float = 2.5
var hurt_time: float = 0.0
var was_injured: bool = false

func _ready() -> void:
	super._ready()
	value_changed.connect(_update_hurt_time)
	value_changed.connect(_check_injury_state)

## Set hurt time to prevent immediate regen
func _update_hurt_time(_previous_value: float, _current_value: float, change_amount: float):
	if change_amount < 0:
		hurt_time = max_time_before_health_regen

func _check_injury_state(_previous_value: float, _current_value: float, change_amount: float):
	var current_injured_state: bool = is_injured()
	
	if current_injured_state != was_injured:
		if current_injured_state:
			entered_injured_state.emit()
		else:
			exited_injured_state.emit()
	
	was_injured = current_injured_state

func _process(delta: float) -> void:
	super._process(delta)
	## Only happens when the object is less than a certain threshold of health
	# Countdown hurt delay timer FIRST
	if hurt_time > 0.0:
		hurt_time = max(hurt_time - delta, 0.0)
		return  # Don't regen if still in hurt delay period
	
	if passive_regen:
		var max_regen_cap = max_value * hurt_percentage
		if (value < max_regen_cap):
			var regeneration_amount = passive_regen_rate * delta
			value += regeneration_amount

## Returns if this object is injured
func is_injured() -> bool:
	return get_percentage() <= hurt_percentage
