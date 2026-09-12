shader_type spatial;
#include "surface_relief.gdshaderinc"
uniform sampler2D stone_texture : source_color,filter_linear_mipmap,repeat_enable;
varying vec3 world;
varying vec3 world_normal;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 weights=pow(abs(world_normal),vec3(4.0));
 weights/=max(dot(weights,vec3(1.0)),0.001);
 vec3 stone=texture(stone_texture,world.zy*0.09).rgb*weights.x+texture(stone_texture,world.xz*0.09).rgb*weights.y+texture(stone_texture,world.xy*0.09).rgb*weights.z;
 float height=dot(stone,vec3(0.2126,0.7152,0.0722));
 float wet=(sin(world.x*1.4+sin(world.z*1.9))+1.0)*0.5*max(world_normal.y,0.0);
 ALBEDO=stone*vec3(0.87,0.88,0.80);
 ROUGHNESS=mix(0.87,0.30,wet*smoothstep(0.04,0.3,height));
 SPECULAR=0.5;
 NORMAL=surface_relief(NORMAL,VERTEX,height,0.018);
}
