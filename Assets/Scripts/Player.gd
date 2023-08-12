extends CharacterBody2D
class_name Player
signal hit

@export var player_start_x = 50
@export var player_start_y = 50
@export var speed = 200
var bishop: Bishop = Bishop.new(false, self)

func _enter_tree():
	$MultiplayerSynchronizer.set_multiplayer_authority(name.to_int())
	$CollisionShape2D.disabled = false
	position.x = player_start_x
	position.y = player_start_y

func _ready():
	if is_local_authority():
		$GPUParticles2D.emitting = true
	
func setTeam(team):
	bishop.setTeam(team)
	$AnimatedSprite2D.animation = "default" + str(team)
	
func is_local_authority():
	return $MultiplayerSynchronizer.is_multiplayer_authority()

func _process(_delta):
	if is_local_authority():
		velocity = Vector2.ZERO # The player's movement vector.
		if Input.is_action_pressed("move_right"):
			velocity.x += 1
		if Input.is_action_pressed("move_left"):
			velocity.x -= 1
		if Input.is_action_pressed("move_down"):
			velocity.y += 1
		if Input.is_action_pressed("move_up"):
			velocity.y -= 1

		if velocity.length() > 0:
			velocity = velocity.normalized() * speed
		
		set_velocity(velocity)
		move_and_slide()
		$MultiplayerSynchronizer.sync_position = position
	else:
		position = $MultiplayerSynchronizer.sync_position
		move_and_slide()
	
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "right"+ str(bishop.getTeam())
		$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		$AnimatedSprite2D.animation = "default" + str(bishop.getTeam())
		$AnimatedSprite2D.flip_h = false
	

func addFollowers(followers):
	for follower in followers:
		follower.setTarget(self)
		follower.modulate = Color(10, 1, 1)
		follower.get_node("FollowIcon").visible = true
	bishop.addFollowers(followers)

func _on_Player_body_entered(_body):
	emit_signal("hit")
	$CollisionShape2D.set_deferred("disabled", true)

