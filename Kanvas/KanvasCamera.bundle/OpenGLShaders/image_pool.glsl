precision highp float;

uniform sampler2D inputImageTexture;
uniform float time;
varying vec2 textureCoordinate;

#define TAU 6.28318530718
#define MAX_ITER 5

void main() {

    float time1 = time * .5 + 23.0;
    vec2 uv = textureCoordinate.xy;

#ifdef SHOW_TILING
    vec2 p = mod(uv * TAU * 2.0, TAU) - 250.0;
#else
    vec2 p = mod(uv * TAU, TAU) - 250.0;
#endif

    vec2 i = vec2(p);
    float c = 1.0;
    float inten = .005;

    for (int n = 0; n < MAX_ITER; n++) {
        float t = time * (1.0 - (3.5 / float(n + 1)));
        i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0 / length(vec2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
    }
    c /= float(MAX_ITER);
    c = 1.17 - pow(c, 1.4);
    vec3 color = vec3(pow(abs(c), 8.0));
    color = clamp(color + vec3(0.0, 0.35, 0.5), 0.0, 1.0);

    gl_FragColor = vec4(color, 1.0);

    float stongth = 0.3;
    float waveu = sin((uv.y + time) * 20.0) * 0.5 * 0.05 * stongth;
    vec4 textureColor = texture2D(inputImageTexture, uv + vec2(waveu, 0));

    gl_FragColor.r = (gl_FragColor.r + (textureColor.r * 1.3)) /2.;
    gl_FragColor.g = (gl_FragColor.g + (textureColor.g * 1.3)) /2.;
    gl_FragColor.b = (gl_FragColor.b + (textureColor.b * 1.3)) /2.;
    gl_FragColor.a = 1.0;
}
