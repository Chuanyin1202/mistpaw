shader_type spatial;
render_mode unshaded, depth_draw_never;
void fragment() {
 ALBEDO=vec3(0.03,0.045,0.035);
 ALPHA=(1.0-smoothstep(0.1,0.5,length(UV-vec2(0.5))))*0.55;
}
