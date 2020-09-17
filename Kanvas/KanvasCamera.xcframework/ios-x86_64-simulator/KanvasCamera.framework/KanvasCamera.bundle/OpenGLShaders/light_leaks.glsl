precision highp float;

uniform sampler2D inputImageTexture;
uniform float time;
varying vec2 textureCoordinate;

const float Pi = 3.14159;

void main() {
    vec2 p = textureCoordinate.xy;
    vec4 cam = texture2D(inputImageTexture, textureCoordinate);

    for(int i = 1; i < 6; i++) {
        vec2 newp = p;
        newp.x += 0.6 / float(i) * cos(float(i) * p.y + (time * 7.0) / 10.0 + 0.3 * float(i)) + 400. / 20.0;
        newp.y += 0.6 / float(i) * cos(float(i) * p.x + (time * 5.0) / 10.0 + 0.3 * float(i + 10)) - 400. / 20.0 + 15.0;
        p = newp;
    }
    vec4 col = vec4(2.0 * sin(3.0 * p.x) + 0.7, 1.2 * sin(3.0 * p.y) + 0.7, 3.0 * sin(p.x + p.y)+0.4, sin(1.0));
    float alphaDivisor = cam.a + step(cam.a, 0.2);
    gl_FragColor = cam * (col.a * (cam / alphaDivisor)
    		+ (1.5 * col * (1.0 - (cam / alphaDivisor))))
    		+ col * (1.0 - cam.a) + cam * (1.0 - col.a);
}
