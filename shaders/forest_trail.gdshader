shader_type spatial;
#include "surface_relief.gdshaderinc"
uniform sampler2D soil : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D vegetation : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world.xz;
 vec2 uv=p*0.13;
 vec3 grain=texture(soil,uv).rgb;
 grain*=0.94+noise(p*0.23)*0.12;
 float patches=noise(p*2.5)*0.6+noise(p*8.0)*0.4;
 float verge=smoothstep(0.2,1.1,abs(p.y+sin(p.x*0.65)*0.25)+noise(p*1.3)*0.85-0.25);
 float crevice=1.0-smoothstep(0.055,0.17,dot(grain,vec3(0.2126,0.7152,0.0722)));
 float moss=(verge*0.22+smoothstep(0.48,0.76,patches)*0.18)*mix(0.15,1.0,crevice);
 vec3 greenery=texture(vegetation,1.0-abs(fract(p*0.06)*2.0-1.0)).rgb;
 float worn=smoothstep(0.62,0.80,noise(p*0.65));
 float leaf_litter=smoothstep(0.86,0.96,noise(p*12.0))*smoothstep(0.43,0.72,noise(p*0.55));
 ALBEDO=mix(grain*vec3(0.64,0.66,0.59),greenery*0.65,moss*(1.0-worn*0.6))*(0.90+noise(p*0.23)*0.16);
 ALBEDO=mix(ALBEDO,vec3(0.27,0.15,0.055),leaf_litter*0.5);
 // Broad canopy shade with small gaps; modulation is deliberately subtle.
 float canopy=noise(p*0.43+vec2(2.0,7.0))*0.7+noise(p*1.65)*0.3;
 ALBEDO*=mix(0.78,1.10,smoothstep(0.30,0.65,canopy));
 float wet=smoothstep(0.42,0.72,noise(p*0.75+8.0))*(1.0-moss*0.75);
 ROUGHNESS=mix(0.86,0.29,wet);
 SPECULAR=0.45;
 // Filter away grain before deriving relief: chipped slab edges should
 // catch light without turning each texture pixel into a shiny bump.
 float relief=dot(textureLod(soil,uv,3.5).rgb,vec3(0.2126,0.7152,0.0722));
 NORMAL=surface_relief(NORMAL,VERTEX,relief,0.14);
}
