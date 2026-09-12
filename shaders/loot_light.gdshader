shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,fog_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool ground = false;
uniform float strength = 1.0;
void vertex(){
 if(!ground){
  vec3 up=vec3(0.0,1.0,0.0);
  vec3 right=normalize(cross(up,INV_VIEW_MATRIX[2].xyz));
  MODELVIEW_MATRIX=VIEW_MATRIX*mat4(vec4(right,0.0),vec4(up,0.0),vec4(cross(right,up),0.0),MODEL_MATRIX[3]);
 }
}
void fragment(){
 float light=0.0;
 if(ground){
  float radius=length(UV*2.0-1.0);
  light=exp(-radius*radius*6.0)*(1.0-smoothstep(0.65,1.0,radius))*0.32;
 }else{
  float x=abs(UV.x*2.0-1.0);
  float edge=1.0-smoothstep(0.65,1.0,x);
  float cap=smoothstep(0.0,0.32,UV.y)*(1.0-smoothstep(0.92,1.0,UV.y));
  float core=exp(-x*x*2200.0)*1.6;
  float halo=exp(-x*x*15.0)*0.25;
  light=(core+halo)*edge*cap;
 }
 ALBEDO=tint.rgb*light*strength;
 ALPHA=1.0;
}
