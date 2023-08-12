extends Node2D

class_name Grid
const tile_path = preload("res://Assets/prefabs/Tile.tscn")
#tile sprites
const leftup = preload("res://Assets/Sprites/Grid sprites/1.png")
const leftdown = preload("res://Assets/Sprites/Grid sprites/3.png")
const rightup = preload("res://Assets/Sprites/Grid sprites/2.png")
const rightdown = preload("res://Assets/Sprites/Grid sprites/4.png")

const tentScene = preload("res://Assets/Scenes/tents/Tent.tscn")


var tiles: Array = [[]]
var obstaclePositions = []
var obstacles = [preload("res://Assets/Scenes/obstacles/Obstacle.tscn"),
preload("res://Assets/Scenes/obstacles/Obstacle2.tscn")]

#makes variables editable from godot editor
@export var width: int = 60
@export var height: int = 40

@export var gridID: int = 0 # 0 is for "random" generation while other grids need to have IDs

@export var tileSize: int = 48

@export var gridOffset: int = -48
var tentId: int = 0
var tents = {}
var Multiplayer: Multiplayer

func resetTents():
	tentId = 0
	tents = {}
	for child in get_children():
		if child is Tent or child is Fighter or child is BotPlayer:
			child.queue_free()
			
func resetMap():
	tiles = [[]]
	obstaclePositions = []
	resetTents()
	for child in get_children():
		if child.is_in_group("Obstacle") or child is Tile:
			child.queue_free()
			
func reset():
	resetMap()
	for child in get_children():
		if child is Player:
			child.queue_free()	
			
# Called when the node enters the scene tree for the first time.
func _ready():
	Multiplayer = $Multiplayer
		
func has_village(x: int,y: int):
	if x >= width or y >= height or x < 0 or y < 0:
		return false
	var tile: Tile = tiles[x][y]
	return tile.hasTent
	
func no_near_tents(x: int, y: int):
	return !has_village(x-1, y) and !has_village(x-1,y-1) and !has_village(x-1,y+1) and !has_village(x,y-1)

func generateTents(rng_seed: int):
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for x in range(width):
		for y in range(height):
			var tile: Tile = tiles[x][y]
			if tile.get_child_count() > 1:
				continue
			if rng.randi_range(0,100) < 5 and no_near_tents(x,y):
				spawnTent(tile, rng.randi_range(0,3))

func _make_borders():
	var o = 0
	var w = width * tileSize
	var h = height * tileSize
	var a = 10
	var dimensions = [[o+w/2.0,o,w+100,a], [o,o+h/2.0,a,h+100], [o+w/2.0,h-gridOffset,w+100,a], [w-gridOffset,o+h/2.0,a,h+100]]
	for dimension in dimensions:
		var border := StaticBody2D.new()
		var collisionShape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		border.position = Vector2(dimension[0], dimension[1])
		rect.size.x = dimension[2]
		rect.size.y = dimension[3]
		collisionShape.shape = rect

		add_child(border)
		border.add_child(collisionShape)
		border.add_to_group("Obstacle")
		
func generateGrid(rng_seed: int):
	resetMap()
	_make_borders()
	tentId = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	
	for x in range(width):
		tiles.append([])
		for y in range(height):
			var pos := Vector2(x * tileSize - gridOffset, y * tileSize - gridOffset)
			
			var tile: Tile = tile_path.instantiate()
			self.add_child(tile)

			tile.position = pos
			var texture = null
			tile.name = str(x) +  " " + str(y)
			if (y % 2 == 0 and x % 2 == 0):
				texture = leftup
			elif (y % 2 == 0 and x % 2 == 1):
				texture = rightup
			elif (y % 2 == 1 and x % 2 == 0):
				texture = leftdown
			else:
				texture = rightdown
			tile.get_node("Sprite2D").texture = texture
			
			if rng.randi_range(0,10) < 2:
				tile.addContent(obstacles[rng.randi_range(0,len(obstacles)-1)].instantiate())
				obstaclePositions.append(Vector2(x,y))
			
			tiles[x].append(tile)

func getGridID():
	return gridID
	
func spawnTent(tile: Tile, team: int):
	if not multiplayer.is_server():
		return
	
	var tent: Tent = tentScene.instantiate()
	tent.setOwnership(team)
	tent.position = tile.position
	tile.hasTent = true
	tent.id = tentId
	tents[tentId] = tent
	tentId += 1
	add_child(tent, true)
	
	return tent
	
func getTent(id: int)-> Tent:
	return tents[id]
	
func getTile(x,y):
	return tiles[x][y]
	
func CoordToWpos(coord:Vector2):
	return Vector2(coord.x*tileSize-gridOffset, coord.y*tileSize-gridOffset)
	
func WPosToCoord(worldPos:Vector2):
	var x = int((worldPos.x + gridOffset) / tileSize)
	var y = int((worldPos.y + gridOffset) / tileSize)
	if (x >= width): x = width - 1
	if (y >= width): y = height - 1
	if (x <= 0): x = 0
	if (y <= 0): y = 0
	return Vector2(x,y)

#Start and end in World position
func findPath(start:Vector2, end:Vector2) -> Array[Vector2]:
	start = WPosToCoord(start)
	end = WPosToCoord(end)
	var stack = [start]
	var path = {start:null}
	var visited = {}
	
	while stack:
		var pos = stack.pop_front()
		if pos in visited: continue			
		
		#If found path
		if pos.is_equal_approx(end):
			var result = [end]
			while result.back() != null:
				for toPos in path.keys():
					var fromPos = path[toPos]
					if toPos.is_equal_approx(result.back()):
						#print(fromPos," -> ",toPos)
						result.append(fromPos)
						break
								
			result.pop_back() #remove null at end
			result.invert()
			for i in range(len(result)):
				result.append(CoordToWpos(result.pop_front()))
			return result
		
		#get neighbors
		for p in [[1,0],[-1,0],[0,1],[0,-1]]:
			var x = p[0]+pos.x
			var y = p[1]+pos.y
			var newPos = Vector2(x,y) 
			
			if x < 0 or y < 0 or x >= width or y >= height: continue
			if newPos in obstaclePositions: continue
			if newPos in visited: continue
				
			visited[pos]=""
			path[newPos] = pos
			stack.append(newPos)
			
	print("Did not find path")
	return []

# Loading pre-made maps (grids?)
func loadGrid() -> void:
	for x in range(width):
		tiles.append([])
		for y in range(height):
			var currentTile = "Tile" + str((x * height) + y)
			var tile = self.get_node(currentTile)
			
			var children = tile.get_children()
			if (len(children) > 1):
				if (children[1].is_in_group("Obstacle")):
					obstaclePositions.append(Vector2(x,y))
					
			tiles[x].append(tile)

func ui():
	return get_parent().get_node("Ui")

func _player_count():
	var playerCount = ui().get_node("playerCount")
	if multiplayer.has_multiplayer_peer():
		var count = get_tree().get_nodes_in_group("UniquePlayer").size()
		playerCount.text = "Players: " + str(count)
	else:
		playerCount.text = "Not connected"

func _check_win():
	var winner = _get_winner()
	if winner == null:
		return
	Multiplayer.resetMap()
	
	
func _get_winner():
	var last: Tent = null
	for key in tents.keys():
		var tent: Tent = tents[key]
		if last == null:
			last = tent
		if tent.getTeam() != last.getTeam():
			return null
	return last.getTeam() if last != null else null
		
var lastupdate := 0.0
func _process(delta: float):
	if lastupdate > 2:
		lastupdate = 0
		_player_count()
		if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
			_check_win()
	lastupdate += delta

func _on_join_pressed():
	Multiplayer._on_join_pressed()

func _on_host_pressed():
	Multiplayer._on_host_pressed()


func _on_start_game_pressed():
	Multiplayer._on_start_game_pressed()


func _on_new_map_pressed():
	Multiplayer._on_new_map_pressed()
