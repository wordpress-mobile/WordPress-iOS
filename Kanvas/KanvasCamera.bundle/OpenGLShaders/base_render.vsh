attribute vec4 position;
attribute mediump vec4 texturecoordinate;

varying mediump vec2 textureCoordinate;

void main()
{
    gl_Position = position;
    textureCoordinate = texturecoordinate.xy;
}
