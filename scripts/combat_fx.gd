extends Node3D
## One reusable slash, updated on the combat clock (including pause).
var slash: MeshInstance3D
var slash_material: ShaderMaterial
var age := 1.0
var duration := 0.18
var reach := 2.7
var direction := 1.0
var spinning := false
var stroke := 0
var impacts: Array[Dictionary] = []
var next_impact := 0
var enemy_arcs: Array[Dictionary] = []
var next_enemy_arc := 0

func _ready() -> void:
	slash = MeshInstance3D.new()
	slash.name = "SwordSlash"
	slash.mesh = QuadMesh.new()
	slash_material = ShaderMaterial.new()
	slash_material.shader = preload("res://shaders/sword_arc.gdshader")
	slash_material.set_shader_parameter("atlas", preload("res://assets/art/slash-down.png"))
	slash_material.set_shader_parameter("thrust_atlas",preload("res://assets/art/thrust-flash.png"))
	slash_material.set_shader_parameter("spin_atlas", preload("res://assets/art/spin-ribbon.png"))
	slash.material_override = slash_material
	slash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(slash)
	slash.hide()
	for i in range(8):
		var arc := MeshInstance3D.new()
		arc.mesh = QuadMesh.new()
		arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := slash_material.duplicate() as ShaderMaterial
		mat.set_shader_parameter("tint", Color("b44c36"))
		arc.material_override = mat
		add_child(arc)
		arc.hide()
		enemy_arcs.append({"node": arc, "material": mat, "age": 1.0})
	var contact_quad := QuadMesh.new()
	contact_quad.size = Vector2.ONE
	for i in range(16):
		var node := MeshInstance3D.new()
		node.mesh = contact_quad
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/contact_spark.gdshader")
		mat.set_shader_parameter("spark", preload("res://assets/art/contact-spark.png"))
		node.material_override = mat
		add_child(node)
		node.hide()
		impacts.append({"node": node, "material": mat, "age": 1.0, "duration": 0.14, "size": 1.0})

func enemy_strike(at: Vector3, facing: float, reach: float) -> void:
	var arc := enemy_arcs[next_enemy_arc]
	next_enemy_arc = (next_enemy_arc + 1) % enemy_arcs.size()
	arc.age = 0.0
	arc.node.position = at + Vector3(facing * reach * 0.35, -0.65, 0.8)
	arc.node.mesh.size = Vector2(reach, 1.5)
	arc.material.set_shader_parameter("life", 0.0)
	arc.material.set_shader_parameter("facing_left", facing < 0)
	arc.node.show()

func impact(at: Vector3, force: float) -> void:
	var hit := impacts[next_impact]
	next_impact = (next_impact + 1) % impacts.size()
	hit.age = 0
	hit.duration = 0.18 if force >= 2 else (0.13 if force >= 1.6 else 0.10)
	hit.size = 3.2 if force >= 2.5 else (2.6 if force >= 2 else (1.9 if force >= 1.6 else (1.5 if force >= 1 else 0.9)))
	hit.node.position = at
	hit.node.scale = Vector3.ONE * hit.size
	hit.material.set_shader_parameter("life", 0.0)
	hit.material.set_shader_parameter("angle", float(next_impact % 4) * 0.7)
	hit.node.show()

func strike(at: Vector3, facing: float, attack_reach: float, color: Color, power: bool, style: int = 0) -> void:
	spinning = false
	stroke = style
	age = 0
	duration = 0.18 if power else 0.11
	reach = attack_reach
	direction = facing
	slash.mesh.size = Vector2(reach * 1.12, 3.0 if power else (2.4 if style == 0 else 1.1))
	slash_material.set_shader_parameter("heavy",power)
	slash_material.set_shader_parameter("stroke",style)
	slash_material.set_shader_parameter("tint", color)
	slash_material.set_shader_parameter("facing_left", facing < 0)
	slash_material.set_shader_parameter("spinning", false)
	advance(0, at)

func spin(at: Vector3, facing: float, color: Color) -> void:
	slash_material.set_shader_parameter("heavy",false)
	spinning = true
	age = 0
	duration = 0.16
	direction = facing
	slash.mesh.size = Vector2(7.0, 2.5)
	slash_material.set_shader_parameter("tint", color)
	slash_material.set_shader_parameter("spinning", true)
	slash_material.set_shader_parameter("facing_left", facing < 0)
	advance(0, at)

func advance(dt: float, at: Vector3) -> void:
	for arc in enemy_arcs:
		arc.age += dt
		arc.node.visible = arc.age < 0.12
		if arc.node.visible: arc.material.set_shader_parameter("life", arc.age / 0.12)
	for hit in impacts:
		hit.age += dt
		hit.node.visible = hit.age < hit.duration
		if hit.node.visible:
			var t: float = hit.age / hit.duration
			hit.material.set_shader_parameter("life", t)
			hit.node.scale = Vector3.ONE * hit.size * (1.0 + t * 0.3)
	age += dt
	slash.visible = age < duration
	if not slash.visible: return
	slash.position = at + Vector3(0 if spinning else direction * reach * 0.40, (-0.85 if stroke == 2 else -0.65) if not spinning and stroke > 0 else -0.12, 0.7)
	slash_material.set_shader_parameter("life", age / duration)

func clear() -> void:
	for arc in enemy_arcs:
		arc.age = 1.0
		arc.node.hide()
	age = duration
	slash.hide()
	for hit in impacts:
		hit.age = hit.duration
		hit.node.hide()
