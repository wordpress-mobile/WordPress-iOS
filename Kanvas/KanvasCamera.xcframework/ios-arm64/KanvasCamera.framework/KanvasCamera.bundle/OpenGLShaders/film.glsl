precision highp float;

uniform sampler2D inputImageTexture;
uniform float time;
varying vec2 textureCoordinate;


float hash(in float n) {
    return fract(sin(n) * 43758.5453123);
}

void main() {
   vec2 res = vec2(1., 1.);
   vec2 p = textureCoordinate.xy / res.xy;

   vec2 u = p * 2. - 1.;
   vec2 n = u * vec2(res.x / res.y, 1.0);
   vec3 c = texture2D(inputImageTexture, p).xyz;

   if (mod(textureCoordinate.y * .5, 1.) > 1.) {
       gl_FragColor = vec4(vec3(0), 1);
       return;
   }
   c += hash((hash(n.x) + n.y) * time) * 0.3;

   gl_FragColor = vec4(c, 1.0);
}