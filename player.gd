
extends Node3D

var player: CharacterBody3D
var camera: Camera3D

var gravity = 9.8
var speed = 5.0
var jump_force = 4.5
var mouse_sensitivity = 0.003

var move_input = Vector2.ZERO
var move_start = Vector2.ZERO
var move_touch_index = -1
var look_touch_index = -1
var camera_rotation = 0.0
var jump_requested = false

func _ready():
	randomize()
	create_world_collision()
	create_player()
	generate_world()
	create_hud()

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

	direction -= player.global_basis.z * move_input.y
	direction += player.global_basis.x * move_input.x

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

	if (jump_requested or Input.is_key_pressed(KEY_SPACE)) and player.is_on_floor():
		player.velocity.y = jump_force

	jump_requested = false
	player.move_and_slide()

func _input(event):
	var screen_size = get_viewport().get_visible_rect().size

	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < screen_size.x * 0.5 and move_touch_index == -1:
				move_touch_index = event.index
				move_start = event.position
				move_input = Vector2.ZERO
			elif event.position.x > screen_size.x * 0.5:
				if event.position.x > screen_size.x * 0.78 and event.position.y > screen_size.y * 0.72:
					jump_requested = true
				else:
					look_touch_index = event.index
		else:
			if event.index == move_touch_index:
				move_touch_index = -1
				move_input = Vector2.ZERO
			if event.index == look_touch_index:
				look_touch_index = -1

	if event is InputEventScreenDrag:
		if event.index == move_touch_index:
			var offset = (event.position - move_start) / 100.0
			move_input = offset.limit_length(1.0)
		elif event.index == look_touch_index:
			rotate_camera(event.relative)

	if event is InputEventMouseMotion:
		rotate_camera(event.relative)

func rotate_camera(delta):
	if not player or not camera:
		return

	player.rotate_y(-delta.x * mouse_sensitivity)
	camera_rotation -= delta.y * mouse_sensitivity
	camera_rotation = clamp(camera_rotation, -1.4, 1.4)
	camera.rotation.x = camera_rotation

func generate_world():
	create_box(Vector3(5, 0.12, 100), Vector3(0, 0.02, -40), Color(0.16, 0.16, 0.14))

	for i in range(55):
		var x = randf_range(-45, 45)
		var z = randf_range(-85, 15)

		if abs(x) < 6 or Vector2(x, z).length() < 12:
			continue

		create_tree(Vector3(x, 0, z))

	create_house(Vector3(18, 0, -25))
	create_house(Vector3(-20, 0, -42))
	create_house(Vector3(22, 0, -65))

func create_tree(pos: Vector3):
	var trunk = CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.4
	trunk.height = 5.5

	var tree_trunk = MeshInstance3D.new()
	tree_trunk.mesh = trunk
	tree_trunk.position = pos + Vector3(0, 2.75, 0)

	var wood = StandardMaterial3D.new()
	wood.albedo_color = Color(0.22, 0.15, 0.09)
	tree_trunk.material_override = wood
	add_child(tree_trunk)

	var leaves = CylinderMesh.new()
	leaves.top_radius = 0.0
	leaves.bottom_radius = 2.3
	leaves.height = 5.5

	var foliage = MeshInstance3D.new()
	foliage.mesh = leaves
	foliage.position = pos + Vector3(0, 6.5, 0)

	var green = StandardMaterial3D.new()
	green.albedo_color = Color(0.12, 0.22, 0.12)
	foliage.material_override = green
	add_child(foliage)

func create_house(pos: Vector3):
	create_box(Vector3(8, 4, 7), pos + Vector3(0, 2, 0), Color(0.30, 0.27, 0.21))
	create_box(Vector3(9, 0.5, 8), pos + Vector3(0, 4.2, 0), Color(0.12, 0.13, 0.12))
	create_box(Vector3(1.2, 1.5, 0.15), pos + Vector3(0, 1.1, -3.58), Color(0.12, 0.08, 0.05))
	create_box(Vector3(1.3, 1.2, 0.15), pos + Vector3(-2.5, 2.5, -3.58), Color(0.08, 0.12, 0.13))

func create_box(size: Vector3, pos: Vector3, color: Color):
	var mesh = BoxMesh.new()
	mesh.size = size

	var object = MeshInstance3D.new()
	object.mesh = mesh
	object.position = pos

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0

	object.material_override = material
	add_child(object)

func create_hud():
	var layer = CanvasLayer.new()
	layer.name = "GameHUD"
	add_child(layer)

	var ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)

	var health = Label.new()
	health.text = "♥ 100"
	health.position = Vector2(25, 25)
	health.add_theme_font_size_override("font_size", 25)
	health.add_theme_color_override("font_color", Color(0.3, 1, 0.4))
	ui.add_child(health)

	var stamina = Label.new()
	stamina.text = "STAMINA 100%"
	stamina.position = Vector2(25, 60)
	stamina.add_theme_font_size_override("font_size", 18)
	stamina.add_theme_color_override("font_color", Color.WHITE)
	ui.add_child(stamina)

	var ammo = Label.new()
	ammo.text = "30 / 120"
	ammo.anchor_left = 1.0
	ammo.anchor_right = 1.0
	ammo.offset_left = -180
	ammo.offset_right = -25
	ammo.offset_top = 30
	ammo.offset_bottom = 70
	ammo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo.add_theme_font_size_override("font_size", 25)
	ammo.add_theme_color_override("font_color", Color.WHITE)
	ui.add_child(ammo)

	var crosshair = Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-12, -18)
	crosshair.add_theme_font_size_override("font_size", 32)
	crosshair.add_theme_color_override("font_color", Color.WHITE)
	ui.add_child(crosshair)

	var jump_button = Button.new()
	jump_button.text = "ПРЫЖОК"
	jump_button.anchor_left = 1.0
	jump_button.anchor_top = 1.0
	jump_button.anchor_right = 1.0
	jump_button.anchor_bottom = 1.0
	jump_button.offset_left = -160
	jump_button.offset_top = -140
	jump_button.offset_right = -25
	jump_button.offset_bottom = -35
	ui.add_child(jump_button)

	jump_button.pressed.connect(func():
		jump_requested = true
	)

	var hint = Label.new()
	hint.text = "ЗОНА ОТЧУЖДЕНИЯ"
	hint.position = Vector2(25, 100)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.65))
	ui.add_child(hint)
