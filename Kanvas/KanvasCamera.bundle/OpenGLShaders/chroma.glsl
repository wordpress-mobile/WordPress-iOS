precision highp float;

uniform sampler2D inputImageTexture;
uniform float time;
varying vec2 textureCoordinate;

void main() {
    vec2 uv = textureCoordinate.xy;

    vec4 color;

    float go = sin(time) * 0.01;
    float go2 = sin(time) * 0.01;

    vec2 strength = vec2(1.5, 0.5);

    color.r = texture2D(inputImageTexture, uv - vec2(go, 0.0) * strength).r;
    color.g = texture2D(inputImageTexture, uv - vec2(0.005, go2) * strength).g;
    color.b = texture2D(inputImageTexture, uv).g;

    color.a = 1.0;

    gl_FragColor = color;
}
