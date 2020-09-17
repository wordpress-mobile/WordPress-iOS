precision highp float;

uniform sampler2D inputImageTexture;
varying vec2 textureCoordinate;

vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main() {
    vec4 color = texture2D(inputImageTexture, textureCoordinate);
    float grey = dot(color.rgb, W);
    gl_FragColor = vec4(grey, grey, grey, color.a);
}
