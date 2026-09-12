shader_type canvas_item;
// Atlas artwork is opaque. Clip in local sprite UV, never atlas UV.
uniform float diameter = 72.0;
varying vec2 local_uv;
void vertex() { local_uv = VERTEX / diameter; }
void fragment() {
 vec4 art = texture(TEXTURE, UV);
 float d = length(local_uv - vec2(0.5));
 art.a *= 1.0 - smoothstep(0.489, 0.499, d);
 COLOR *= art;
}
