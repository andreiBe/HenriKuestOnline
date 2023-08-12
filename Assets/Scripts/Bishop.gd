extends Node2D

class_name Bishop
var _team: int = 0
var _home: Node2D = null
var _followers = []
var _isBot: bool
var _parent: Node

func _init(isBot: bool, parent: Node):
	_isBot = isBot
	_parent = parent
	
func getHome():
	return _home
	
func setHome(home: Node2D):
	_home = home

func getTeam():
	return _team

func setTeam(team: int):
	_team = team

func addFollowers(followers: Array[Fighter]):
	_followers.append_array(followers)
	
func takeFollowers():
	var list = _followers.duplicate()
	_followers.clear()
	return list

func numberOfFollowers() -> int:
	return _followers.size()
	
func destroyIfNotHuman():
	if _isBot:
		_parent.queue_free()
