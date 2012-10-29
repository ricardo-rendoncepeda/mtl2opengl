//
//  ShaderData.m
//  MTL
//
//  Created by Ricardo Rendon Cepeda on 30/10/12.
//  Copyright (c) 2012 Personal. All rights reserved.
//

#import "ShaderProcessor.h"

#include <iostream>

@implementation ShaderProcessor

- (GLuint)BuildProgram:(const char*)vertexShaderSource with:(const char*)fragmentShaderSource
{
    // Build shaders
    GLuint vertexShader = [self BuildShader:vertexShaderSource with:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self BuildShader:fragmentShaderSource with:GL_FRAGMENT_SHADER];
    
    // Create program
    GLuint programHandle = glCreateProgram();
    
    // Attach shaders
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    
    // Link program
    glLinkProgram(programHandle);
    
    // Check for errors
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) 
    {
        NSLog(@"GLSL Program Error");
        GLchar messages[1024];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        std::cout << messages;
        exit(1);
    }
    
    // Delete shaders
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return programHandle;
}

- (GLuint)BuildShader:(const char*)source with:(GLenum)shaderType
{
    // Create the shader object
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // Load the shader source
    glShaderSource(shaderHandle, 1, &source, 0);
    
    // Compile the shader
    glCompileShader(shaderHandle);
    
    // Check for errors
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) 
    {
        NSLog(@"GLSL Shader Error");
        GLchar messages[1024];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        std::cout << messages;
        exit(1);
    }
    
    return shaderHandle;
}

@end
