//
//  ViewController.m
//  MTL
//
//  Created by Ricardo Rendon Cepeda on 30/10/12.
//  Copyright (c) 2012 RRC. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@end

struct AttributeHandles
{
    GLint   aVertex;
    GLint   aNormal;
    GLint   aTexture;
};

struct UniformHandles
{
    GLuint  uProjectionMatrix;
    GLuint  uModelViewMatrix;
    GLuint  uNormalMatrix;
    
    GLint   uAmbient;
    GLint   uDiffuse;
    GLint   uSpecular;
    GLint   uExponent;
    
    GLint   uTexture;
    GLint   uMode;
};

@implementation ViewController
{
    struct AttributeHandles _attributes;
    struct UniformHandles   _uniforms;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize Context & OpenGL ES
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    // Setup View
    self.glkView = (GLKView *) self.view;
    self.glkView.context = self.context;
    self.glkView.opaque = YES;
    self.glkView.backgroundColor = [UIColor blackColor];
    self.glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.glkView.drawableMultisample = GLKViewDrawableMultisample4X;
    
    // Initialize Class Objects
    self.shaderProcessor = [[ShaderProcessor alloc] init];
    
    // Setup OpenGL ES
    [self setupOpenGLES];
}

- (void)setupOpenGLES
{
    [EAGLContext setCurrentContext:self.context];
    
    // Enable depth test
    glEnable(GL_DEPTH_TEST);
    
    // Projection Matrix
    float aspectRatio = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0f), aspectRatio, 0.1, 1.1);
    
    // ModelView Matrix
    _modelViewMatrix = GLKMatrix4Identity;
    
    // Load Texture
    UIImage* textureImage = [UIImage imageNamed:@"cube.png"];
    [self loadTexture:textureImage];
    
    // Create the GLSL program
    _program = [self.shaderProcessor BuildProgram:ShaderV with:ShaderF];
    glUseProgram(_program);
    
    // Extract the attribute handles
    _attributes.aVertex = glGetAttribLocation(_program, "aVertex");
    _attributes.aNormal = glGetAttribLocation(_program, "aNormal");
    _attributes.aTexture = glGetAttribLocation(_program, "aTexture");
    
    // Extract the uniform handles
    _uniforms.uProjectionMatrix = glGetUniformLocation(_program, "uProjectionMatrix");
    _uniforms.uModelViewMatrix = glGetUniformLocation(_program, "uModelViewMatrix");
    _uniforms.uNormalMatrix = glGetUniformLocation(_program, "uNormalMatrix");
    _uniforms.uAmbient = glGetUniformLocation(_program, "uAmbient");
    _uniforms.uDiffuse = glGetUniformLocation(_program, "uDiffuse");
    _uniforms.uSpecular = glGetUniformLocation(_program, "uSpecular");
    _uniforms.uExponent = glGetUniformLocation(_program, "uExponent");
    _uniforms.uTexture = glGetUniformLocation(_program, "uTexture");
    _uniforms.uMode = glGetUniformLocation(_program, "uMode");
}

- (void)loadTexture:(UIImage *)textureImage
{
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    CGImageRef cgImage = textureImage.CGImage;
    float imageWidth = CGImageGetWidth(cgImage);
    float imageHeight = CGImageGetHeight(cgImage);
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, CFDataGetBytePtr(data));
}

- (void)updateViewMatrices
{
    // ModelView Matrix
    _modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.1, -0.6);
    _modelViewMatrix = GLKMatrix4Rotate(_modelViewMatrix, GLKMathDegreesToRadians(self.rotateX.value), 1.0, 0.0, 0.0);
    _modelViewMatrix = GLKMatrix4Rotate(_modelViewMatrix, GLKMathDegreesToRadians(self.rotateY.value), 0.0, 1.0, 0.0);
    _modelViewMatrix = GLKMatrix4Rotate(_modelViewMatrix, GLKMathDegreesToRadians(self.rotateZ.value), 0.0, 0.0, 1.0);
    _modelViewMatrix = GLKMatrix4Scale(_modelViewMatrix, 0.30, 0.33, 0.30);
    
    // Normal Matrix
    // Transform object-space normals into eye-space
    _normalMatrix = GLKMatrix3Identity;
    bool isInvertible;
    GLKMatrix4 normalFull = GLKMatrix4InvertAndTranspose(_modelViewMatrix, &isInvertible);
    
    GLKMatrix3 normalTemp =
    {
        normalTemp.m00 = normalFull.m00, normalTemp.m01 = normalFull.m01, normalTemp.m02 = normalFull.m02,
        normalTemp.m10 = normalFull.m10, normalTemp.m11 = normalFull.m11, normalTemp.m12 = normalFull.m12,
        normalTemp.m20 = normalFull.m20, normalTemp.m21 = normalFull.m21, normalTemp.m22 = normalFull.m22
    };
    
    _normalMatrix = normalTemp;
}

# pragma mark - GLKView Delegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Clear Buffers
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Set View Matrices
    [self updateViewMatrices];
    glUniformMatrix4fv(_uniforms.uProjectionMatrix, 1, 0, _projectionMatrix.m);
    glUniformMatrix4fv(_uniforms.uModelViewMatrix, 1, 0, _modelViewMatrix.m);
    glUniformMatrix3fv(_uniforms.uNormalMatrix, 1, 0, _normalMatrix.m);
    
    // Attach Texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(_uniforms.uTexture, 0);
    
    // Set View Mode
    glUniform1i(_uniforms.uMode, self.viewMode.selectedSegmentIndex);
    
    // Enable Attributes
    glEnableVertexAttribArray(_attributes.aVertex);
    glEnableVertexAttribArray(_attributes.aNormal);
    glEnableVertexAttribArray(_attributes.aTexture);
    
    // Load OBJ Data
    glVertexAttribPointer(_attributes.aVertex, 3, GL_FLOAT, GL_FALSE, 0, cubeOBJVerts);
    glVertexAttribPointer(_attributes.aNormal, 3, GL_FLOAT, GL_FALSE, 0, cubeOBJNormals);
    glVertexAttribPointer(_attributes.aTexture, 2, GL_FLOAT, GL_FALSE, 0, cubeOBJTexCoords);
    
    // Load MTL Data
    for(int i=0; i<cubeMTLNumMaterials; i++)
    {
        glUniform3f(_uniforms.uAmbient, cubeMTLAmbient[i][0], cubeMTLAmbient[i][1], cubeMTLAmbient[i][2]);
        glUniform3f(_uniforms.uDiffuse, cubeMTLDiffuse[i][0], cubeMTLDiffuse[i][1], cubeMTLDiffuse[i][2]);
        glUniform3f(_uniforms.uSpecular, cubeMTLSpecular[i][0], cubeMTLSpecular[i][1], cubeMTLSpecular[i][2]);
        glUniform1f(_uniforms.uExponent, cubeMTLExponent[i]);
        
        // Draw scene by material group
        glDrawArrays(GL_TRIANGLES, cubeMTLFirst[i], cubeMTLCount[i]);
    }
    
    // Disable Attributes
    glDisableVertexAttribArray(_attributes.aVertex);
    glDisableVertexAttribArray(_attributes.aNormal);
    glDisableVertexAttribArray(_attributes.aTexture);
}

# pragma mark - GLKViewController Delegate

- (void)glkViewControllerUpdate:(GLKViewController *)controller
{
}

@end
