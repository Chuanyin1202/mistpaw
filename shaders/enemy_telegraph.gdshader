shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, fog_disabled;
uniform vec2 aim = vec2(0.0);
uniform float reach = 1.45;
uniform float depth_width = 0.7;
uniform float facing = 1.0;
uniform float progress = 0.0;
uniform bool ranged = false;
uniform int pattern=0;
void fragment() {
 vec2 p = (UV-0.5)*vec2(20.0,12.0);
 float d = max(max(length(p)-reach-0.7,length(p-aim)-reach),max(abs(p.y)-depth_width,abs(p.y-aim.y)-depth_width));
 d=max(d,-p.x*facing-0.35);
 if(ranged) {
  float t=clamp(dot(p,aim)/max(dot(aim,aim),0.001),0.0,1.0);
  d=length(p-aim*t)-0.22;
 }
 float mask=1.0-smoothstep(-0.025,0.025,d);
 if(pattern==1){
  float t=clamp(dot(p,aim)/max(dot(aim,aim),0.001),0.0,1.0);
  d=length(p-aim*t)-0.85;
 }
 if(pattern==2)d=length(p)-2.2;
 mask=1.0-smoothstep(-0.025,0.025,d);
 float rim=smoothstep(-0.10,-0.025,d);
 ALBEDO=mix(vec3(0.72,0.36,0.08),vec3(0.94,0.12,0.06),progress);
 ALPHA=mask*(0.06+progress*0.10+rim*0.42);
}
