extends Node3D
var environment:Environment
## Perspective diorama: physical lane, lit cutouts, distant forest and depth haze.
var atmosphere:Node3D
const TEXTURES = {
 "forest-sunlit-distance.png": preload("res://assets/art/forest-sunlit-distance.png"),
 "stone-flight.png": preload("res://assets/art/stone-flight.png"),
 "cat-combo-sweep.png": preload("res://assets/art/cat-combo-sweep.png"),
 "cat-combo-thrust.png": preload("res://assets/art/cat-combo-thrust.png"),
 "cat-walk-toward.png": preload("res://assets/art/cat-walk-toward.png"),
 "cat-walk-away.png": preload("res://assets/art/cat-walk-away.png"),
 "cat-run.png": preload("res://assets/art/cat-run.png"),
 "cat-backstep.png": preload("res://assets/art/cat-backstep.png"),
 "boss-claw.png": preload("res://assets/art/boss-claw.png"),
 "cat-heavy-eight.png": preload("res://assets/art/cat-heavy-eight.png"),
 "rat-run.png": preload("res://assets/art/rat-run.png"),
 "weasel-run.png": preload("res://assets/art/weasel-run.png"),
 "cat-spin.png": preload("res://assets/art/cat-spin.png"),
 "cat-jump.png": preload("res://assets/art/cat-jump.png"),
 "cat-cut-eight.png": preload("res://assets/art/cat-cut-eight.png"),
 "cat-heavy-cleave.png": preload("res://assets/art/cat-heavy-cleave.png"),
 "cat-rush.png": preload("res://assets/art/cat-rush.png"),
 "cat-walk.png": preload("res://assets/art/cat-walk.png"),
 "grass-rat.png": preload("res://assets/art/grass-rat.png"),
 "beast-wind-weasel.png": preload("res://assets/art/beast-wind-weasel.png"),
 "beast-stone-toad.png": preload("res://assets/art/beast-stone-toad.png"),
 "elite-grass-rat.png": preload("res://assets/art/elite-grass-rat.png"),
 "boss-grass-rat.png": preload("res://assets/art/boss-grass-rat.png"),
 "forest-side-distance.png": preload("res://assets/art/forest-side-distance.png"),
 "cedar-forked.png": preload("res://assets/art/cedar-forked.png"),
 "ancient-cedar.png": preload("res://assets/art/ancient-cedar.png"),
 "forest-ferns.png": preload("res://assets/art/forest-ferns.png"),
 "slash-down.png": preload("res://assets/art/slash-down.png"),
}


func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if glow > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

static func road_back(x: float) -> float:
	if x >= 21.0: return lerpf(-1.7,-4.7,clampf((x-21.0)/5.0,0.0,1.0))
	return lerpf(-4.7,-1.7,clampf((x-4.0)/5.0,0.0,1.0))

func box(at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mat
	n.position = at
	add_child(n)
	return n

func sprite(file: String, at: Vector3, pixel: float) -> Sprite3D:
	var n := Sprite3D.new()
	n.texture = TEXTURES[file]
	n.pixel_size = pixel
	n.position = at
	n.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	n.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	n.no_depth_test = false
	n.shaded = true
	add_child(n)
	return n

func _ready() -> void:
	var compatibility := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	atmosphere=preload("res://scripts/forest_atmosphere.gd").new()
	add_child(atmosphere)
	var world_environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.background_color = Color("253d43")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a1c4dd")
	env.ambient_light_energy = 0.32
	env.fog_enabled = true
	env.fog_light_color = Color("afcbd0")
	env.fog_density = 0.0014
	env.fog_sky_affect = 0.0
	env.volumetric_fog_enabled = not compatibility
	env.volumetric_fog_density = 0.0
	env.volumetric_fog_length = 55.0
	env.volumetric_fog_ambient_inject = 0.25
	env.volumetric_fog_anisotropy = 0.45
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_hdr_threshold = 1.2
	env.ssr_enabled = not compatibility
	env.ssr_max_steps = 48
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("719bbf")
	sky_material.sky_horizon_color = Color("d0dfdf")
	sky_material.ground_bottom_color = Color("122e2b")
	sky_material.ground_horizon_color = Color("72877d")
	var reflection_sky := Sky.new()
	reflection_sky.sky_material = sky_material
	env.sky = reflection_sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ssao_enabled = true
	env.ssao_radius = 0.65
	env.ssao_intensity = 1.1
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	# Compatibility lights in a different color pipeline. Calibrated against
	# the same seeded Forward+ scene; HUD colors remain outside this grading.
	env.tonemap_exposure = 0.78 if compatibility else 0.9
	if compatibility:
		env.adjustment_enabled = true
		env.adjustment_saturation = 0.90
	environment=env
	world_environment.environment = env
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "ForestSun"
	sun.rotation_degrees = Vector3(-35, -145, 0)
	sun.light_color = Color("fff0d2")
	sun.light_energy = 1.0 if compatibility else 1.7
	sun.shadow_enabled = true
	sun.light_volumetric_fog_energy = 1.2
	sun.directional_shadow_max_distance = 65.0
	sun.shadow_blur = 1.5
	sun.shadow_bias = 0.15 if compatibility else 0.1
	sun.shadow_normal_bias = 2.5 if compatibility else 2.0
	add_child(sun)
	# Soft sky bounce keeps camera-facing sprites readable against the sun.
	var bounce := DirectionalLight3D.new()
	bounce.name = "ForestSkyBounce"
	bounce.rotation_degrees = Vector3(-35,-30,0)
	bounce.light_color = Color("c7dcdf")
	bounce.light_energy = 0.38 if compatibility else 0.55
	bounce.light_volumetric_fog_energy = 0.0
	bounce.shadow_enabled = false
	bounce.light_specular = 0.0
	add_child(bounce)
	# One sunlight direction drives surface shadows and volumetric scattering.
	# Visible foliage is the occluder; there are no detached shadow planes.
	if not compatibility:
		var air := FogVolume.new()
		air.name = "BridgeAir"
		air.size = Vector3(78,14,12)
		air.position = Vector3(24,4,-8)
		var mist := FogMaterial.new()
		mist.density = 0.016
		mist.albedo = Color("c5dadd")
		air.material = mist
		add_child(air)
	var stone := ShaderMaterial.new()
	stone.shader = preload("res://shaders/sunlit_stone.gdshader")
	stone.set_shader_parameter("stone_texture",preload("res://assets/art/ancient-masonry.png"))
	var cliff := ShaderMaterial.new()
	cliff.shader = preload("res://shaders/moss_rock.gdshader")
	cliff.set_shader_parameter("rock_texture",preload("res://assets/art/forest-strata.png"))
	cliff.set_shader_parameter("moss_texture",preload("res://assets/art/forest-floor.png"))
	var moss := material(Color("64774a"))
	moss.albedo_texture = preload("res://assets/art/ancient-masonry.png")
	moss.uv1_triplanar = true
	moss.uv1_scale = Vector3.ONE * 0.18
	var earth := ShaderMaterial.new()
	earth.shader = preload("res://shaders/forest_trail.gdshader")
	earth.set_shader_parameter("soil",preload("res://assets/art/forest-flagstones.png"))
	earth.set_shader_parameter("vegetation",preload("res://assets/art/forest-floor.png"))
	# Distant art follows slowly; it never substitutes for the physical lane.
	var bg := sprite("forest-sunlit-distance.png", Vector3(3, 8, -20), 0.04)
	bg.name = "Distance"
	bg.shaded = false
	bg.modulate = Color(0.97,1.0,1.0)
	bg.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var canopy=[Vector3(-7,0.92,-6.9),Vector3(4.5,1.08,-7.7),Vector3(27.5,0.90,-6.1),Vector3(37,1.04,-8.0),Vector3(55,0.86,-6.8)]
	for i in range(canopy.size()):
		var place:Vector3=canopy[i]
		var tree := sprite("cedar-forked.png" if i in [2,4] else "ancient-cedar.png", Vector3(place.x, 4.25*place.y, place.z), 0.007*place.y)
		tree.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		tree.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		tree.modulate = Color(0.90,0.94,0.86) if place.z < -7 else Color(0.98,0.98,0.89)
		tree.flip_h = i % 2 == 0
	var banks := preload("res://scripts/riverbanks.gd").new()
	add_child(banks)
	for place in [Vector3(4.5,3.0,-14),Vector3(25.5,3.4,-15),Vector3(1.0,4.0,-18),Vector3(29.0,4.8,-19)]:
		var cedar := sprite("cedar-forked.png" if place.x < 10 else "ancient-cedar.png",place,0.0048)
		cedar.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		cedar.modulate = Color(0.52,0.66,0.62)
	for place in [Vector3(6.5,-2.6,3.5),Vector3(24,-2.5,3.8),Vector3(4,-1.0,-9),Vector3(26,-0.8,-10)]:
		var fern := sprite("forest-ferns.png",place,0.003)
		fern.modulate = Color(0.58,0.69,0.39)
	# Small plants break the terrace silhouette, rather than repeating full trees.
	for side in [-1,1]:
		for tier in range(2 if side < 0 else 3):
			for i in range(7):
				var x: float = 15+side*(11.5-tier*1.5 if side < 0 else 10.5-tier*1.1)+(i-3)*0.95
				var plant := sprite("forest-ferns.png",Vector3(x,-1.55+tier*1.15,(-10.3-tier*3.0 if side < 0 else -9.3-tier*2.4)),0.0018+(i%3)*0.0003)
				plant.modulate = Color(0.59,0.7,0.46)
	for x in [4.3,6.7,8.4,21.4,23.2,26.1]:
		var edge := sprite("forest-ferns.png",Vector3(x,0.15,1.65),0.0012)
		edge.modulate = Color(0.66,0.74,0.4)
		var hanging := sprite("forest-ferns.png",Vector3(x,-1.1,2.5),0.0015)
		hanging.rotation.z = PI
		hanging.modulate = Color(0.42,0.54,0.30)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for span in [Vector2(-12, 9), Vector2(21, 62)]:
		var middle: float = (span.x + span.y) * 0.5
		box(Vector3(middle, -3.05, -2.8), Vector3(span.y - span.x, 6, 10), cliff)
		box(Vector3(middle, -0.05, -4.25), Vector3(span.y - span.x, 0.15, 6.5), moss)
		# Both banks share a wide battle floor with tapered bridge approaches.
		var path := SurfaceTool.new()
		path.begin(Mesh.PRIMITIVE_TRIANGLES)
		var cuts := [-12.0,4.0,9.0] if span.x < 0 else [21.0,26.0,62.0]
		for segment in range(cuts.size()-1):
			var x0: float = cuts[segment]
			var x1: float = cuts[segment+1]
			var points := [Vector3(x0,0.06,road_back(x0)),Vector3(x1,0.06,road_back(x1)),Vector3(x1,0.06,1.7),Vector3(x0,0.06,1.7)]
			# Godot front faces use clockwise winding when viewed from above.
			for index in [0,1,2,0,2,3]:
				path.set_normal(Vector3.UP)
				path.set_uv(Vector2(points[index].x,points[index].z)*0.5)
				path.add_vertex(points[index])
		var floor_mesh := MeshInstance3D.new()
		floor_mesh.name = "WideClearing" if span.x < 0 else "WideFarBank"
		floor_mesh.mesh = path.commit()
		floor_mesh.material_override = earth
		# The terrace volume below casts its silhouette. This coplanar surface
		# only receives shadows, avoiding self-shadow bands in Compatibility.
		floor_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(floor_mesh)
		add_child(preload("res://scripts/flagstone_paving.gd").build(cuts,road_back))
		for i in range(int(span.x), int(span.y)):
			for z in [road_back(i+0.5), 1.7]:
				var block := box(Vector3(i + 0.5, -0.22, z), Vector3(1.05, rng.randf_range(0.4, 0.65), 0.85), stone)
				block.rotation.z = rng.randf_range(-0.1, 0.1)
				box(Vector3(i + 0.5, 0.08, z), Vector3(1.03, 0.12, 0.88), moss)
			if i % 2 == 0:
				banks.rock(Vector3(i+0.5,-2.0-rng.randf_range(0,0.6),2.1),Vector3(rng.randf_range(1.8,2.7),rng.randf_range(2.0,3.1),rng.randf_range(0.7,1.4)))
			if i % 3 == 0:
				var fern := sprite("forest-ferns.png", Vector3(i, 0.32, road_back(i)-0.8), 0.0015)
				fern.modulate = Color(0.72, 0.8, 0.6)
	# A true gap under a narrow stone bridge; foreground masonry stays below feet.
	for i in range(24):
		var x := 9.25 + i * 0.5
		box(Vector3(x, -0.12, 0), Vector3(0.48, 0.32, 4.4), stone)
		box(Vector3(x, 0.065, 0), Vector3(0.48, 0.05, 3.8), stone)
		var arch_top := -2.7 + 2.2 * sqrt(maxf(0, 1 - pow((x - 15) / 5.9, 2)))
		var height := maxf(0.15, -0.27 - arch_top)
		for z in [-1.9, 1.9]:
			box(Vector3(x, -0.27 - height * 0.5, z), Vector3(0.51, height, 0.55), stone)
	for x in [9.2, 12.1, 15.0, 17.9, 20.8]:
		box(Vector3(x, 0.55, -2), Vector3(0.3, 1.1, 0.3), stone)
		box(Vector3(x, 1.14, -2), Vector3(0.43, 0.12, 0.43), moss)
	box(Vector3(15, 0.83, -2), Vector3(12, 0.2, 0.24), stone)
	for z in [-1.8, 1.8]:
		for i in range(17):
			var angle := PI * float(i) / 16
			var voussoir := box(Vector3(15 + cos(angle) * 5.7, -2.7 + sin(angle) * 2.2, z), Vector3(1.0, 0.48, 0.65), stone)
			voussoir.rotation.z = atan2(2.2 * cos(angle), -5.7 * sin(angle))
	var water := ShaderMaterial.new()
	water.shader = preload("res://shaders/lake.gdshader")
	var lake := MeshInstance3D.new()
	lake.name = "Lake"
	var surface := PlaneMesh.new()
	surface.size = Vector2(90,42)
	lake.mesh = surface
	lake.material_override = water
	lake.position = Vector3(23,-3.65,-0.5)
	lake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lake)
	# Only the two visible ends bound movement; there are no intermediate walls.
	for x in [-8.8, 56.8]:
		box(Vector3(x, 1.6, -1.5), Vector3(0.65, 3.2, 7.4), stone)
		box(Vector3(x, 3.25, -1.5), Vector3(0.9, 0.2, 7.8), moss)
	# Shrines are behind the lane and cannot mask the hero.
	for x in [42, 46]:
		box(Vector3(x, 1.9, -6.4), Vector3(0.7, 3.8, 0.7), stone)
		for y in [0.2, 1.3, 2.6, 3.65]:
			box(Vector3(x, y, -6.4), Vector3(0.85, 0.15, 0.85), moss)
	box(Vector3(44, 3.9, -6.4), Vector3(5.2, 0.4, 1), stone)
	box(Vector3(44, 4.2, -6.4), Vector3(5.8, 0.2, 1.3), moss)
	for x in [-4, 8, 22, 34, 49]:
		box(Vector3(x, 0.5, road_back(x)-0.8), Vector3(0.45, 1, 0.45), stone)
		box(Vector3(x, 1.1, road_back(x)-0.8), Vector3(0.4, 0.25, 0.4), material(Color("d99b55"), 0.6))
		box(Vector3(x, 1.3, road_back(x)-0.8), Vector3(0.65, 0.13, 0.65), stone)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(x, 1.2, road_back(x)-0.3)
		lamp.light_color = Color("ffc178")
		lamp.omni_range = 3
		lamp.light_energy = 0.65
		add_child(lamp)
	for x in [-8, 2, 26, 39, 54]:
		var front := sprite("forest-ferns.png", Vector3(x, -1.8, 3.8), 0.0024)
		front.modulate = Color(0.24, 0.32, 0.25)

	# Sparse broken stones sit outside the traversable edge; the lane stays readable.
	for i in range(24):
		var x:float=-6.0+i*2.55
		if x>8.5 and x<21.5:continue
		var z:float=road_back(x)-0.4-rng.randf_range(0,0.5)
		banks.rock(Vector3(x,0.08,z),Vector3(rng.randf_range(0.35,0.85),rng.randf_range(0.15,0.35),rng.randf_range(0.35,0.65)))
	# Shared per-texture/tint materials keep the new wind pass bounded.
	var foliage_materials:Dictionary={}
	for child in get_children():
		if not child is Sprite3D:continue
		if child.texture not in [TEXTURES["forest-ferns.png"],TEXTURES["ancient-cedar.png"],TEXTURES["cedar-forked.png"]]:continue
		var key:String=child.texture.resource_path+str(child.modulate)+str(child.flip_h)+str(child.rotation.z)
		if not foliage_materials.has(key):
			var leaves:=ShaderMaterial.new()
			leaves.shader=preload("res://shaders/foliage.gdshader")
			leaves.set_shader_parameter("foliage_texture",child.texture)
			leaves.set_shader_parameter("tint",child.modulate)
			var inverted:float=-1.0 if absf(child.rotation.z)>3.0 else 1.0
			leaves.set_shader_parameter("flip_axes",Vector2((-1.0 if child.flip_h else 1.0)*inverted,inverted))
			leaves.set_shader_parameter("sway",0.035 if child.texture==TEXTURES["forest-ferns.png"] else 0.085)
			foliage_materials[key]=leaves
		child.material_override=foliage_materials[key]

func follow_camera(x: float) -> void:
	get_node("Distance").position.x = 3 + (x - 3) * 0.94
