extends CharacterBody3D

signal toggle_inventory()

@export var inventory_data : InventoryData

@onready var head = $head
@onready var camera = $head/Camera3D
@onready var mesh = $MeshInstance3D2
@onready var MainPlayer = get_parent().get_node("WebSocketClient")
@onready var shootAnim = $head/Camera3D/Rifle/AnimationPlayer
@onready var gun_barrel = $head/Camera3D/Rifle/RayCast3D
@onready var interact_ray = $head/Camera3D/InteractRay
@onready var inventory = $"../UI/InventoryInterface"

const SPEED = 2.0
const JUMP_VELOCITY = 2.5
const CROUCH_Y_OFFSET = -0.2
var isCrouch = false
const SENSITIVITY = 0.003
var bullet = load("res://models/rifles/bullet.tscn")
var instanceBullet
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var last_position = Vector3()


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var json_like_string = '{"CMD": "GP", "uid": "%s"}' % [Global.uid]
	MainPlayer.send(json_like_string)
	last_position = global_transform.origin
	
	var aabb = mesh.get_aabb()
	var center_y = aabb.position.y + aabb.size.y / 2
	
	var mesh_transform = mesh.transform
	mesh_transform.origin.y -= center_y
	mesh.transform = mesh_transform
	
func _input(event):
	if event is InputEventMouseMotion and !inventory.visible:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		mesh.rotate_y(-event.relative.x * SENSITIVITY)
		var json_like_string = '{"CMD": "ROT", "uid": "%s", "rotY": %f}' % [Global.uid, mesh.rotation.y]
		MainPlayer.send(json_like_string)
	
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory.emit()

	if Input.is_action_just_pressed("interact"):
		interact()

func interact() -> void:
	if interact_ray.is_colliding():
		interact_ray.get_collider().player_interact(self)

func get_drop_position() -> Vector3:
	var direction = -camera.global_transform.basis.z
	return camera.global_position + direction

func set_position_player(posX: float, posY: float, posZ: float) -> void:
	self.global_transform.origin = Vector3(posX, posY, posZ)
	last_position = global_transform.origin

func _physics_process(delta):
	# Add the gravity.
	if inventory.visible:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle MouseClickL
	if Input.is_action_pressed("MouseL"):
		if !shootAnim.is_playing():
			shootAnim.play("Shoot")
			instanceBullet = bullet.instantiate()
			instanceBullet.position = gun_barrel.global_position
			instanceBullet.transform.basis = gun_barrel.global_transform.basis
			get_parent().add_child(instanceBullet)
	
	# Handle crouch.
	if Input.is_action_pressed("crouch"):
		if not isCrouch:
			isCrouch = true
			camera.transform.origin.y += CROUCH_Y_OFFSET
	else:
		if isCrouch:
			isCrouch = false
			camera.transform.origin.y -= CROUCH_Y_OFFSET

	var input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	var current_position = global_transform.origin
	if current_position != last_position:
		last_position = current_position
		var rotation_y = mesh.rotation.y
		var json_like_string = '{"CMD": "PP", "uid": "%s", "posX": %f, "posY": %f, "posZ": %f, "rotY": %f}' % [Global.uid, current_position.x, current_position.y, current_position.z, rotation_y]
		MainPlayer.send(json_like_string)
	
