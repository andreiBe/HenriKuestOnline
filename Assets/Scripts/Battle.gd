extends Node
class_name Battle
var _battleSymbol: Node2D
var _defenders: Array[Fighter] = []
var _attackers: Array[Fighter] = []
var _battleTimer = Timer.new()
var _attacked_tent: AttackableTent
var _attackingPlayerTeam: int


func _ready():
	_startBattle()

func _startBattle():
	_attacked_tent = get_parent()
	var attackingPlayer = _attacked_tent.getCurrentAttacker()
	_attackingPlayerTeam = attackingPlayer.getTeam()
	_battleSymbol = _attacked_tent.getTent().get_node("BattleSymbol")
	_defenders = _attacked_tent.getTent().getSoldierLink()
	addAttackers(attackingPlayer.takeFollowers())
	_setUpBattleTimer()
	_setUpBattleSymbol()
	attackingPlayer.destroyIfNotHuman()
		
func _setUpBattleTimer():
	add_child(_battleTimer)
	_battleTimer.wait_time = 1
	_battleTimer.connect("timeout", Callable(self, "_simulateCombat"))
	_battleTimer.start()


func _setUpBattleSymbol():
	_battleSymbol.visible = true

# Ends combat if runs out of attackers or defenders, otherwise kills units
func _simulateCombat():	
	if _defenders.size() == 0 or _attackers.size() == 0:
		_endBattle()
	else:
		_killUnits()
	


# Kills one attacker and one defender
func _killUnits():
	_defenders.pop_back().queue_free()
	_attackers.pop_back().queue_free()

func addAttackers(newAttackers):
	for attacker in newAttackers:
		_attackers.append(attacker)
		attacker.modulate = Color(1, 10, 1)
		attacker.get_node("FollowIcon").visible = false
		attacker.setTarget(_attacked_tent.getTent())
	
func _checkWinner():	
	if _defenders.size() == 0:
		return [_attackingPlayerTeam, _attackers]
	else:
		return [_attacked_tent.getTeam(), _defenders]
		
func _endBattle():
	_battleSymbol.visible = false
	_battleTimer.stop()
	var winner = _checkWinner()
	_attacked_tent.endBattle(winner[0], winner[1])
	queue_free()

