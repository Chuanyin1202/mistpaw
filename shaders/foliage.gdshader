shader_type spatial;
render_mode cull_disabled;
uniform sampler2D foliage_texture : source_color, filter_nearest_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform float sway=0.045;
uniform vec2 flip_axes=vec2(1.0);
void vertex(){
 float phase=MODEL_MATRIX[3].x*0.73+MODEL_MATRIX[3].z*0.31;
 float wind=sin(TIME*0.85+phase)*0.65+sin(TIME*1.7+phase*1.8)*0.35;
 VERTEX.x+=wind*sway*pow(1.0-UV.y,2.0);
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
 MODELVIEW_NORMAL_MATRIX=mat3(MODELVIEW_MATRIX);
}
void fragment(){
 vec4 leaf=texture(foliage_texture,(UV-0.5)*flip_axes+0.5);
 ALBEDO=leaf.rgb*tint.rgb;
 ALPHA=leaf.a;
 ALPHA_SCISSOR_THRESHOLD=0.48;
 ROUGHNESS=0.95;
}
