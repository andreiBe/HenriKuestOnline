extends Node

class_name Multiplayer

var peer: ENetMultiplayerPeer
@export var player_scene: PackedScene
@export var teams: Array[int] = []
var _rng_seed: int = 0
var PORT: int = 34154
var _grid: Grid = null

func _enter_tree():
	_grid = get_parent()
	multiplayer.multiplayer_peer = null
	
func resetMap():
	_rng_seed = RandomNumberGenerator.new().randi_range(0, 100000)
	_grid.resetMap()
	_build.rpc(_rng_seed)
	
func _reset():
	_rng_seed = RandomNumberGenerator.new().randi_range(0, 100000)
	multiplayer.multiplayer_peer = null
	peer = ENetMultiplayerPeer.new()
	teams = []
	_grid.reset()
	
func _host():
	peer.create_server(PORT)
	if not multiplayer.peer_connected.is_connected(_add_player):
		multiplayer.peer_connected.connect(_add_player)
	if not multiplayer.peer_disconnected.is_connected(_remove_player):
		multiplayer.peer_disconnected.connect(_remove_player)
	multiplayer.multiplayer_peer = peer
	_add_player()
	
func _on_host_pressed():
	print("Host pressed!")
	_reset()
	_ui().get_node("startGame").disabled = false
	_ui().get_node("newMap").disabled = false
	
	get_tree().process_frame.connect(_host, CONNECT_ONE_SHOT)


func _add_player(id: int = 1):
	var maxteam = 0
	for team in range(4):
		if team not in teams:
			maxteam = team
			break
	teams.append(maxteam)
	
	var player: Player = player_scene.instantiate()
	player.name = str(id)
	_grid.add_child(player)
	_set_team.rpc(id, maxteam)
	
	_build.rpc_id(id, _rng_seed)
	
func recruit(id: int):
	_recruit.rpc_id(1, id)

func deploy(id: int):
	_deploy.rpc_id(1, id)
	
func isPlayer(team: int):
	return team in teams
	
	
@rpc("authority", "call_local", "reliable")
func _set_team(id: int, team: int):
	_grid.get_node(str(id)).setTeam(team)
	
@rpc("authority", "call_local", "reliable")
func _build(rng_seed: int):
	_grid.generateGrid(rng_seed)

@rpc("any_peer", "call_local", "reliable")
func _deploy(id):
	_grid.getTent(id).get_node("Recruitment").deploySoldiers()

@rpc("any_peer", "call_local", "reliable")
func _recruit(id):
	_grid.getTent(id).get_node("Recruitment").recruitSoldiers()
	
func _remove_player(id):
	print("Removing player ", id)
	var player: Player = _grid.get_node(str(id))
	var i = teams.find(player.bishop.getTeam())
	teams.remove_at(i)
	player.queue_free()

func _ui():
	return _grid.ui()
	
func _join():
	var ipTextField = _ui().get_node("joinIP")
	var ip: String = ( ipTextField as LineEdit).get_text()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	
func _on_join_pressed():
	_reset()
	_ui().get_node("startGame").disabled = true
	_ui().get_node("newMap").disabled = true
	get_tree().process_frame.connect(_join, CONNECT_ONE_SHOT)
	
func _on_start_game_pressed():
	_grid.resetTents()
	_grid.generateTents(_rng_seed)
	
func _on_new_map_pressed():
	resetMap()

