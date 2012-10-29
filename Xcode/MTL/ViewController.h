//
//  ViewController.h
//  MTL
//
//  Created by Ricardo Rendon Cepeda on 30/10/12.
//  Copyright (c) 2012 RRC. All rights reserved.
//

// Frameworks
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

// Models
#import "cubeOBJ.h"
#import "cubeMTL.h"

// Shaders
#import "ShaderProcessor.h"
#define STRINGIFY(A) #A
#include "Shader.vsh"
#include "Shader.fsh"

@interface ViewController : GLKViewController <GLKViewDelegate, GLKViewControllerDelegate>
{
    // Render
    GLuint  _program;
    GLuint  _texture;
    
    // View
    GLKMatrix4  _projectionMatrix;
    GLKMatrix4  _modelViewMatrix;
    GLKMatrix3  _normalMatrix;
}

// Class Objects
@property (strong, nonatomic) ShaderProcessor* shaderProcessor;

// View
@property (strong, nonatomic) EAGLContext* context;
@property (strong, nonatomic) GLKView* glkView;

// UI Controls
@property (weak, nonatomic) IBOutlet UISlider* rotateX;
@property (weak, nonatomic) IBOutlet UISlider* rotateY;
@property (weak, nonatomic) IBOutlet UISlider* rotateZ;
@property (weak, nonatomic) IBOutlet UISegmentedControl* viewMode;


@end
