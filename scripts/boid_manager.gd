extends Node

@export var spawnRadius : float
@export var radius : float
@export var region : Rect2

@export var n : int = 100

const boidScene : PackedScene = preload("res://scenes/boid.tscn")
var sampler : PoissonDiskSampler
var boids : Array[Boid]

@export var maxSpeed : float
@export var maxForce : float

@export var s : float
@export var c : float
@export var a : float

@export var boidContainer : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sampler = PoissonDiskSampler.new()
	spawnBoids()
	call_deferred("addBoids")

func addBoids():
	boids.assign(get_tree().get_nodes_in_group("boids"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	separate()
	cohere()
	align()
	for boid in boids:
		boid.update()
	
func spawnBoids() -> void:
	var coordinates : Array[Vector2] = sampler.generatePoints(spawnRadius, region)
	var numberOfBoids = min(n, coordinates.size())
	for i in range(numberOfBoids):
		var idx = randi_range(0, coordinates.size()-1)
		var boid = boidScene.instantiate()
		boid.position = coordinates[idx]
		boid.velocity = Vector2.RIGHT.rotated(randf_range(0, TAU))
		boid.maxSpeed = maxSpeed
		coordinates.remove_at(idx)
		boidContainer.add_child(boid)

func separate():
	for i in boids.size():
		var target = Vector2.ZERO
		var total = 0
		for j in boids.size():
			if i == j:
				continue
			var dst = boids[i].position.distance_to(boids[j].position)
			if dst < radius:
				var diff := boids[i].position - boids[j].position
				diff /= dst * dst
				target += diff
				total += 1
		
		if total == 0:
			continue
		
		target /= total
		target = target.normalized() * maxSpeed
		var force : Vector2 = target - boids[i].velocity
		force = force.limit_length(maxForce)
		
		force *= s
		boids[i].acc += force

func cohere() -> void:
	for i in boids.size():
		var center : Vector2
		var total : int = 0
		for j in boids.size():
			if i == j:
				continue
			var dst = boids[i].position.distance_to(boids[j].position)
			if dst < radius:
				center += boids[j].position
				total += 1
		
		if total == 0:
			continue
			
		center /= total
		var target : Vector2 = center - boids[i].position
		target = target.normalized() * maxSpeed
		var force : Vector2 = target - boids[i].velocity
		force = force.limit_length(maxForce)
		
		force *= c
		boids[i].acc += force

func align() -> void:
	for i in boids.size():
		var target : Vector2
		var total : int = 0
		for j in boids.size():
			if i == j:
				continue
			var dst = boids[i].position.distance_to(boids[j].position)
			if dst < radius:
				target += boids[j].velocity
				total += 1
		
		if total == 0:
			continue
		
		target /= total
		target = target.normalized() * maxSpeed
		
		var force : Vector2 = target - boids[i].velocity
		force = force.limit_length(maxForce)
		
		force *= a
		boids[i].acc += force
