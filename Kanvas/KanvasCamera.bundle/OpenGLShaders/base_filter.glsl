varying lowp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform lowp mat4 transform;

void main()
{
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
}
