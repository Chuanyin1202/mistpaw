shader_type spatial;
#include "surface_relief.gdshaderinc"
uniform sampler2D rock_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D moss_texture : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world;
varying vec3 world_normal;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
vec2 mirror_uv(vec2 p){ return 1.0-abs(fract(p*0.5)*2.0-1.0); }
void fragment(){
 vec3 weights=pow(abs(world_normal),vec3(4.0));weights/=max(dot(weights,vec3(1.0)),0.001);
 vec3 rock=texture(rock_texture,mirror_uv(world.zy*0.20)).rgb*weights.x+texture(rock_texture,mirror_uv(world.xz*0.20)).rgb*weights.y+texture(rock_texture,mirror_uv(world.xy*0.20)).rgb*weights.z;
 vec3 green=texture(moss_texture,mirror_uv(world.zy*0.12)).rgb*weights.x+texture(moss_texture,mirror_uv(world.xz*0.12)).rgb*weights.y+texture(moss_texture,mirror_uv(world.xy*0.12)).rgb*weights.z;
 float strata=0.86+0.14*smoothstep(-0.65,0.15,sin(world.y*6.0+sin(world.x*0.75)*2.0+sin(world.z*1.7)));
 float moss=smoothstep(0.3,0.8,world_normal.y+sin(world.x*3.0+world.z*2.0)*0.15);
 float wet=1.0-smoothstep(-3.55,-2.9,world.y);
 float mineral=0.93+0.07*sin(world.x*0.48+world.y*0.65+sin(world.z));
 ALBEDO=mix(rock*vec3(0.82,0.85,0.77)*strata,green*0.75,moss)*(1.0-wet*0.42)*mineral;
 ROUGHNESS=mix(0.93,0.38,wet);
 NORMAL=surface_relief(NORMAL,VERTEX,dot(rock,vec3(0.2126,0.7152,0.0722)),0.012);
}
