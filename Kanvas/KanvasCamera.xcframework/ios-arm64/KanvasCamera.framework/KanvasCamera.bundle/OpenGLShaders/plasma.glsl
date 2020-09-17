precision highp float;

uniform sampler2D inputImageTexture;
uniform float time;
varying vec2 textureCoordinate;

vec3 rainbow(float h) {
	h = mod(mod(h, 1.0) + 1.0, 1.0);
	float h6 = h * 6.0;
	float r = clamp(h6 - 4.0, 0.0, 1.0) + clamp(2.0 - h6, 0.0, 1.0);
	float g = h6 < 2.0 ? clamp(h6, 0.0, 1.0) : clamp(4.0 - h6, 0.0, 1.0);
	float b = h6 < 4.0 ? clamp(h6 - 2.0, 0.0, 1.0) : clamp(6.0 - h6, 0.0, 1.0);
	return vec3(r, g, b);
}

vec3 plasma(vec2 textureCoordinate) {
	const float speed = 12.0;
	const float scale = 2.5;
	
	const float startA = 563.0 / 512.0;
	const float startB = 233.0 / 512.0;
	const float startC = 4325.0 / 512.0;
	const float startD = 312556.0 / 512.0;
	
	const float advanceA = 6.34 / 512.0 * 18.2 * speed;
	const float advanceB = 4.98 / 512.0 * 18.2 * speed;
	const float advanceC = 4.46 / 512.0 * 18.2 * speed;
	const float advanceD = 5.72 / 512.0 * 18.2 * speed;
	
	vec2 uv = textureCoordinate * scale;
	
	float a = startA + time * advanceA;
	float b = startB + time * advanceB;
	float c = startC + time * advanceC;
	float d = startD + time * advanceD;
	
	float n = sin(a + 3.0 * uv.x) + sin(b - 4.0 * uv.x) + sin(c + 2.0 * uv.y) + sin(d + 5.0 * uv.y);
	
	n = mod(((4.0 + n) / 4.0), 1.0);
	
	uv = textureCoordinate.xy;
	n += texture2D(inputImageTexture, uv).r;
	
	return rainbow(n);
}

void main() {
    vec3 green = vec3(0.173, 0.5, 0.106);
	vec2 uv = vec2(textureCoordinate.xy);
	vec3 image = texture2D(inputImageTexture, uv).rgb;
	float greenness = 1.0 - (length(image - green) / length(vec3(1, 1, 1)));
	float imageAlpha = clamp((greenness - 0.7) / 0.2, 0.0, 1.0);
	gl_FragColor = vec4(image * (1.0 - imageAlpha), 1.0) + vec4(plasma(textureCoordinate) * imageAlpha, 1.0);
}
