extends StaticBody3D

func _on_sprint_pickup_trigger_body_entered(body):
	if body.has_method("update_hud"):
		Globals.max_sprint_speed += 1.5
		self.visible = false
		body.update_hud(1)
		$AudioStreamPlayer3D.play()

func _on_audio_stream_player_3d_finished():
	queue_free()
