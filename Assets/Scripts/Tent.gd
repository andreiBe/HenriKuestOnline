extends Node2D

class_name Tent
# Declare member variables here.
var timer = Timer.new()
var currentProduction = 1
var soldierScene = preload("res://Assets/Scenes/characters/Soldier.tscn")
var _soldiers: Array[Fighter] = []
@export var ownerPlayerNumber = 0
@export var timeBetweenSpawns = 20
var grid: Grid
@export var id = 0

func getNextWaitTime():
	var x = len(_soldiers)
	var a = 1.17
	var b = -1.83
	var c = 3
	return a*x*x+b*x+c
	
# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(timer)
	resetTimer()
	timer.connect("timeout", Callable(self, "_handleSpawning"))
	grid = get_tree().current_scene.get_node("GridManager")
	


# Called by timer countdown. Spawns the unit currently in production.
func _handleSpawning():
	if not multiplayer.is_server():
		return
	var spawn: Fighter = soldierScene.instantiate()
	spawn.setTeam(ownerPlayerNumber)
	spawn.setTarget(self)
	
	grid.add_child(spawn,true)
	spawn.position.x = self.position.x
	spawn.position.y = self.position.y
	_soldiers.append(spawn)
	
	resetTimer()
	
	
	
	
# Change the ownership of the tent.
func setOwnership(targetPlayerNumber):
	ownerPlayerNumber = targetPlayerNumber
	($Texture as Sprite2D).region_rect = Rect2(ownerPlayerNumber*13, 0, 13, 17)
	
	
func addSoldiers(tempSoldiers):
	for soldier in tempSoldiers:
		soldier.modulate = Color(1, 1, 1)
		var follow_icon = soldier.get_node("FollowIcon")
		if follow_icon != null:
			follow_icon.visible = false
		soldier.setTarget(self)
	_soldiers.append_array(tempSoldiers)
	resetTimer()
	
func distance_to(anotherTent: Tent):
	return position.distance_to(anotherTent.position)


func resetTimer():
	timer.stop()
	timer.set_wait_time(getNextWaitTime())
	timer.start()
	
func isInCombat():
	return ($Attack as AttackableTent).inBattle()
	
func getDefenderAmount():
	return len(_soldiers)

func stopSpawnTimer():
	timer.stop()


func startSpawnTimer():
	timer.start()
	
func getTeam():
	return ownerPlayerNumber

# New battle system stuff below
func takeDefendersFromTent() -> Array[Fighter]:
	var defenders = _soldiers.duplicate()
	_soldiers.clear()
	resetTimer()
	return defenders
	
func getSoldierLink()->Array[Fighter]:
	return _soldiers
	
func getCurrentOwner():
	return ownerPlayerNumber
