shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
uniform float age=0.0;
uniform bool healing=false;
uniform float facing=1.0;
void vertex(){
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
}
void fragment(){
 vec2 p=(UV-0.5)*2.0;
 float fade=pow(1.0-clamp(age,0.0,1.0),1.5);
 if(healing){
  // Three inward curling wisps, soft volume at the center; no annular outline.
  float mist=exp(-dot(p*vec2(1.5,1.1),p*vec2(1.5,1.1))*5.0)*0.24;
  for(int i=0;i<3;i++){
   float a=float(i)*2.094+age*1.8;
   vec2 center=vec2(cos(a)*0.55*(1.0-age),sin(a)*0.38-age*0.15);
   vec2 q=(p-center)*vec2(1.7,0.8);
   mist+=exp(-dot(q,q)*22.0)*0.65;
  }
  ALBEDO=vec3(1.0,0.018,0.035)*mist*fade*1.7;
 }else{
  p.x*=facing;
  float r=length(p);
  float radius=0.55+age*0.35;
  float ring=exp(-pow((r-radius)*28.0,2.0));
  float aura=exp(-pow((r-radius)*7.0,2.0))*0.25;
  ALBEDO=vec3(0.38,0.72,1.0)*(ring+aura)*fade*smoothstep(-0.45,0.2,p.x)*1.7;
 }
 ALPHA=1.0;
}
