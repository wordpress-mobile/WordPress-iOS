varying lowp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    lowp vec2 uv = textureCoordinate;
    if (uv.x > 1. || uv.y > 1. || uv.x < 0. || uv.y < 0.) {
        gl_FragColor = vec4(0., 0., 0., 0.);
    } else {
        gl_FragColor = texture2D(inputImageTexture, uv);
    }
}
