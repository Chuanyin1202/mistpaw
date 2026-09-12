shader_type canvas_item;
uniform float strength=0.0;
void fragment(){
 vec2 p=abs(UV-0.5)*2.0;
 float edge=smoothstep(0.6,1.0,max(p.x,p.y));
 COLOR=vec4(0.48,0.035,0.025,edge*strength);
}
