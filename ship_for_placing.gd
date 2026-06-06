extends Node2D

class_name Ship

@export var ship_name := ""

@export var length := 3

var positions: Array[Vector2i] = []

var is_vertical := false

var is_placed := false
