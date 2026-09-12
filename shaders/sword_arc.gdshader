shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
uniform sampler2D atlas : source_color, filter_nearest;
uniform sampler2D spin_atlas : source_color, filter_nearest, repeat_disable;
uniform sampler2D thrust_atlas : source_color, filter_linear, repeat_disable;
uniform int stroke = 0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float life = 0.0;
uniform bool facing_left = false;
uniform bool spinning = false;
uniform bool heavy = false;
void vertex() {
 MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
 vec2 uv=UV;
 if(facing_left) uv.x=1.0-uv.x;
 // The upper-right atlas cell is a coherent downward arc. Do not jump to
 // the lower-left cell, which reverses the arc's silhouette and position.
 vec2 arc_uv = stroke == 1 ? vec2(uv.y,1.0-uv.x) : uv;
 vec3 light=texture(atlas,vec2(0.5+arc_uv.x*0.5,arc_uv.y*0.5)).rgb;
 if(stroke == 2 && !spinning) light=texture(thrust_atlas,vec2(uv.x,(uv.y-(uv.x-0.5)*0.65)*0.35+0.325)).rgb;
 if (spinning) {
  vec2 p=UV-0.5;
  float angle=life*3.14159*(facing_left ? -1.0 : 1.0);
  vec2 rotated=mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)))*p+0.5;
  light=texture(spin_atlas,rotated).rgb;
 }
 float fade=1.0-smoothstep(0.25,1.0,life);
 float sweep=heavy ? 1.0-smoothstep(life*3.5-0.10,life*3.5+0.14,uv.y) : 1.0;
 ALBEDO=light*tint.rgb*fade*(heavy?1.2:0.8)*sweep;
 ALPHA=1.0;
}
