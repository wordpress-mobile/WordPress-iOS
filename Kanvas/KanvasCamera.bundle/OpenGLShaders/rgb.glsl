precision highp float;

uniform sampler2D inputImageTexture;
uniform float time;
varying vec2 textureCoordinate;

void main() {
    vec2 uv = vec2(textureCoordinate.xy);
    vec2 control = vec2(0.7, 0.7);
    vec2 m = vec2(control.xy);
    float d = (length(m) < .02) ? .015 : m.x / 10.;

    gl_FragColor = vec4(texture2D(inputImageTexture, uv - d).x, texture2D(inputImageTexture, uv).x, texture2D(inputImageTexture, uv + d).x, 1.0);
}
