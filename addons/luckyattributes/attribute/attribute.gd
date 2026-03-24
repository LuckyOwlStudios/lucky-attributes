@tool
@icon("uid://tmoqeff3atmw")
class_name Attribute
extends Node
## A base node that tracks a numerical value with a minimum, maximum, and optional rate of change.
## Supports [AttributeModifier] resources that can dynamically affect [member max_value] and [member rate_of_change].
## Extend this class to create specific attributes such as [HealthAttribute], stamina, oxygen, and more.

## Emitted when the current value changes
signal value_changed(previous_value: float, current_value: float, change_amount: float)

## Emitted when the max value changes
signal max_value_changed(previous_max_value: float, current_max_value: float, change_amount: float)

## Emitted when this container is emptied
signal empty

## Emitted when this container is full
signal full

## The current value of this object, this value is changed by attributes
@export var value: float:
	set(amount):
		var previous_value: float = value
		value = clamp(amount, 0, max_value)
		if value == 0:
			empty.emit()
		if value == max_value:
			full.emit()
		if value != previous_value:
			var change_amount: float = value - previous_value
			value_changed.emit(previous_value, value, change_amount)

## Value this attribute starts with per default.
@export var value_start : float = 100

## The maximum value of this container (before attributes), this value should not change
@export var base_max_value: float = 100
## The current max value of this object, this value is changed by attributes
var max_value: float:
	set(amount):
		var prev: float = max_value
		max_value = max(1, amount)
		var change_amount: float = max_value - prev
		max_value_changed.emit(prev, max_value, change_amount)

## The base regeneration of this container (before attributes), this value should not change
@export var base_rate_of_change: float = 0
## The current regeneration rate of this object, this value is changed by attributes
var rate_of_change: float

### --- OLD METHOD ---
#@export var modifiers: Dictionary[String, AttributeModifier]:
	#set(new_modifiers):
		## Disconnect old ones first
		#for modifier in modifiers.values():
			#if modifier and modifier.target_variable_changed.is_connected(recalculate_attributes):
				#_disconnect_modifier_signals(modifier)
		#modifiers = new_modifiers
		## Connect new ones
		#for modifier in modifiers.values():
			#if modifier:
				#_connect_modifier_signals(modifier)
		#recalculate_attributes()

@export var modifiers: Array[AttributeModifier] = []:
	set(new_modifier):
		modifiers = new_modifier
		for new_mod in modifiers:
			if new_mod:
				_connect_modifier_signals(new_mod)
		recalculate_attributes()

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	properties.append({
		"name": "Visualize Data",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	properties.append({
		"name": "max_value",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY
	})
	properties.append({
		"name": "rate_of_change",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY
	})
	return properties

func _connect_modifier_signals(modifier: AttributeModifier) -> void:
	modifier.target_variable_hint = _get_modifier_targets()
	modifier.notify_property_list_changed()
	if not modifier.updated.is_connected(recalculate_attributes):
		modifier.updated.connect(recalculate_attributes)

func _disconnect_modifier_signals(modifier: AttributeModifier) -> void:
	modifier.updated.disconnect(recalculate_attributes)

static func has_attributes(node: Node) -> bool:
	return node.get("attributes") is Array[Attribute]

static func get_attributes(node: Node) -> Array[Attribute]:
	return node.get("attributes")

func _ready() -> void:
	if not Engine.is_editor_hint():
		max_value = base_max_value
		rate_of_change = base_rate_of_change
	
	recalculate_attributes()
	
	if not Engine.is_editor_hint():
		value = value_start

func _process(delta: float) -> void:
	if rate_of_change != 0.0:
		value += rate_of_change * delta
	
	for modifier in modifiers:
		if modifier == null:
			continue
		if modifier.duration == -1.0:
			continue
		modifier.duration -= delta
		if modifier.duration <= 0:
			remove_modifier(modifier.id)

#region Attribute Methods
func add_modifier(modifier: AttributeModifier) -> bool:
	if has_modifier(modifier.id):
		push_warning("Modifier with same name already exists")
		return false
	_connect_modifier_signals(modifier)
	modifiers.append(modifier)
	recalculate_attributes()
	return true

func remove_modifier(id: String) -> bool:
	var modifier := get_modifier(id)
	if modifier:
		_disconnect_modifier_signals(modifier)
		modifiers.erase(modifier)
		recalculate_attributes()
		return true
	return false

## Recalculate all attributes and update component values
func recalculate_attributes():
	# Start with base values
	var new_max_value = base_max_value
	var new_rate_of_change = base_rate_of_change
	
	# Apply all modifiers for max_value first (for proper order of operations)
	#for modifier_value in modifiers.values(): ### --- OLD METHOD ---
	for modifier_value in modifiers:
		if modifier_value == null:
			continue
		var modifier: AttributeModifier = modifier_value
		if modifier.target_variable == "max_value":
			match modifier.operation:
				AttributeModifier.OPERATION_TYPE.ADD_VALUE:
					new_max_value += modifier.value
				AttributeModifier.OPERATION_TYPE.ADD_MULTIPLIED_BASE:
					new_max_value += base_max_value * (modifier.value / 100.0)
				AttributeModifier.OPERATION_TYPE.ADD_MULTIPLIED_TOTAL:
					new_max_value += new_max_value * (modifier.value / 100.0)
	
	# Apply all modifiers for rate_of_change
	#for modifier_value in modifiers.values(): ### --- OLD METHOD ---
	for modifier_value in modifiers:
		if modifier_value == null:
			continue
		var modifier: AttributeModifier = modifier_value
		if modifier.target_variable == "rate_of_change":
			match modifier.operation:
				AttributeModifier.OPERATION_TYPE.ADD_VALUE:
					new_rate_of_change += modifier.value
				AttributeModifier.OPERATION_TYPE.ADD_MULTIPLIED_BASE:
					new_rate_of_change += base_rate_of_change * (modifier.value / 100.0)
				AttributeModifier.OPERATION_TYPE.ADD_MULTIPLIED_TOTAL:
					new_rate_of_change += new_rate_of_change * (modifier.value / 100.0)
	
	# Update the actual values
	max_value = new_max_value
	rate_of_change = new_rate_of_change
	
	# Clamp current value if max_value decreased
	if value > max_value:
		value = max_value

## Override this in subclasses to expose additional targetable variables
func _get_modifier_targets() -> String:
	return "max_value,rate_of_change"

func has_modifier(id: String) -> bool:
	return get_modifier(id) != null
	#return modifiers.get(key) != null ### --- OLD METHOD ---

func get_modifier(id: String) -> AttributeModifier:
	var results := modifiers.filter(func(m): return m.id == id)
	return results[0] if not results.is_empty() else null
	#return modifiers.get(key) ### --- OLD METHOD ---

#endregion

#region Setter Methods
func increase(amount: float) -> bool:
	if is_full():
		return false
	value += amount
	return true

func decrease(amount: float) -> bool:
	if is_empty():
		return false
	value -= amount
	return true

func set_empty():
	value = 0

func set_full():
	value = max_value
#endregion

#region Getter Methods
func is_full() -> bool:
	return value >= max_value

func is_empty():
	return value <= 0

## Returns a percentage based on fullness
func get_percentage() -> float:
	return value / max_value

## Uses the rate_of_change to determine how long will it take for this container to be full
func get_time_to_full() -> float:
	# Already full
	if is_full():
		return 0.0
	
	# No regeneration or negative regeneration - will never be full
	if rate_of_change <= 0:
		return -1.0
	
	# Calculate remaining value needed and divide by rate
	var remaining_value = max_value - value
	return remaining_value / rate_of_change
#endregion
