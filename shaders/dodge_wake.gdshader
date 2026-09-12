shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,fog_disabled;
uniform float phase=0.0;
void fragment(){
 vec2 p=UV;
 float tail=smoothstep(0.0,0.45,p.x)*(1.0-smoothstep(0.85,1.0,p.x));
 float lines=0.0;
 for(int i=0;i<3;i++){
  float y=0.27+float(i)*0.23+sin(p.x*3.0+phase*2.0+float(i))*0.05;
  lines+=exp(-pow((p.y-y)*65.0,2.0));
 }
 float edge=smoothstep(0.0,0.08,p.y)*(1.0-smoothstep(0.92,1.0,p.y));
 ALBEDO=vec3(0.34,0.7,0.76)*lines*tail*edge*(1.0-phase)*0.65;
 ALPHA=1.0;
}
