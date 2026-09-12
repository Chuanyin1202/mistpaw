extends RefCounted
## A single mesh of shallow, bevelled Voronoi slabs. Gameplay remains on the
## original plane; the 4 cm relief provides real edge lighting, not obstacles.
static func clip(poly:PackedVector2Array, origin:Vector2, normal:Vector2)->PackedVector2Array:
	var result:=PackedVector2Array()
	if poly.is_empty():return result
	var previous:=poly[-1]
	var previous_distance:float=(previous-origin).dot(normal)
	for point in poly:
		var distance:float=(point-origin).dot(normal)
		if (distance<=0)!=(previous_distance<=0):
			result.append(previous.lerp(point,previous_distance/(previous_distance-distance)))
		if distance<=0:result.append(point)
		previous=point
		previous_distance=distance
	return result

static func triangle(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,tone:Color)->void:
	# Clockwise front faces; explicitly derived face normal preserves bevels.
	var normal:Vector3=(c-a).cross(b-a).normalized()
	for point in [a,b,c]:
		surface.set_normal(normal)
		surface.set_color(tone)
		surface.set_uv(Vector2(point.x,point.z)*0.13)
		surface.add_vertex(point)

static func build(cuts:Array,road_back:Callable)->MeshInstance3D:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng:=RandomNumberGenerator.new()
	rng.seed=109+int(cuts[0])
	for section in range(cuts.size()-1):
		var left:float=cuts[section]
		var right:float=cuts[section+1]
		var boundary:=PackedVector2Array([Vector2(left,road_back.call(left)),Vector2(right,road_back.call(right)),Vector2(right,1.7),Vector2(left,1.7)])
		var seeds:Array[Vector2]=[]
		for ix in range(int(ceil((right-left)/1.15))):
			for iz in range(6):
				seeds.append(Vector2(left+0.55+ix*1.15+rng.randf_range(-0.24,0.24),-4.4+iz*1.05+rng.randf_range(-0.22,0.22)))
		for seed_position in seeds:
			var polygon:=boundary
			for other in seeds:
				var direction:Vector2=other-seed_position
				if direction.length_squared()<0.001 or direction.length_squared()>12.0:continue
				polygon=clip(polygon,(seed_position+other)*0.5,direction)
				if polygon.size()<3:break
			if polygon.size()<3:continue
			var center:=Vector2.ZERO
			for point in polygon:center+=point
			center/=polygon.size()
			var height:float=rng.randf_range(0.085,0.105)
			var tone:=Color(rng.randf_range(0.78,1.06),rng.randf_range(0.26,0.75),0,1)
			var top_center:=Vector3(center.x,height,center.y)
			for edge in range(polygon.size()):
				var a:Vector2=center.lerp(polygon[edge],0.965)
				var b:Vector2=center.lerp(polygon[(edge+1)%polygon.size()],0.965)
				var inner_a:Vector2=center.lerp(a,0.91)
				var inner_b:Vector2=center.lerp(b,0.91)
				var top_a:=Vector3(inner_a.x,height,inner_a.y)
				var top_b:=Vector3(inner_b.x,height,inner_b.y)
				var low_a:=Vector3(a.x,0.062,a.y)
				var low_b:=Vector3(b.x,0.062,b.y)
				triangle(surface,top_center,top_a,top_b,tone)
				triangle(surface,top_a,low_a,low_b,tone)
				triangle(surface,top_a,low_b,top_b,tone)
	var mesh:=MeshInstance3D.new()
	mesh.name="FlagstoneRelief"
	mesh.mesh=surface.commit()
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/paving_stone.gdshader")
	material.set_shader_parameter("stone_texture",preload("res://assets/art/forest-flagstones.png"))
	mesh.material_override=material
	return mesh
