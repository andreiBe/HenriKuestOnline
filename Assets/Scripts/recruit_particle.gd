extends GPUParticles2D


func _on_Timer_timeout():
	queue_free()
