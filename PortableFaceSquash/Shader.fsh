varying lowp vec2 texCoordOut;
uniform sampler2D tex;

uniform lowp vec2 corners[4];

lowp vec2 interpolateQuad(lowp float s, lowp float t) {
    lowp vec2 p0_p1 = mix(corners[0], corners[1], s);
    lowp vec2 p3_p2 = mix(corners[3], corners[2], s);
    return mix(p0_p1, p3_p2, t);
}

void main(void) {
    gl_FragColor = texture2D(tex, interpolateQuad(texCoordOut.x, texCoordOut.y));
}
