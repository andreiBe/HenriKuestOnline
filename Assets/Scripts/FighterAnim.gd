extends Sprite2D

@export var jumpSpeed = 20
@export var jumpAmount = 120
@export var _time = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_time += delta
	var movement = cos(_time * jumpSpeed) * jumpAmount
	
	if get_parent().isMoving:
		position.y += movement * delta
