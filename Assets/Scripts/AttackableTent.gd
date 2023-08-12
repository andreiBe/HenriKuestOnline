extends Node

class_name AttackableTent
const _Bishop = preload("res://Assets/Scenes/characters/EnemyPlayer.tscn")
var _BattleScene = preload("res://Assets/Scenes/Battle.tscn")
var _rng = RandomNumberGenerator.new()

var _tent: Tent = null
var _currentBattle: Battle = null
var _currentAttacker: Bishop = null
var _grid:Grid = null

var _attackTimer: Timer = Timer.new()
@export var minDefendersToAttack = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(_attackTimer)
	_attackTimer.wait_time = 1
	_attackTimer.connect("timeout", Callable(self, "_tryAttack"))
	_attackTimer.start()
	
	_grid = get_tree().current_scene.get_node("GridManager")
	_rng.randomize()
	_tent = get_parent()
	connect("body_entered", Callable(self, "_on_body_entered"))

	
func _on_body_entered(body:Node) -> void:
	#tents can only be attacked server side
	if not multiplayer.is_server():
		return
	#normal soldiers should not cause an attack
	if !body.is_in_group("Bishop"): 
		return
	var bishop:= body.bishop as Bishop
	#the attack	comes from this tent. This is needed because bot
	#players can deploy soldiers to their own tents
	#if this would not exist, they couldn't attack
	if bishop.getHome() == _tent:
		return
	#no attackers
	if bishop.numberOfFollowers() == 0:
		bishop.destroyIfNotHuman()
		return
	#own village
	if bishop.getTeam() == getTeam():
		# add units if bot
		if not _grid.Multiplayer.isPlayer(bishop.getTeam()):			
			_tent.addSoldiers(bishop.takeFollowers())
			bishop.destroyIfNotHuman()
		return
	
	#only one team can attack a tent at the same time
	if _currentAttacker != null and _currentAttacker.getTeam() != bishop.getTeam():
		return
	#only one battle at the same time
	if inBattle():
		_currentBattle.addAttackers(bishop.takeFollowers())
		return
	_currentAttacker = bishop
	_currentBattle = _BattleScene.instantiate()
	add_child(_currentBattle)
	_attackTimer.stop()
	_tent.stopSpawnTimer()
	
#bots can attack
func _tryAttack() -> void:
	var x = _tent.getDefenderAmount()
	if x < minDefendersToAttack:
		return
	#function to define to chance for an attack to occur
	var a = 1.67
	var b = 5
	var c = -16.7
	#attacks can only be started from the server side
	if not _grid.Multiplayer.isPlayer(getTeam()) and multiplayer.is_server():
		if _rng.randi_range(0, 100) < a*pow(x,1.2)+b*x+c:
			_attack()
			
func _attack() -> void:
	var playerTents = _getAllEnemyTents()
	
	if playerTents.size() == 0:
		return
	
	var closestTent: Tent = null
	for i in playerTents:
		var tent := i as Tent 
		if tent.isInCombat(): 
			continue
		if closestTent == null: 
			closestTent = tent
		var dist = tent.position.distance_to(_tent.position)
		var mindist = closestTent.position.distance_to(_tent.position)
		if dist < mindist:
			closestTent = tent
	#No available tents; skip attack
	if closestTent == null: return

	attack_tent(closestTent)
	
func attack_tent(tent: Tent) -> void:
	var enemyPlayer: BotPlayer = _Bishop.instantiate()
	enemyPlayer.bishop.setTeam(getTeam())
	enemyPlayer.bishop.setHome(_tent)
	enemyPlayer.position = _tent.position

	var soldiers = _tent.takeDefendersFromTent()
	
	for i in soldiers:
		var soldier := i as Fighter
		soldier.setTarget(enemyPlayer)
	enemyPlayer.bishop.addFollowers(soldiers)
	
	_grid.add_child(enemyPlayer, true)
	enemyPlayer.setTarget(tent)

func _getAllEnemyTents() -> Array[Tent]:
	var tents: Array[Tent] = []
	for member in get_tree().get_nodes_in_group("Tents"):
		var tent := member as Tent
		if tent.getTeam() != getTeam():
			tents.append(tent)
	return tents
	
func getCurrentAttacker()-> Bishop:
	return _currentAttacker

func getTeam() -> int:
	return _tent.getTeam()

func getTent() -> Tent:
	return _tent
	
func inBattle() -> bool:
	return _currentBattle != null
	
func endBattle(winnerTeam, remainingTroops):
	if _tent.getTeam() != winnerTeam:
		_tent.setOwnership(winnerTeam)
		_tent.addSoldiers(remainingTroops)
	_attackTimer.start()
	_tent.startSpawnTimer()
	_currentBattle = null
	_currentAttacker = null
	
