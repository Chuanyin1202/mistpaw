shader_type spatial;
render_mode cull_disabled;
uniform sampler2D canopy:source_color,filter_linear_mipmap;
void vertex(){
 VERTEX.x+=sin(TIME*0.6+MODEL_MATRIX[3].x)*0.10;
 VERTEX.z+=sin(TIME*0.45+MODEL_MATRIX[3].x*0.3)*0.07;
}
void fragment(){
 // Use crown only, excluding the trunk, with a soft outer fade before alpha test.
 vec2 uv=vec2(UV.x,UV.y*0.48);
 vec4 leaves=texture(canopy,uv);
 float edge=smoothstep(0.0,0.14,UV.x)*smoothstep(0.0,0.14,1.0-UV.x)*smoothstep(0.0,0.12,UV.y)*smoothstep(0.0,0.12,1.0-UV.y);
 ALBEDO=vec3(0.0);
 ALPHA=leaves.a*edge;
 ALPHA_SCISSOR_THRESHOLD=0.5;
}
