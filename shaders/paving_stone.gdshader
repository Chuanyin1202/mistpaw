shader_type spatial;
uniform sampler2D stone_texture:source_color,filter_linear_mipmap,repeat_enable;
void fragment(){
 vec3 stone=texture(stone_texture,UV,1.5).rgb;
 ALBEDO=stone*vec3(0.61,0.63,0.56)*COLOR.r;
 ROUGHNESS=COLOR.g;
 SPECULAR=0.5;
}
