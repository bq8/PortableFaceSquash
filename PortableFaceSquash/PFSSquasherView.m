//
//  PFSSquasherView.m
//  PortableFaceSquash
//
//  Created by Brian Quach on 2017/02/22.
//  Copyright © 2017 Brian Quach. All rights reserved.
//

#import "PFSSquasherView.h"
#import <OpenGLES/ES2/gl.h>

typedef struct {
    float Position[3];
    float TexCoord[2];
} Vertex;

const Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0}},
    {{1, 1, 0}, {1, 1}},
    {{-1, 1, 0}, {0, 1}},
    {{-1, -1, 0}, {0, 0}}
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

@interface PFSSquasherView () {
    EAGLContext *_context;
    
    GLuint _colorBufferHandle;
    GLuint _frameBufferHandle;
    
    GLuint _positionAttrib;
    GLuint _texCoordAttrib;
    
    GLuint _quadCornerUniform;
    GLuint _textureUniform;
    
    GLuint _texture;
    
    GLint _backingWidth;
    GLint _backingHeight;
    
    CGPoint handleCoords[4];
}

@end

@implementation PFSSquasherView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark - Lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self setupLayer];
    [self setupContext];
    [self setupBuffers];
    [self setupShaders];
    [self setupVBOs];
    
    _texture = [self setupTexture:@"DSCF2319.jpg"];
    handleCoords[0] = CGPointMake(0, 1);
    handleCoords[1] = CGPointMake(1, 1);
    handleCoords[2] = CGPointMake(1, 0);
    handleCoords[3] = CGPointMake(0, 0);
    
    [self render];
}

#pragma mark - OpenGL ES Drawing

- (void)render {
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, _backingWidth, _backingHeight);
    
    glVertexAttribPointer(_positionAttrib,
                          3,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(Vertex),
                          0);
    glVertexAttribPointer(_texCoordAttrib,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(Vertex),
                          (GLvoid *) (sizeof(float) * 3));
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(_textureUniform, 0);
    

    GLfloat quadCorners[4][2] = {{handleCoords[0].x, handleCoords[0].y},
                                 {handleCoords[1].x, handleCoords[1].y},
                                 {handleCoords[2].x, handleCoords[2].y},
                                 {handleCoords[3].x, handleCoords[3].y}};
    glUniform2fv(_quadCornerUniform, 4, (GLfloat *)&quadCorners);
    
    glDrawElements(GL_TRIANGLES,
                   sizeof(Indices)/sizeof(Indices[0]),
                   GL_UNSIGNED_BYTE,
                   0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Squash Handles

- (void)updateHandle:(NSUInteger)handle position:(CGPoint)position {
    handleCoords[handle] = position;
}

#pragma mark - Setup

- (void)setupLayer {
    [(CAEAGLLayer *)self.layer setOpaque:NO];
}

- (void)setupContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!_context || ![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to setup context.");
        exit(1);
    }
}

- (void)setupBuffers {
    glGenRenderbuffers(1, &_colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    glGenFramebuffers(1, &_frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBufferHandle);
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:nil];
    
    NSError *error;
    NSString *sourceString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    if (!sourceString) {
        NSLog(@"Failed to load shader: %@", error.localizedDescription);
        exit(1);
    }
    
    GLuint shader = glCreateShader(shaderType);
    
    const char *sourceStringUTF8 = [sourceString UTF8String];
    glShaderSource(shader, 1, &sourceStringUTF8, NULL);
    
    glCompileShader(shader);
    
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shader;
}

- (void)setupShaders {
    GLuint vertexShader = [self compileShader:@"Shader.vsh" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"Shader.fsh" withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    _positionAttrib = glGetAttribLocation(programHandle, "position");
    glEnableVertexAttribArray(_positionAttrib);
    
    _texCoordAttrib = glGetAttribLocation(programHandle, "texCoord");
    glEnableVertexAttribArray(_texCoordAttrib);
    
    _quadCornerUniform = glGetUniformLocation(programHandle, "corners");
    _textureUniform = glGetUniformLocation(programHandle, "tex");
}

- (void)setupVBOs {
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}

- (GLuint)setupTexture:(NSString *)fileName {
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData,
                                                       width,
                                                       height,
                                                       8,
                                                       width * 4,
                                                       CGImageGetColorSpace(spriteImage),
                                                       kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

@end
