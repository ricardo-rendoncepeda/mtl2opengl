// FRAGMENT SHADER

static const char* ShaderF = STRINGIFY
(

// Input from Vertex Shader
varying mediump vec3 vNormal;
varying mediump vec2 vTexture;
varying lowp vec3 vAmbient;
varying lowp vec3 vDiffuse;
varying lowp vec3 vSpecular;
varying highp float vShine;
 
uniform lowp int uMode;
uniform lowp vec3 uColor;
uniform sampler2D uTexture;
 
lowp vec3 materialDefault(highp float df, highp float sf)
{
    lowp vec3 ambient = vec3(0.5);
    lowp vec3 diffuse = vec3(0.5);
    lowp vec3 specular = vec3(0.0);
    highp float shine = 1.0;
    
    sf = pow(sf, shine);
    
    return (ambient + (df * diffuse) + (sf * specular));
}
 
lowp vec3 materialMTL(highp float df, highp float sf)
{
    sf = pow(sf, vShine);

    return (vAmbient + (df * vDiffuse) + (sf * vSpecular));
}
 
lowp vec3 modelColor(void)
{
    highp vec3 N = normalize(vNormal);
    highp vec3 L = vec3(1.0, 1.0, 0.5);
    highp vec3 E = vec3(0.0, 0.0, 1.0);
    highp vec3 H = normalize(L + E);
    
    highp float df = max(0.0, dot(N, L));
    highp float sf = max(0.0, dot(N, H));
    
    // Default
    if(uMode == 0)
        return materialDefault(df, sf);
    
    // Texture
    else if(uMode == 1)
        return (materialDefault(df, sf) * vec3(texture2D(uTexture, vTexture)));
    
    // Material
    else if(uMode == 2)
        return materialMTL(df, sf);
}
 
void main(void)
{
    lowp vec3 color = modelColor();
    gl_FragColor = vec4(color, 1.0);
}

);