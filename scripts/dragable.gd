extends RigidBody2D

var is_dragging: bool = false
var click_offset: Vector2 = Vector2.ZERO
@export var stiffness: float = 400.0
@export var damping: float = 40.0
@export var friction = 10.0

func _ready() -> void:
	input_pickable = true

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		is_dragging = true
		click_offset = global_position - get_global_mouse_position()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging = false

func _physics_process(delta: float) -> void:
	if is_dragging:
		var target_position = get_global_mouse_position() + click_offset
		var displacement = target_position - global_position
		var accel = displacement * stiffness - linear_velocity * damping
		linear_velocity += accel * delta
	if linear_velocity != Vector2.ZERO:
		linear_velocity = linear_velocity.lerp(Vector2.ZERO, friction * delta)
