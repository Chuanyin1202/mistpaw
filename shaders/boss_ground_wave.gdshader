shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
uniform float radius=0.0;
uniform float strength=0.0;
uniform bool danger=false;
uniform float ground_back=-4.7;
varying vec3 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=(UV-0.5)*10.0;
 float d=length(p);
 float ring=1.0-smoothstep(0.10,0.28,abs(d-radius));
 float texture_break=0.65+0.35*sin(atan(p.y,p.x)*31.0+d*23.0);
 vec3 color=danger?vec3(1.0,0.35,0.10):vec3(0.7,0.50,0.22);
 float ground_mask=smoothstep(ground_back,ground_back+0.15,world_at.z)*(1.0-smoothstep(1.55,1.7,world_at.z));
 ALBEDO=color*ring*texture_break*strength*ground_mask*(1.0-smoothstep(4.5,4.9,d));
 ALPHA=1.0;
}
