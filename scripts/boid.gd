extends Node2D
class_name Boid

var velocity: Vector2
var acc: Vector2

@export var maxSpeed: float = 6.0
@export var minSpeed: float = 4.0
@export var maxForce: float = 2.5
@export var smoothing: float = 1.25

@export var sideRayCount: int = 10
@export var raySpreadAngle: float = deg_to_rad(90.0)
@export var maxViewDst := 100.0
@export var obstacleMask: int = 1
@export var avoidWeight := 10.0

@export var omniAvoidRadius: float = 500.0
@export var omniAvoidWeight: float = 20.0
@onready var proximityArea: Area2D = $Area2D

@export var wrapBounds := Rect2(-1024.0, -512.0, 2048.0, 1024.0)

func _ready() -> void:
	add_to_group("boids")
	proximityArea.body_entered.connect(_on_body_entered)
	proximityArea.body_exited.connect(_on_body_exited)

func update(delta: float) -> void:
	var forwardAvoidAcc = avoid()
	var omniAvoidAcc = omniAvoid()
	var targetVelocity = velocity.normalized() * maxSpeed
	# Does omniAvoid make forwardAvoid irrelevant?
	targetVelocity += acc + forwardAvoidAcc + omniAvoidAcc

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
	if position.x < wrapBounds.position.x:
		position.x = wrapBounds.end.x
	elif position.x > wrapBounds.end.x:
		position.x = wrapBounds.position.x
	if position.y < wrapBounds.position.y:
		position.y = wrapBounds.end.y
	elif position.y > wrapBounds.end.y:
		position.y = wrapBounds.position.y

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

	if not found:
		chosenDir = (global_position - forwardResult.position).normalized()

	var strength = 1.0 - (hitDst / maxViewDst)
	strength = clamp(strength, 0.0, 1.0)

	var target = chosenDir * maxSpeed
	var steer = (target - velocity).limit_length(5.0)

	return steer * avoidWeight * strength

func castRay(state: PhysicsDirectSpaceState2D, dir: Vector2) -> Dictionary:
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + dir * maxViewDst
	)
	query.collision_mask = obstacleMask
	return state.intersect_ray(query)
	
var nearbyBodies: Array[Node2D] = []

func _on_body_entered(body: Node2D) -> void:
	nearbyBodies.append(body)
	
func _on_body_exited(body: Node2D) -> void:
	nearbyBodies.erase(body)
	
func omniAvoid() -> Vector2:
	var steer := Vector2.ZERO
	for body in nearbyBodies:
		var offset = global_position - body.global_position
		var dst = offset.length()
		if dst < omniAvoidRadius and dst > 0.001:
			steer += offset.normalized()
	
	return steer.limit_length(maxForce) * omniAvoidWeight
