extends Button

var sceneList = ["res://Assets/Scenes/Intro.tscn", "res://Assets/Scenes/LevelTutorial.tscn", "res://Assets/Scenes/Level1.tscn", "res://Assets/Scenes/Level2.tscn", "res://Assets/Scenes/Level3.tscn", "res://Assets/Scenes/Main.tscn"]


func _ready():
	var currentScene = get_parent().get_parent().get_parent().get_node("GridManager").gridID
	if (currentScene < (len(sceneList) - 1)):
		self.text = "Restart level"
	else:
		self.text = "Play Randomized"
	pass # Replace with function body.

func _pressed():
	var currentScene = get_parent().get_parent().get_parent().get_node("GridManager").gridID
	get_tree().change_scene_to_file(sceneList[currentScene])
