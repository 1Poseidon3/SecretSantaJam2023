extends StaticBody3D

func _on_ammo_replenish_pickup_body_entered(body):
	if body.has_method("update_hud"):
		Globals.m1911_ammo_in_gun = 7
		Globals.m1911_ammo_in_reserve = 56
		Globals.rifle_ammo_in_gun = 20
		Globals.rifle_ammo_in_reserve = 100
		Globals.shotgun_ammo_in_gun = 6
		Globals.shotgun_ammo_in_reserve = 48
		body.update_hud(0)
		self.visible = false
		$AudioStreamPlayer3D.play()

func _on_audio_stream_player_3d_finished():
	queue_free()
