attribute vec4 position;
attribute vec2 texCoord;

varying vec2 texCoordOut;

void main(void) {
    gl_Position = position;
    texCoordOut = texCoord;
}
