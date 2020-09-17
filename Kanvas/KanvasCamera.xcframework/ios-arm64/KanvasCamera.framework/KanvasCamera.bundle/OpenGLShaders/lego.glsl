precision highp float;

uniform sampler2D inputImageTexture;
uniform vec2 iResolution;
varying vec2 textureCoordinate;

float c = 0.03;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 middle = floor(fragCoord * c + .5) / c;

    vec3 color = texture2D(inputImageTexture, middle / iResolution.xy).rgb;

	float dis = distance(fragCoord, middle) * c * 2.;
	if(dis < .65 && dis > .55) {
		color *= dot(vec2(0.707), normalize(fragCoord - middle)) * .5 +1.;
	}

	vec2 delta = abs(fragCoord - middle) * c * 2.;
	float sdis = max(delta.x, delta.y);
	if(sdis > .9) {
		color *= .8;
	}

	fragColor = vec4(color,1.0);
}

void main() {
	mainImage(gl_FragColor, textureCoordinate*iResolution.xy);
}
