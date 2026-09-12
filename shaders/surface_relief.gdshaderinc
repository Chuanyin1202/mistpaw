// Perturb the shading normal from local texture height; silhouettes stay geometric.
vec3 surface_relief(vec3 n,vec3 position,float height,float strength) {
 vec3 px=dFdx(position),py=dFdy(position);
 vec3 r1=cross(py,n),r2=cross(n,px);
 float determinant=dot(px,r1);
 vec3 gradient=sign(determinant)*(dFdx(height)*r1+dFdy(height)*r2);
 return normalize(max(abs(determinant),0.000001)*n-strength*gradient);
}
