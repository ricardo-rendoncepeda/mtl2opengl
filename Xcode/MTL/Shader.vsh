// VERTEX SHADER

static const char* ShaderV = STRINGIFY
(

// OBJ Data
attribute vec4 aVertex;
attribute vec3 aNormal;
attribute vec2 aTexture;
 
// MTL Data
attribute vec3 aAmbient;
attribute vec3 aDiffuse;
attribute vec3 aSpecular;
attribute float aShine;
 
// View Matrices
uniform mat4 uProjectionMatrix;
uniform mat4 uModelViewMatrix;
uniform mat3 uNormalMatrix;
 
// Output to Fragment Shader
varying vec3 vNormal;
varying vec2 vTexture;
varying vec3 vAmbient;
varying vec3 vDiffuse;
varying vec3 vSpecular;
varying float vShine;
 
void main(void)
{
    vNormal     = uNormalMatrix * aNormal;
    vTexture    = aTexture;
    vAmbient    = aAmbient;
    vDiffuse    = aDiffuse;
    vSpecular   = aSpecular;
    vShine      = aShine;
    
    gl_Position = uProjectionMatrix * uModelViewMatrix * aVertex;
}
 
);