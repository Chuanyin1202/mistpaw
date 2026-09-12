shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
uniform sampler2D spark : source_color, filter_nearest, repeat_disable;
uniform float life = 0.0;
uniform float angle = 0.0;
void vertex() {
 MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
 vec2 p=UV-0.5;
 vec2 uv=mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)))*p+0.5;
 ALBEDO=texture(spark,uv).rgb*(1.0-smoothstep(0.05,1.0,life));
 ALPHA=1.0;
}
