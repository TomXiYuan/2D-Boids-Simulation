extends Node
class_name FlockManager

@export var separationRadius := 60.0
@export var cohesionRadius := 80.0
@export var alignmentRadius := 80.0

@export var separationWeight := 1.8
@export var cohesionWeight := 1.0
@export var alignmentWeight := 1.0

var boids : Array[Boid]

func _ready() -> void:
	call_deferred("addBoids")

func addBoids():
	boids.assign(get_tree().get_nodes_in_group("boids"))

func _physics_process(delta: float) -> void:

	for boid in boids:
		boid.acc += _separate(boid) * separationWeight
		boid.acc += _cohere(boid) * cohesionWeight
		boid.acc += _align(boid) * alignmentWeight

	for boid in boids:
		boid.update(delta)

func _separate(boid: Boid) -> Vector2:
	var target := Vector2.ZERO
	var total := 0
	for other in boids:
		if other == boid:
			continue
		var dst = boid.position.distance_to(other.position)
		if dst < separationRadius and dst > 0.0:
			target += (boid.position - other.position) / (dst * dst)
			total += 1
	if total == 0:
		return Vector2.ZERO
	target = (target / total).normalized() * boid.maxSpeed
	return (target - boid.velocity).limit_length(boid.maxForce)

func _cohere(boid: Boid) -> Vector2:
	var center := Vector2.ZERO
	var total := 0
	for other in boids:
		if other == boid:
			continue
		var dst = boid.position.distance_to(other.position)
		if dst < cohesionRadius:
			center += other.position
			total += 1
	if total == 0:
		return Vector2.ZERO
	var target = ((center / total) - boid.position).normalized() * boid.maxSpeed
	return (target - boid.velocity).limit_length(boid.maxForce)

func _align(boid: Boid) -> Vector2:
	var target := Vector2.ZERO
	var total := 0
	for other in boids:
		if other == boid:
			continue
		var dst = boid.position.distance_to(other.position)
		if dst < alignmentRadius:
			target += other.velocity
			total += 1
	if total == 0:
		return Vector2.ZERO
	target = (target / total).normalized() * boid.maxSpeed
	return (target - boid.velocity).limit_length(boid.maxForce)
