shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, fog_disabled;
uniform float age=0.0;
uniform float ground_back=-4.7;
varying vec3 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=(UV-0.5)*10.0;
 float d=length(p);
 float a=atan(p.y,p.x);
 float jagged=a*9.0+sin(d*13.0)*0.24+sin(d*27.0)*0.12;
 float line_distance=abs(sin(jagged))*max(d,0.25);
 float cracks=1.0-smoothstep(0.035,0.08,line_distance);
 float edges=(1.0-smoothstep(0.07,0.14,line_distance))*(1.0-cracks);
 float branches=1.0-smoothstep(0.025,0.065,abs(d-(1.1+sin(a*7.0)*0.18)));
 cracks=max(cracks,branches*0.7);
 float extent=2.45+sin(a*5.0)*0.24;
 float reveal=1.0-smoothstep(min(age*22.0,extent)-0.15,min(age*22.0,extent),d);
 float scar=cracks*reveal*(1.0-smoothstep(1.5,2.4,age));
 float grit=0.55+0.22*sin(p.x*32.0+sin(p.y*17.0))+0.20*sin(p.y*41.0);
 float dust_ring=exp(-pow((d-age*4.0)/0.55,2.0));
 float dust=dust_ring*grit*(1.0-smoothstep(0.1,0.85,age))*0.6;
 float mask=smoothstep(ground_back,ground_back+0.15,world_at.z)*(1.0-smoothstep(1.55,1.7,world_at.z));
 float edge=edges*reveal*(1.0-smoothstep(1.5,2.4,age));
 ALBEDO=mix(vec3(0.035,0.025,0.015),vec3(0.42,0.32,0.19),clamp(edge+dust*2.0,0.0,1.0));
 ALPHA=max(max(scar*0.95,edge*0.75),dust)*mask*(1.0-smoothstep(3.5,4.0,d));
}
