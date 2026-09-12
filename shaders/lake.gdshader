shader_type spatial;
render_mode cull_disabled;
// World-space ripples: broad, slow movement with finer intersecting capillary waves.
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
float waves(vec2 p, float t) {
 float warp=noise(p*0.45+vec2(t*0.035,0.0));
 return sin(p.x*2.8+p.y*5.3+t*0.7+warp*6.0)*0.025
       +sin(p.x*6.2-p.y*3.7-t*0.52+warp*3.0)*0.012
       +sin(p.x*9.1+p.y*12.7+t*1.1+warp*9.0)*0.003
       +noise(p*vec2(4.0,11.0)+vec2(t*0.08,-t*0.13))*0.028;
}
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_position.xz;
 float h=waves(p,TIME);
 float sx=(waves(p+vec2(0.045,0),TIME)-h)/0.045;
 float sz=(waves(p+vec2(0,0.045),TIME)-h)/0.045;
 NORMAL=normalize((VIEW_MATRIX*vec4(normalize(vec3(-sx,1.0,-sz)),0.0)).xyz);
 // The banks end at z=2.2, and the channel lies between x=9 and x=21.
 float bank_x=max(9.0-p.x,p.x-21.0);
 float shore=bank_x>0.0 ? max(0.0,p.y-2.2) : length(vec2(min(p.x-9.0,21.0-p.x),max(0.0,p.y-2.2)));
 float shallow=exp(-shore*0.8);
 float broad=noise(p*0.22+vec2(TIME*0.012,0));
 ALBEDO=mix(vec3(0.009,0.031,0.049),vec3(0.020,0.083,0.074),shallow*0.65+broad*0.18);
 // Numeric water colors above are linear; Compatibility expects sRGB.
 if (OUTPUT_IS_SRGB) {
  ALBEDO=mix(ALBEDO*12.92,1.055*pow(ALBEDO,vec3(1.0/2.4))-0.055,step(vec3(0.0031308),ALBEDO));
  // Match the muted forest reflection without Forward+ screen-space reflections.
  ALBEDO=mix(vec3(dot(ALBEDO,vec3(0.2126,0.7152,0.0722))),ALBEDO,0.80)*0.84;
 }
 ROUGHNESS=(OUTPUT_IS_SRGB ? 0.16 : 0.075)+noise(p*1.5)*0.035;
 METALLIC=0.05;
 SPECULAR=0.85;
}
