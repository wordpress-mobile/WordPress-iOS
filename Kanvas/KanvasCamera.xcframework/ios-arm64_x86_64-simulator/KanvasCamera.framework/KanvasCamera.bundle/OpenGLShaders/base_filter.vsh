attribute vec4 position;
attribute lowp vec4 texturecoordinate;

uniform lowp mat4 transform;

varying lowp vec2 textureCoordinate;

void main()
{
    gl_Position = position;
    textureCoordinate = ((vec4((texturecoordinate.xy - 0.5) * 2., 0., 1.) * transform).xy / 2.) + 0.5;
}
