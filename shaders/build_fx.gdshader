shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never,fog_disabled;
uniform sampler2D art : source_color,filter_linear,repeat_disable;
uniform bool billboard=true;
uniform bool flip=false;
uniform int kind=0;
uniform float life=0.0;
uniform float strength=0.5;
void vertex(){
 if(billboard) MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
}
void fragment(){
 vec2 uv=UV;
 if(flip) uv.x=1.0-uv.x;
 if(kind==1)uv.y=uv.y*0.5+0.25;
 float fade=1.0-smoothstep(0.15,1.0,life);
 if(kind==2)fade=1.0-smoothstep(0.7,1.0,life);
 vec3 ink=texture(art,uv).rgb;
 if(kind==3){
  ink=max(ink-vec3(0.018),vec3(0.0));
  ink*=smoothstep(0.0,0.08,uv.x)*(1.0-smoothstep(0.92,1.0,uv.x))*smoothstep(0.0,0.08,uv.y)*(1.0-smoothstep(0.92,1.0,uv.y));
 }
 ALBEDO=ink*strength*fade;
 ALPHA=1.0;
}
