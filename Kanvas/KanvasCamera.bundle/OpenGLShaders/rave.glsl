precision highp float;

uniform sampler2D inputImageTexture;
uniform float time;
varying vec2 textureCoordinate;

void main() {
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
    gl_FragColor.r *= abs(sin(time * 1.0));
    gl_FragColor.g *= abs(sin(time * 5.0 + 4.0));
    gl_FragColor.b *= abs(sin(time * 3.0 + 2.0));
    gl_FragColor.a = 1.0;
}