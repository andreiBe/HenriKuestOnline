extends Node

var recruit

# Declare member variables here. Examples:
var recruitable = false
var player: Player
var grid: Grid
var _tent: Tent
var particle_effect_scene = preload("res://Assets/Scenes/recruit_particle.tscn")
var playersInside: Array[Player] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_tent = get_parent()
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	recruit = get_parent().get_node("KeyHelper")
	recruit.visible = false
	grid = get_tree().current_scene.get_node("GridManager")

func _on_body_entered(body:Node):	
	if not body.is_in_group("Player"):
		return
	var p := body as Player
	playersInside.append(p)
	
	#var bishop := p.bishop as Bishop	
	#if bishop.getTeam() == _tent.getTeam() and player.is_local_authority():
	#	player = body
	#	recruitable = true
	#	recruit.visible = true

func _on_body_exited(body:Node):
	if not body.is_in_group("Player"):
		return
	var p := body as Player
	playersInside.erase(p)
	
	#var bishop := player.bishop
	#if bishop.getTeam() == _tent.getTeam():
	#	recruitable = false
	#	recruit.visible = false
		
func _query_players_inside():
	for p in playersInside:
		var bishop := p.bishop
		if bishop.getTeam() == _tent.getTeam():
			if p.is_local_authority():	
				recruit.visible = true
			player = p
			recruitable = true
			return
	recruitable = false
	recruit.visible = false
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	_checkInput()
	_query_players_inside()

func inputFromCorrectPlayer(action: String):
	return (Input.is_action_just_pressed(action)
	and recruitable
	and player.is_local_authority()
	and player.bishop.getTeam() == _tent.getTeam())
	
func _checkInput():
	if inputFromCorrectPlayer("command_troops"):
		grid.Multiplayer.recruit(_tent.id)
	if inputFromCorrectPlayer("deploy_defenders"):
		grid.Multiplayer.deploy(_tent.id)


func recruitSoldiers():
	if _tent.isInCombat(): return
	var soldiers = _tent.takeDefendersFromTent()
	if (soldiers.size() == 0): return
	player.addFollowers(soldiers)
	var particle = particle_effect_scene.instantiate()
	add_child(particle)
	particle.global_position = self.global_position
	_tent.resetTimer()
	
func deploySoldiers():
	var soldiers = player.bishop.takeFollowers()
	if soldiers.size() == 0: return
	_tent.addSoldiers(soldiers)
	
	var particle = particle_effect_scene.instantiate()
	add_child(particle)
	particle.global_position = self.global_position
	_tent.resetTimer()
