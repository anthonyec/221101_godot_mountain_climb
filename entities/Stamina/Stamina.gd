class_name Stamina
extends Node

signal depleted
signal full

@export var can_recover: bool = true
@export var regain_amount: float = 20.0
@export var pause_time: float = 1.0
@export var max_stamina: float = 100.0

@onready var regain_timer: Timer = $RegainTimer

var previous_amount: float = max_stamina
var amount: float = max_stamina
var is_recovering: bool = false

func _ready() -> void:
	regain_timer.wait_time = pause_time

func _process(delta):
	if is_recovering:
		regain(regain_amount * delta)
	
	if previous_amount != amount:
		if is_depleted():
			depleted.emit()
			
		if is_full():
			full.emit()

func use(amount_to_subtract: float = 1.0):
	is_recovering = false
	previous_amount = amount
	amount = clamp(amount - amount_to_subtract, 0, max_stamina)
	
	# Reset the timer
	regain_timer.stop()
	regain_timer.start()
	
func regain(amount_to_add: float = 1.0):
	if !can_recover:
		return

	previous_amount = amount
	amount = clamp(amount + amount_to_add, 0, max_stamina)

func is_depleted() -> bool:
	return amount == 0
	
func is_full() -> bool:
	return amount == max_stamina

func _on_regain_timer_timeout() -> void:
	regain_timer.stop()
	is_recovering = true
