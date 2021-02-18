extends KinematicBody

export var speed = 10
export var acceleration = 5
export var jump_power = 30
export var gravity = 0.98
export var mouse_sensitivity = 0.3
export var max_pitch = 90
export var min_pitch = -90

onready var head = $Head
onready var camera = $Head/Camera
onready var raycast = $Head/Camera/RayCast
onready var springArm = $Head/Camera/SpringArm
onready var position3d = $Head/Camera/Position3D

var velocity = Vector3.ZERO
var holding = false
var held_object
var pickup_point

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion or event is InputEventJoypadMotion:
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		head.rotation_degrees.x -= event.relative.y * mouse_sensitivity
		head.rotation_degrees.x = clamp(head.rotation_degrees.x, min_pitch, max_pitch)

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	handle_movement(delta)
	interact()
	scale_held_object()
	
func handle_movement(delta):
	var head_basis = head.get_global_transform().basis
	var dir = Vector3.ZERO 
	if Input.is_action_pressed("move_forward"):
		dir -= head_basis.z
	elif Input.is_action_pressed("move_backward"):
		dir += head_basis.z
	if Input.is_action_pressed("move_left"):
		dir -= head_basis.x
	elif Input.is_action_pressed("move_right"):
		dir += head_basis.x
	dir = dir.normalized()
	velocity = velocity.linear_interpolate(dir * speed, acceleration * delta)
	velocity.y -= gravity
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump_power
	velocity = move_and_slide(velocity, Vector3.UP)

func scale_held_object():
	if holding:
		var moveDist = held_object.global_transform.origin - pickup_point
		print(moveDist)
#		if moveDist > 0:
#			held_object.set_scale(Vector3(1/moveDist, 1/moveDist, 1/moveDist))
#		elif moveDist < 0:
#			held_object.set_scale(Vector3(moveDist, moveDist, moveDist))

func interact():
	if Input.is_action_just_pressed("interact"):
		if !holding:
			if raycast.is_colliding():
				var interactable_object = raycast.get_collider()
				var collision_point = raycast.get_collision_point()
				if interactable_object.get_collision_layer() == 4:
					# the object is grabbable
					held_object = interactable_object
					get_parent().remove_child(held_object)
					springArm.add_child(held_object)
					held_object.transform.origin = Vector3(0, 0, -5)
					pickup_point = collision_point
					held_object.set_sleeping(true)
					holding = true
				elif interactable_object.get_collision_layer() == 5:
					# the object is interactable but not grabbable
					pass
		else:
			var new_transform = held_object.global_transform
			held_object.get_parent().remove_child(held_object)
			get_parent().add_child(held_object)
			held_object.transform.origin = Vector3.ZERO
			held_object.global_transform = new_transform
			held_object.set_sleeping(false)
			holding = false
