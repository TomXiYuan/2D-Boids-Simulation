extends Node

@export var spawnRadius : float
@export var region : Rect2

@export var n : int = 100

const boidScene : PackedScene = preload("res://scenes/boid.tscn")
var sampler : PoissonDiskSampler
var boids : Array[Boid]

@export var boidContainer : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sampler = PoissonDiskSampler.new()
	spawnBoids()

func spawnBoids() -> void:
	var coordinates : Array[Vector2] = sampler.generatePoints(spawnRadius, region)
	var numberOfBoids = min(n, coordinates.size())
	for i in range(numberOfBoids):
		var idx = randi_range(0, coordinates.size()-1)
		var boid = boidScene.instantiate()
		if boid == null:
			push_error("Failed to instantiate boidScene — check boid.gd for compile errors")
			continue
		boid.position = coordinates[idx]
		boid.velocity = Vector2.RIGHT.rotated(randf_range(0, TAU))
		coordinates.remove_at(idx)
		boidContainer.add_child(boid)
