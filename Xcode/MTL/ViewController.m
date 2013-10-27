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
    self.glkView.backgroundColor = [UIColor whiteColor];
    self.glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
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
    CGRect screen = [[UIScreen mainScreen] bounds];
    float aspectRatio = fabsf(screen.size.width / screen.size.height);
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0), aspectRatio, 0.1, 10.1);
    
    // ModelView Matrix
    _modelViewMatrix = GLKMatrix4Identity;
    
    // Initialize Model Pose
    self.transformations = [[Transformations alloc] initWithDepth:5.0f Scale:1.33f Translation:GLKVector2Make(0.0f, 0.0f) Rotation:GLKVector3Make(0.0f, 0.0f, 0.0f)];
    
    // Load Texture
    [self loadTexture:@"cube.png"];
    
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

- (void)loadTexture:(NSString *)fileName
{
    NSDictionary* options = @{[NSNumber numberWithBool:YES] : GLKTextureLoaderOriginBottomLeft};
    
    NSError* error;
    NSString* path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    GLKTextureInfo* texture = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if(texture == nil)
        NSLog(@"Error loading file: %@", [error localizedDescription]);
    
    glBindTexture(GL_TEXTURE_2D, texture.name);
}

- (void)updateViewMatrices
{
    // ModelView Matrix
    _modelViewMatrix = [self.transformations getModelViewMatrix];
    
    // Normal Matrix
    // Transform object-space normals into eye-space
    _normalMatrix = GLKMatrix3Identity;
    bool isInvertible;
    _normalMatrix = GLKMatrix4GetMatrix3(GLKMatrix4InvertAndTranspose(_modelViewMatrix, &isInvertible));
}

# pragma mark - GLKView Delegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Clear Buffers
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Set View Matrices
    [self updateViewMatrices];
    glUniformMatrix4fv(_uniforms.uProjectionMatrix, 1, 0, _projectionMatrix.m);
    glUniformMatrix4fv(_uniforms.uModelViewMatrix, 1, 0, _modelViewMatrix.m);
    glUniformMatrix3fv(_uniforms.uNormalMatrix, 1, 0, _normalMatrix.m);
    
    // Attach Texture
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

// GESTURES

# pragma mark - Gestures

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Begin transformations
    [self.transformations start];
}

- (IBAction)pan:(UIPanGestureRecognizer *)sender
{
    // Pan (1 Finger)
    if((sender.numberOfTouches == 1) &&
       ((self.transformations.state == S_NEW) || (self.transformations.state == S_TRANSLATION)))
    {
        CGPoint translation = [sender translationInView:sender.view];
        float x = translation.x/sender.view.frame.size.width;
        float y = translation.y/sender.view.frame.size.height;
        [self.transformations translate:GLKVector2Make(x, y) withMultiplier:2.0f];
    }
    
    // Pan (2 Fingers)
    else if((sender.numberOfTouches == 2) &&
            ((self.transformations.state == S_NEW) || (self.transformations.state == S_ROTATION)))
    {
        const float m = GLKMathDegreesToRadians(0.5f);
        CGPoint rotation = [sender translationInView:sender.view];
        [self.transformations rotate:GLKVector3Make(rotation.x, rotation.y, 0.0f) withMultiplier:m];
    }
}

- (IBAction)pinch:(UIPinchGestureRecognizer *)sender
{
    // Pinch
    if((self.transformations.state == S_NEW) || (self.transformations.state == S_SCALE))
    {
        float scale = [sender scale];
        [self.transformations scale:scale];
    }
}

- (IBAction)rotation:(UIRotationGestureRecognizer *)sender
{
    // Rotation
    if((self.transformations.state == S_NEW) || (self.transformations.state == S_ROTATION))
    {
        float rotation = [sender rotation];
        [self.transformations rotate:GLKVector3Make(0.0f, 0.0f, rotation) withMultiplier:1.0f];
    }
}

@end
