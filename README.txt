README

mtl2opengl Version 1.1 (31 October 2012)
Copyright © 2012 Ricardo Rendon Cepeda
<http://www.rendoncepeda.com/


ABOUT
mtl2opengl is a perl script for converting .obj and .mtl data files into arrays compatible with OpenGL ES on iOS devices.


INSTRUCTIONS
To run the script with its default settings, type the following into the command line terminal:

./mtl2opengl.pl model.obj model.mtl

where model.obj and model.mtl are the .obj and corresponding .mtl files of your 3D model.


ACCOMPANYING FILES
The full project includes:
-Resources: Example 3D models for a cube and pyramid shape, with .obj, .mtl, .png (texture) files and the resulting .h header files produced by the script.
-Xcode: A full Xcode project showing how to implement the resulting .h files on an iPhone application using GLKit and OpenGL ES 2.0 with Vertex and Fragment shaders.


ACKNOWLEDGEMENTS
This script is based on the work of:
Heiko Behrens <http://heikobehrens.net/2009/08/27/obj2opengl/>
Margaret Geroch <http://people.sc.fsu.edu/~jburkardt/pl_src/obj2opengl/obj2opengl.html>