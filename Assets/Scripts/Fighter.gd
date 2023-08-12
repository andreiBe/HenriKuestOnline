extends Node2D
class_name Fighter

var _noise = FastNoiseLite.new()
var _rng = RandomNumberGenerator.new()
var _angle = 0

var _target: Node2D
var _max_dist = 50
#Fighters won't move unless true
@export var isMoving = false
var _cell_width
var _width #width of grid
var _height #height of grid


# Called when the node enters the scene tree for the first time.
func _ready():
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 2.0
	var grid = get_tree().current_scene.get_node("GridManager")
	_cell_width = grid.tileSize
	_width = grid.width
	_height = grid.height
	_startMoving()
	
func setTeam(team):
	($Square as Sprite2D).region_rect = Rect2(team*12, 0, 12, 16)

func setTarget(target):
	_target = target
	
func _startMoving():
	while true:
		await get_tree().create_timer(0.8).timeout
		_changeDirection()
		if !is_instance_valid(_target):
			return
		#when following a player, don't stop ever
		if _target.is_in_group("Player"):
			isMoving = true
		else:
			isMoving = !isMoving
	
func _changeDirection():
	_rng.randomize()
	var rng_number = _rng.randf_range(-10.0, 10.0)
	var dir = _noise.get_noise_2d(position.x+rng_number, position.y+rng_number)
	_angle = dir*360 - PI/2.0
	
func move(delta):
	# Define some speed
	var speed = 100.0
	if !is_instance_valid(_target):return
	var go_around_point = _target.position
	# Calculate direction:
	# the Y coordinate must be inverted,
	# because in 2D the Y axis is pointing down
	var dir = Vector2(cos(_angle), -sin(_angle))
	var new_pos: Vector2 = (position + dir * (speed * delta))
	# Move
	#position = (position + dir * (speed * delta))
	var dist = new_pos.distance_to(go_around_point)
	var distbefore = position.distance_to(go_around_point)
	if (dist > _max_dist and distbefore < dist):
		dir = Vector2(go_around_point.x-position.x, go_around_point.y-position.y)
		var direction_vector = dir.normalized() * speed * delta
		new_pos = position + direction_vector
	position = new_pos
	
	
	position.x = clamp(position.x, _cell_width, _width*_cell_width)
	position.y = clamp(position.y, _cell_width, _height*_cell_width)
	
	
func _process(delta):
	if isMoving:
		move(delta)


