extends Node2D

class_name Boid

var targetVelocity : Vector2
var velocity : Vector2
var acc : Vector2

var maxSpeed : float
var minSpeed : float = 4.0

@export var sideRayCount : int = 10
@export var raySpreadAngle : float = deg_to_rad(90.0)
@export var maxViewDst := 100.0

@export var obstacleMask : int = 1
@export var a := 10.0

@export var smoothing: float = 1.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.add_to_group("boids")

func update(delta: float) -> void:
	var avoidAcc = avoid()
	targetVelocity = velocity.normalized() * maxSpeed
	targetVelocity += acc + avoidAcc

	velocity = velocity.lerp(targetVelocity, 1.0 - exp(-smoothing * delta))
	if velocity.length() > maxSpeed:
		velocity = velocity.limit_length(maxSpeed)
	elif velocity.length() < minSpeed:
		velocity = velocity.normalized() * minSpeed
		
	position += velocity
	_wrap()
	queue_redraw()
	acc = Vector2.ZERO

func _wrap() -> void:
	if position.x < -1024.0:
		position.x = 1024.0
	elif position.x > 1024.0:
		position.x = -1024.0
	if position.y < -512.0:
		position.y = 512.0
	elif position.y > 512.0:
		position.y = -512.0
	
func _draw() -> void:
	if velocity == Vector2.ZERO:
		return
	var heading = velocity.angle()
	var points = PackedVector2Array([
		Vector2(20, 0),
		Vector2(-10, 10),
		Vector2(-10, -10)
	])
	
	draw_set_transform(Vector2.ZERO, heading, Vector2.ONE)
	draw_colored_polygon(points, Color.WHITE)

# Probably won't work for all cases
func avoid() -> Vector2:
	if velocity == Vector2.ZERO:
		return Vector2.ZERO

	var state = get_world_2d().direct_space_state
	var forwardDir = velocity.normalized()

	var forwardResult := castRay(state, forwardDir)
		
	if forwardResult.is_empty():
		return Vector2.ZERO
	
	var hitDst = global_position.distance_to(forwardResult.position)

	var chosenDir := Vector2.ZERO
	var found := false
	var angleStep = raySpreadAngle / float(sideRayCount * 2)

	for i in range(1, sideRayCount + 1):
		var angle = angleStep * i
		# There is probably a way to reduce repeated blocks
		var rightDir = forwardDir.rotated(angle)
		var rightResult = castRay(state, rightDir)
		if rightResult.is_empty():
			chosenDir = rightDir
			found = true
			break

		var leftDir = forwardDir.rotated(-angle)
		var leftResult = castRay(state, leftDir)
		if leftResult.is_empty():
			chosenDir = leftDir
			found = true
			break

	# Facing a wall
	if not found:
		chosenDir = (global_position - forwardResult.position).normalized()

	var strength = 1.0 - (hitDst / maxViewDst)
	strength = clamp(strength, 0.0, 1.0)

	var target = chosenDir * maxSpeed
	var steer = target - velocity
	
	# TODO: Create a variable for steer limit
	steer = steer.limit_length(5.0)
	
	return steer * a * strength

func castRay(state: PhysicsDirectSpaceState2D, dir: Vector2) -> Dictionary:
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + dir * maxViewDst
	)
	query.collision_mask = obstacleMask
	return state.intersect_ray(query)
