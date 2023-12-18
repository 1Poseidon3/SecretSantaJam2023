extends StaticBody3D

const MOVE_SPEED = 3.0

@export var price : int

func _ready():
	pass

func _process(_delta):
	pass

func show_price():
	$Price.visible = true
	$PriceTextDisappear.start()

func _on_price_text_disappear_timeout():
	$Price.visible = false;
