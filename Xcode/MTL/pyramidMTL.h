// Created with mtl2opengl.pl

/*
source files: Resources/pyramid.obj, Resources/pyramid.mtl
materials: 4

Name: blinnGSG
Ka: 0.000, 0.100, 0.000
Kd: 0.000, 0.900, 0.000
Ks: 0.400, 0.400, 0.400
Ns: 1

Name: flatSG
Ka: 0.500, 0.500, 0.500
Kd: 0.500, 0.500, 0.500
Ks: 0, 0, 0
Ns: 1

Name: lambertRSG
Ka: 0.100, 0.000, 0.000
Kd: 0.900, 0.000, 0.000
Ks: 0, 0, 0
Ns: 1

Name: phongBSG
Ka: 0.000, 0.000, 0.100
Kd: 0.000, 0.000, 0.900
Ks: 0.600, 0.600, 0.600
Ns: 48.000

*/


int pyramidMTLNumMaterials = 4;

int pyramidMTLFirst [4] = {
0,
3,
6,
9,
};

int pyramidMTLCount [4] = {
3,
3,
3,
3,
};

float pyramidMTLAmbient [4][3] = {
0.000,0.100,0.000,
0.500,0.500,0.500,
0.100,0.000,0.000,
0.000,0.000,0.100,
};

float pyramidMTLDiffuse [4][3] = {
0.000,0.900,0.000,
0.500,0.500,0.500,
0.900,0.000,0.000,
0.000,0.000,0.900,
};

float pyramidMTLSpecular [4][3] = {
0.400,0.400,0.400,
0,0,0,
0,0,0,
0.600,0.600,0.600,
};

float pyramidMTLExponent [4] = {
1,
1,
1,
48.000,
};

