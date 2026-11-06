
extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var gravity = 9.8
var speed = 5.0
var jump_force = 4.5
var mouse_sensitivity = 0.002

var camera_rotation = 0.0

func _ready():
    create_world_collision()
    create_player()

func create_world_collision():
    var floor = StaticBody3D.new()
    floor.name = "FloorCollision"
    add_child(floor)

    var shape = CollisionShape3D.new()
    var box = BoxShape3D.new()
    box.size = Vector3(200, 1, 200)
    shape.shape = box
    floor.add_child(shape)
    floor.position.y = -0.6

func create_player():
    player = CharacterBody3D.new()
    player.name = "Player"
    add_child(player)
    player.position = Vector3(0, 1.5, 0)

    var collision = CollisionShape3D.new()
    var capsule = CapsuleShape3D.new()
    capsule.radius = 0.4
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    player.add_child(collision)

    camera = Camera3D.new()
    camera.position.y = 1.6
    camera.current = true
    player.add_child(camera)

func _physics_process(delta):
    if not player:
        return

    if not player.is_on_floor():
        player.velocity.y -= gravity * delta

    var direction = Vector3.ZERO

    if Input.is_key_pressed(KEY_W):
        direction -= player.global_basis.z
    if Input.is_key_pressed(KEY_S):
        direction += player.global_basis.z
    if Input.is_key_pressed(KEY_A):
        direction -= player.global_basis.x
    if Input.is_key_pressed(KEY_D):
        direction += player.global_basis.x

    direction.y = 0
    direction = direction.normalized()

    player.velocity.x = direction.x * speed
    player.velocity.z = direction.z * speed

    if Input.is_key_pressed(KEY_SPACE) and player.is_on_floor():
        player.velocity.y = jump_force

    player.move_and_slide()

func _unhandled_input(event):
    if event is InputEventMouseMotion:
        player.rotate_y(-event.relative.x * mouse_sensitivity)
        camera_rotation -= event.relative.y * mouse_sensitivity
        camera_rotation = clamp(camera_rotation, -1.4, 1.4)
        camera.rotation.x = camera_rotation
