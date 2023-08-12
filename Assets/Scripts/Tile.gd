class_name Tile
extends Node2D


var _content : Node
var hasTent = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func addContent(content : Node):
	_content = content
	add_child(_content)
	
func clearTile():
	self.remove_child(_content)
