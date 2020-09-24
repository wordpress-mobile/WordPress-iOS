precision highp float;

uniform sampler2D inputImageTexture;
varying vec2 textureCoordinate;

void main() {
    vec2 uv = textureCoordinate.xy;
    vec4 c[4];
    c[0] = texture2D(inputImageTexture, uv);
    c[1] = texture2D(inputImageTexture, vec2(1.0 - uv.x, uv.y));

    vec4 color = vec4(0.);

    if (uv.x >= 0.5) {
        color = c[0];
    } else if (uv.x <= 0.5) {
        color = c[1];
    }

    gl_FragColor = color;
}
