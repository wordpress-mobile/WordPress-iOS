precision mediump float;

uniform sampler2D inputImageTexture;
varying vec2 textureCoordinate;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

vec3 StripsPattern(vec2 position) {
	vec2 p = (position - 0.5) * 500.;

	float angle = 0.7;
	vec2 direction = vec2(cos(angle), sin(angle));

	float contrast = cos(dot(p, direction));
	vec3 color = vec3(1. - contrast);

	float gray = dot(color, W);
	if(gray > 0.5) {
		return vec3(220. / 255., 220. / 255., 220. / 255.);
	} else {
		return vec3(120. / 255., 120. / 255., 120. / 255.);
	}
}

void main() {
	vec3 color;

	vec3 border;
	float dx = 1./720.;
	float dy = 1./720.;
	vec3 sample0 = texture2D(inputImageTexture, vec2(textureCoordinate.x - dx, textureCoordinate.y + dy)).rgb;
	vec3 sample1 = texture2D(inputImageTexture, vec2(textureCoordinate.x - dx, textureCoordinate.y)).rgb;
	vec3 sample2 = texture2D(inputImageTexture, vec2(textureCoordinate.x - dx, textureCoordinate.y - dy)).rgb;
	vec3 sample3 = texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y + dy)).rgb;
	vec3 sample4 = texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y)).rgb;
	vec3 sample5 = texture2D(inputImageTexture, vec2(textureCoordinate.x, textureCoordinate.y - dy)).rgb;
	vec3 sample6 = texture2D(inputImageTexture, vec2(textureCoordinate.x + dx, textureCoordinate.y + dy)).rgb;
	vec3 sample7 = texture2D(inputImageTexture, vec2(textureCoordinate.x + dx, textureCoordinate.y)).rgb;
	vec3 sample8 = texture2D(inputImageTexture, vec2(textureCoordinate.x + dx, textureCoordinate.y - dy)).rgb;

	vec3 horizEdge = sample2 + sample5 + sample8 - (sample0 + sample3 + sample6);
	vec3 vertEdge = sample0 + sample1 + sample2 - (sample6 + sample7 + sample8);

	border = sqrt((horizEdge * horizEdge) + (vertEdge * vertEdge));

	float gray = dot(sample4, W);

	if (border.r > 0.5 || border.g > 0.5 || border.b > 0.5) {
		color = vec3(0.0) ;
	} else {
		if(gray < 0.25) {
			color = vec3(20./255., 20./255., 20./255.);
		} else if(gray >= 0.25 && gray < 0.4) {
			color = StripsPattern(textureCoordinate);
		} else {
			color = vec3(1.);
		}
	}

	gl_FragColor = vec4(color, 1.0);
}
