
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
	create_environment()
	create_world_collision()
	create_player()
	generate_world()
	create_hud()

func create_environment():
	var world_env = get_node_or_null("WorldEnvironment")
	if world_env:
		var env = Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.20, 0.25, 0.24)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.48, 0.52, 0.47)
		env.ambient_light_energy = 0.65
		env.fog_enabled = true
		env.fog_light_color = Color(0.48, 0.53, 0.49)
		env.fog_density = 0.006
		world_env.environment = env

	var sun = get_node_or_null("Sun")
	if sun:
		sun.light_color = Color(0.78, 0.76, 0.66)
		sun.light_energy = 0.65
		sun.shadow_enabled = true

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
	camera.fov = 80
	player.add_child(camera)

	create_scanner()

func create_scanner():
	var body = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.13, 0.12, 0.32)
	body.mesh = mesh
	body.position = Vector3(0.27, -0.24, -0.48)

	var metal = StandardMaterial3D.new()
	metal.albedo_color = Color(0.12, 0.16, 0.14)
	metal.metallic = 0.7
	metal.roughness = 0.35
	body.material_override = metal
	camera.add_child(body)

	var screen = MeshInstance3D.new()
	var screen_mesh = BoxMesh.new()
	screen_mesh.size = Vector3(0.10, 0.015, 0.09)
	screen.mesh = screen_mesh
	screen.position = Vector3(0.27, -0.17, -0.53)

	var green = StandardMaterial3D.new()
	green.albedo_color = Color(0.1, 1.0, 0.3)
	green.emission_enabled = true
	green.emission = Color(0.1, 1.0, 0.3)
	screen.material_override = green
	camera.add_child(screen)

	var light = OmniLight3D.new()
	light.position = Vector3(0.27, -0.18, -0.55)
	light.light_color = Color(0.1, 1.0, 0.3)
	light.light_energy = 0.5
	light.omni_range = 0.8
	camera.add_child(light)

	var indicator = MeshInstance3D.new()
	var indicator_mesh = SphereMesh.new()
	indicator_mesh.radius = 0.025
	indicator_mesh.height = 0.05
	indicator.mesh = indicator_mesh
	indicator.position = Vector3(0.27, -0.15, -0.61)
	indicator.material_override = green
	camera.add_child(indicator)

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
	create_box(Vector3(7, 0.13, 130), Vector3(0, 0.02, -55), Color(0.12, 0.13, 0.12))
	create_box(Vector3(0.25, 0.02, 130), Vector3(-3.2, 0.10, -55), Color(0.35, 0.32, 0.22))
	create_box(Vector3(0.25, 0.02, 130), Vector3(3.2, 0.10, -55), Color(0.35, 0.32, 0.22))

	for i in range(150):
		var x = randf_range(-42, 42)
		var z = randf_range(-115, 15)
		if abs(x) > 5:
			create_grass(Vector3(x, 0, z))

	for i in range(75):
		var x = randf_range(-48, 48)
		var z = randf_range(-110, 12)
		if abs(x) > 5.5:
			create_tree(Vector3(x, 0, z))

	create_ruin(Vector3(-16, 0, -25), 1.0)
	create_ruin(Vector3(17, 0, -43), 1.2)
	create_ruin(Vector3(-22, 0, -65), 1.3)
	create_ruin(Vector3(24, 0, -85), 1.0)

	create_bus(Vector3(-11, 0, -48))

	create_lamp(Vector3(-5, 0, -18))
	create_lamp(Vector3(5, 0, -38))
	create_lamp(Vector3(-5, 0, -62))
	create_lamp(Vector3(5, 0, -88))

	for i in range(35):
		var x = randf_range(-35, 35)
		var z = randf_range(-100, 10)
		if abs(x) > 5:
			create_rock(Vector3(x, 0, z))

func create_tree(pos: Vector3):
	var height = randf_range(4.5, 7.0)

	var trunk = CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.38
	trunk.height = height

	var tree_trunk = MeshInstance3D.new()
	tree_trunk.mesh = trunk
	tree_trunk.position = pos + Vector3(0, height / 2, 0)
	tree_trunk.material_override = make_material(Color(0.19, 0.13, 0.08))
	add_child(tree_trunk)

	for i in range(3):
		var leaves = CylinderMesh.new()
		leaves.top_radius = 0.0
		leaves.bottom_radius = randf_range(1.7, 2.5)
		leaves.height = 3.5

		var foliage = MeshInstance3D.new()
		foliage.mesh = leaves
		foliage.position = pos + Vector3(0, height - 0.5 + i * 1.1, 0)
		foliage.material_override = make_material(Color(0.09, 0.17, 0.10))
		add_child(foliage)

func create_grass(pos: Vector3):
	var grass = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(randf_range(0.08, 0.2), randf_range(0.3, 0.8), 0.08)
	grass.mesh = mesh
	grass.position = pos + Vector3(0, 0.25, 0)
	grass.rotation.y = randf_range(0, TAU)
	grass.material_override = make_material(Color(0.18, 0.24, 0.13))
	add_child(grass)

func create_ruin(pos: Vector3, scale: float):
	var wall_color = Color(0.27, 0.26, 0.22)
	var dark_color = Color(0.08, 0.10, 0.09)

	create_box(Vector3(8, 4, 0.5) * scale, pos + Vector3(0, 2, -3) * scale, wall_color)
	create_box(Vector3(0.5, 4, 6) * scale, pos + Vector3(-4, 2, 0) * scale, wall_color)
	create_box(Vector3(0.5, 3, 5) * scale, pos + Vector3(4, 1.5, 0) * scale, wall_color)
	create_box(Vector3(8, 0.35, 7) * scale, pos + Vector3(0, 4, 0) * scale, dark_color)

	create_box(Vector3(1.4, 1.1, 0.12) * scale, pos + Vector3(-2, 2.5, -3.3) * scale, Color(0.07, 0.12, 0.12))
	create_box(Vector3(1.4, 1.1, 0.12) * scale, pos + Vector3(2, 2.5, -3.3) * scale, Color(0.07, 0.12, 0.12))

	create_rock(pos + Vector3(-5, 0, 2))
	create_rock(pos + Vector3(5, 0, -2))

func create_bus(pos: Vector3):
	var rusty = Color(0.28, 0.23, 0.15)
	var window = Color(0.07, 0.12, 0.13)

	create_box(Vector3(3.2, 2.8, 8), pos + Vector3(0, 1.8, 0), rusty)
	create_box(Vector3(3.25, 1.1, 7.5), pos + Vector3(0, 2.6, 0), window)

	for side in [-1.0, 1.0]:
		for z in [-2.5, 0.0, 2.5]:
			create_box(Vector3(0.08, 1.0, 1.8), pos + Vector3(side * 1.65, 2.6, z), rusty)

	for z in [-2.5, 2.5]:
		var wheel = CylinderMesh.new()
		wheel.top_radius = 0.65
		wheel.bottom_radius = 0.65
		wheel.height = 0.35

		var wheel_object = MeshInstance3D.new()
		wheel_object.mesh = wheel
		wheel_object.rotation.z = PI / 2
		wheel_object.position = pos + Vector3(1.6, 0.65, z)
		wheel_object.material_override = make_material(Color(0.04, 0.04, 0.04))
		add_child(wheel_object)

		var wheel2 = wheel_object.duplicate()
		wheel2.position.x = pos.x - 3.2
		add_child(wheel2)

func create_lamp(pos: Vector3):
	var pole = CylinderMesh.new()
	pole.top_radius = 0.07
	pole.bottom_radius = 0.12
	pole.height = 6.5

	var pole_object = MeshInstance3D.new()
	pole_object.mesh = pole
	pole_object.position = pos + Vector3(0, 3.25, 0)
	pole_object.material_override = make_material(Color(0.12, 0.13, 0.12))
	add_child(pole_object)

	create_box(Vector3(1.2, 0.12, 0.12), pos + Vector3(0.5, 6.4, 0), Color(0.15, 0.15, 0.13))

	var lamp = OmniLight3D.new()
	lamp.position = pos + Vector3(0.9, 6.1, 0)
	lamp.light_color = Color(0.75, 0.68, 0.42)
	lamp.light_energy = 0.5
	lamp.omni_range = 7
	add_child(lamp)

func create_rock(pos: Vector3):
	var rock = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(randf_range(0.4, 1.5), randf_range(0.3, 1.0), randf_range(0.4, 1.4))
	rock.mesh = mesh
	rock.position = pos + Vector3(0, 0.25, 0)
	rock.rotation = Vector3(randf_range(0, 0.3), randf_range(0, TAU), randf_range(0, 0.3))
	rock.material_override = make_material(Color(0.22, 0.22, 0.19))
	add_child(rock)

func make_material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material

func create_box(size: Vector3, pos: Vector3, color: Color):
	var mesh = BoxMesh.new()
	mesh.size = size

	var object = MeshInstance3D.new()
	object.mesh = mesh
	object.position = pos
	object.material_override = make_material(color)
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
	ammo.text = "СКАНЕР"
	ammo.anchor_left = 1.0
	ammo.anchor_right = 1.0
	ammo.offset_left = -180
	ammo.offset_right = -25
	ammo.offset_top = 30
	ammo.offset_bottom = 70
	ammo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo.add_theme_font_size_override("font_size", 22)
	ammo.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
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
