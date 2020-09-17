varying lowp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform sampler2D textureOverlay;

void main()
{
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 textureOverlayColor = texture2D(textureOverlay, textureCoordinate);

    lowp float alpha = 1.;
    gl_FragColor = vec4(mix(textureColor.rgb, textureOverlayColor.rgb, textureOverlayColor.a * alpha), textureColor.a);
}
