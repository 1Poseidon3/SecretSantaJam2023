extends StaticBody3D

#region Constants
const MOVE_SPEED = 3.0
#endregion

#region Variables
var bought : bool = false
var sound_played : bool = false
#endregion

#region On Ready Variables
@onready var price_tag1 : Label3D = $Price1
@onready var price_tag2 : Label3D = $Price2
@onready var sound_player : AudioStreamPlayer3D = $AudioStreamPlayer3D
#endregion

#region Export Variables
@export var price : int
#endregion

func _ready():
	price_tag1.text = str(price)
	price_tag2.text = str(price)

func _process(_delta):
	if bought:
		var tween : Tween = get_tree().create_tween()
		tween.tween_property($".", "position:y", -4, 5)
		price_tag1.visible = false
		price_tag2.visible = false
		if !sound_player.playing and !sound_played:
			sound_player.play()
			sound_played = true
		if !tween.is_running():
			self.queue_free()

func show_price():
	price_tag1.visible = true
	price_tag2.visible = true
	$PriceTextDisappear.start()

func _on_price_text_disappear_timeout():
	price_tag1.visible = false
	price_tag2.visible = false
