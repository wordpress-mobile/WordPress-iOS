precision highp float;

uniform sampler2D inputImageTexture;
varying vec2 textureCoordinate;

void main() {
    vec2 uv = textureCoordinate.xy;
    vec4 c[4];
    c[0] = texture2D(inputImageTexture, uv);
    c[1] = texture2D(inputImageTexture, vec2(1.0-uv.x, uv.y));
    c[2] = texture2D(inputImageTexture, vec2(uv.x, 1.0-uv.y));
    c[3] = texture2D(inputImageTexture, vec2(1.0-uv.x, 1.0-uv.y));
    
    vec4 color = (uv.y >= 0.5 && uv.x >= 0.5) ? c[0] :
    	(uv.y >= 0.5 && uv.x < 0.5) ? c[1] :
    	(uv.y < 0.5 && uv.x >= 0.5) ? c[2] : c[3];
    
    gl_FragColor = color;
}
