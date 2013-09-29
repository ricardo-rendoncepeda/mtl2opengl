//
//  ShaderData.h
//  MTL
//
//  Created by Ricardo Rendon Cepeda on 30/10/12.
//  Copyright (c) 2012 Personal. All rights reserved.
//

// Frameworks
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface ShaderProcessor : NSObject

- (GLuint)BuildProgram:(const char*)vertexShaderSource with:(const char*)fragmentShaderSource;

@end
