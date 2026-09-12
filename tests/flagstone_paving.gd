extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok:failures+=1
func _initialize():call_deferred("run")
func run():
	var paving=preload("res://scripts/flagstone_paving.gd")
	var forest=preload("res://scripts/forest.gd")
	for cuts in [[-12.0,4.0,9.0],[21.0,26.0,62.0]]:
		var node:MeshInstance3D=paving.build(cuts,forest.road_back)
		var arrays:Array=node.mesh.surface_get_arrays(0)
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var bounds_ok:=true
		var normals_ok:=true
		for i in range(vertices.size()):
			var p:=vertices[i]
			bounds_ok=bounds_ok and p.is_finite() and p.x>=cuts[0]-0.001 and p.x<=cuts[-1]+0.001 and p.z>=forest.road_back(p.x)-0.001 and p.z<=1.701 and p.y>=0.061 and p.y<=0.106
			normals_ok=normals_ok and normals[i].is_finite() and normals[i].y>0 and is_equal_approx(normals[i].length(),1.0)
		check(bounds_ok,"slabs stay inside playable terrace and visual height budget")
		check(normals_ok,"all stone faces have finite upward lighting normals")
		check(node.get_child_count()==0 and node.mesh.get_surface_count()==1,"paving adds one mesh and no collision bodies")
		check(vertices.size()>1000 and vertices.size()<30000,"stone geometry remains within its vertex budget")
		var repeat:MeshInstance3D=paving.build(cuts,forest.road_back)
		check(repeat.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==vertices,"stone layout is deterministic")
		repeat.free()
		node.free()
	quit(1 if failures else 0)
