class_name Balance
extends Node

signal fully_unbalanced(balance: float)

@export var range: float = 50

var min_balance: float = -range
var max_balance: float = range
var previous_amount: float = 0
var amount: float = 0
var percent: float = 0

func _process(delta: float) -> void:
	var half_range = (max_balance - min_balance) / 2
	
	percent = amount / half_range
	
	previous_amount = amount
	amount = clamp(amount + percent, min_balance, max_balance)

	if previous_amount != amount:
		if amount == max_balance or amount == min_balance:
			fully_unbalanced.emit(amount)

func lean(power: float) -> void:
	amount += power
