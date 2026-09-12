shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
uniform vec4 tint:source_color=vec4(0.7,0.5,0.2,1.0);
uniform float opacity=0.0;
uniform bool leaf=false;
void fragment(){
 vec2 p=UV*2.0-1.0;
 float mask;
 if(leaf){
  float width=0.46*(1.0-p.y*p.y);
  mask=(1.0-smoothstep(width-0.06,width,abs(p.x)))*(1.0-smoothstep(0.85,1.0,abs(p.y)));
  ALBEDO=tint.rgb*mix(0.7,1.0,step(0.0,p.x));
 }else{
  mask=pow(max(0.0,1.0-dot(p,p)),2.0);
  ALBEDO=tint.rgb;
 }
 ALPHA=mask*opacity*tint.a;
}
