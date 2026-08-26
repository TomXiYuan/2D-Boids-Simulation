extends Camera2D

@export var dragSpeed := 5.0
var targetPos := Vector2.ZERO
var isDragging := false

@export var minZoom := 0.5
@export var maxZoom := 2.5
@export var zoomSpeed := 5.0
@export var zoomSmoothSpeed := 8.0
var targetZoom := Vector2.ONE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	targetPos = global_position
	
	limit_left = -1500
	limit_right = 1500
	limit_top = -1000
	limit_bottom = 1000
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		isDragging = event.pressed
	if event is InputEventMouseMotion and isDragging:
		targetPos -= event.relative / zoom
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoomCamera(zoomSpeed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoomCamera(-zoomSpeed)
	
	# MacOS functionality
	if event is InputEventMagnifyGesture:
		zoomCamera((event.factor - 1.0) * zoomSpeed * 4.0)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = global_position.lerp(targetPos, dragSpeed * delta)
	zoom = zoom.lerp(targetZoom, zoomSmoothSpeed * delta)
	targetPos = clampToLimits(targetPos)

func zoomCamera(speed: float) -> void:
	var newZoom: Vector2 = zoom + Vector2(speed, speed)
	newZoom.x = clamp(newZoom.x, minZoom, maxZoom)
	newZoom.y = clamp(newZoom.y, minZoom, maxZoom)
	targetZoom = newZoom

func clampToLimits(pos: Vector2) -> Vector2:
	# Divide by two to prevent overflow when dragging near edge limits.
	var halfExtents: Vector2 = get_viewport_rect().size / zoom / 2.0
	var minPos := Vector2(limit_left, limit_top) + halfExtents
	var maxPos := Vector2(limit_right, limit_bottom) - halfExtents
	return pos.clamp(minPos, maxPos)
	
