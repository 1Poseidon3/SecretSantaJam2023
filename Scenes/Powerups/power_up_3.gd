extends StaticBody3D

func _on_health_pickup_trigger_body_entered(body):
	if body.has_method("update_hud"):
		Globals.max_player_health += 25
		Globals.player_health += 25
		self.visible = false
		body.update_hud(2)
		$AudioStreamPlayer3D.play()

func _on_audio_stream_player_3d_finished():
	queue_free()
