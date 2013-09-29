#! /usr/bin/perl
=head1 NAME

 mtl2opengl - converts obj and mtl files to arrays for use with OpenGL ES
 
=head1 SYNOPSIS

 mtl2opengl [options] file

 use -help or -man for further information

=head1 DESCRIPTION

This script expects:
An OBJ file consisting of vertices (v), texture coords (vt) and normals (vn). The 
corresponding MTL file consisting of ambient (Ka), diffuse (Kd), specular (Ks), and 
exponent (Ns) components.

The resulting .H files offer three float arrays for the OBJ geometry data and
four float arrays for the MTL material data to be rendered.

=head1 AUTHOR

Ricardo Rendon Cepeda <http://www.rendoncepeda.com/>

=head1 VERSION

28 September 2013 (1.3)

=head1 VERSION HISTORY

Version 1.3
-----------
- Removed whitespace as suggested by @GuntisTreulands, resulting in a smaller header file.
- The example Xcode project has been updated to include the script changes.
- The example Xcode project has been updated to iOS 7.
- The example Xcode project has better OpenGL ES performance for iPhone 4 due to decreased depth format and no multisample (now runs at 30 FPS)
- The example Xcode project now uses gesture recognizers to transform the model: translate XY (1-finger pan), rotate XY (2-finger pan), rotate Z (rotation), scale XYZ (pinch).
- Resulting file reductions
-- cubeOBJ.h: 5.5 MB -> 4.6 MB
-- cubeMTL.h: 2.0 KB -> 1.0 KB
-- Total reduction is approximately 16%

Version 1.2
-----------
- Reduced precision of outputs to 3 decimal places, resulting in a smaller header file.
- Removed the "face line" comment occuring every 3 vertices, resulting in a smaller header file.
- Vertices are written to the header file in sequential order, according to their associated material.
- Materials are grouped to their appropriate vertices by keeping track of *first* and *count* integers for use with glDrawArrays(GL_TRIANGLES, *first*, *count*).
- The new format mimics the the OBJ/MTL behavior where each face in the OBJ file points to a material in the MTL file.
- The example Xcode project has been updated to include the script changes.
- Resulting file reductions
-- cubeOBJ.h: 17.0 MB -> 5.5 MB
-- cubeMTL.h: 13.2 MB -> 2.0 KB
-- Total reduction is approximately 82%

Version 1.1
-----------
Original

=head1 COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 ACKNOWLEDGEMENTS

This script is based on the work of:

Heiko Behrens <http://heikobehrens.net/2009/08/27/obj2opengl/>

Margaret Geroch <http://people.sc.fsu.edu/~jburkardt/pl_src/obj2opengl/obj2opengl.html>

=head1 REQUIRED ARGUMENTS

The first (1) argument must be an OBJ file. 
The second (2) argument must be the corresponding MTL file.

=head1 OPTIONS

=over

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the extended manual page and exits.

=item B<-noScale>    

Prevents automatic scaling. Otherwise the object will be scaled
such the the longest dimension is 1 unit.

=item B<-scale <float>>

Sets the scale factor explicitly. Please be aware that negative numbers
are not handled correctly regarding the orientation of the normals.

=item B<-noMove>

Prevents automatic scaling. Otherwise the object will be moved to the center of
its vertices.

=item B<-noverbose>

Runs this script silently.
   
=cut

use Getopt::Long;
use File::Basename;
use Pod::Usage;

# -----------------------------------------------------------------
# Main Program
# -----------------------------------------------------------------
handleArguments();

# derive center coords and scale factor if neither provided nor disabled
unless(defined($scalefac) && defined($xcen)) 
{
	calcSizeAndCenter();
}

if($verbose) 
{
	printInputAndOptions();
}

loadDataMTL();
loadDataOBJ();
normalizeNormals();

if($verbose) 
{
	printStatistics();
}

writeOutputOBJ();
writeOutputMTL();

# -----------------------------------------------------------------
# Sub Routines
# -----------------------------------------------------------------

sub handleArguments() 
{
	my $help = 0;
	my $man = 0;
	my $noscale = 0;
	my $nomove = 0;
	$verbose = 1;
	$errorInOptions = !GetOptions 
	(
		"help" => \$help,
		"man"  => \$man,
		"noScale" => \$noscale,
		"scale=f" => \$scalefac,
		"noMove" => \$nomove,
		"center=f{3}" => \@center,
		"verbose!" => \$verbose,
	);
	
	if($noscale) 
	{
		$scalefac = 1;
	}
	elsif($scalefac < 0)
	{
		$errorInOptions = true;
	}
	
	if($nomove) 
	{
		@center = (0, 0, 0);
	}
	
	if(defined(@center)) 
	{
		$xcen = $center[0];
		$ycen = $center[1];
		$zcen = $center[2];
	}
	
	my $argvSize = @ARGV;
	
	if($argvSize > 1) 
	{
		my ($fileOBJ, $dirOBJ, $extOBJ) = fileparse($ARGV[0], qr/\.[^.]*/);
		$inFilenameOBJ = $dirOBJ . $fileOBJ . $extOBJ;
		
		my ($fileMTL, $dirMTL, $extMTL) = fileparse($ARGV[1], qr/\.[^.]*/);
		$inFilenameMTL = $dirMTL . $fileMTL . $extMTL;
	} 
	else 
	{
		$errorInOptions = true;
	}

	# derive output filenames from input filenames
	unless($errorInOptions) 
	{
		my ($fileOBJ, $dirOBJ, $extOBJ) = fileparse($inFilenameOBJ, qr/\.[^.]*/);
		$outFilenameOBJ = $dirOBJ . $fileOBJ . "OBJ.h";
		
		my ($fileMTL, $dirMTL, $extMTL) = fileparse($inFilenameMTL, qr/\.[^.]*/);
		$outFilenameMTL = $dirMTL . $fileMTL . "MTL.h";
	}
	
	# derive object names from input filenames
	unless($errorInOptions) 
	{
		my ($fileOBJ, $dirOBJ, $extOBJ) = fileparse($inFilenameOBJ, qr/\.[^.]*/);
	  	$objectOBJ = $fileOBJ . "OBJ";
	  	
	  	my ($fileMTL, $dirMTL, $extMTL) = fileparse($inFilenameMTL, qr/\.[^.]*/);
	  	$objectMTL = $fileMTL . "MTL";
	}
		
	if($errorInOptions || $man || $help) 
	{
		pod2usage(-verbose => 2) if $man;
		pod2usage(-verbose => 1) if $help;
		pod2usage(); 
	}
	
	# check whether files exist
	open ( INFILEOBJ, "<$inFilenameOBJ" ) 
	  || die "Can't find file '$inFilenameOBJ' ...exiting \n";
	close(INFILEOBJ);
	open ( INFILEMTL, "<$inFilenameMTL" ) 
	  || die "Can't find file '$inFilenameMTL' ...exiting \n";
	close(INFILEMTL);
}

# Stores center of object in $xcen, $ycen, $zcen
# and calculates scaling factor $scalefac to limit max
# side of object to 1.0 units
sub calcSizeAndCenter() 
{
	open ( INFILEOBJ, "<$inFilenameOBJ" ) 
	  || die "Can't find file '$inFilenameOBJ' ...exiting \n";

	$numVerts = 0;
	
	my 
	(
		$xsum, $ysum, $zsum, 
		$xmin, $ymin, $zmin,
		$xmax, $ymax, $zmax,
	);

	while ( $line = <INFILEOBJ> ) 
	{
	  	chop $line;
	  
	  	if ($line =~ /v\s+.*/)
	  	{
	  
			$numVerts++;
	    	@tokens = split(' ', $line);
	    
	    	$xsum += $tokens[1];
	    	$ysum += $tokens[2];
	    	$zsum += $tokens[3];
	    
	    	if ( $numVerts == 1 )
	    	{
	      		$xmin = $tokens[1];
	     	 	$xmax = $tokens[1];
	      		$ymin = $tokens[2];
	      		$ymax = $tokens[2];
	      		$zmin = $tokens[3];
	      		$zmax = $tokens[3];
	    	}
	    	else
	    	{   
	    		if ($tokens[1] < $xmin)
	      		{
	        		$xmin = $tokens[1];
	      		}
	      		elsif ($tokens[1] > $xmax)
	      		{
	        		$xmax = $tokens[1];
	      		}
	    
	      		if ($tokens[2] < $ymin) 
	      		{
	        		$ymin = $tokens[2];
	      		}
	      		elsif ($tokens[2] > $ymax) 
	      		{
	       			$ymax = $tokens[2];
	      		}
	    
	      		if ($tokens[3] < $zmin) 
	      		{
	        		$zmin = $tokens[3];
	      		}
	      		elsif ($tokens[3] > $zmax) 
	      		{
	        		$zmax = $tokens[3];
	      		}
	    	}
	  	}
	}
	close INFILEOBJ;
	
	#  Calculate the center
	unless(defined($xcen)) 
	{
		$xcen = $xsum / $numVerts;
		$ycen = $ysum / $numVerts;
		$zcen = $zsum / $numVerts;
	}
	
	#  Calculate the scale factor
	unless(defined($scalefac)) 
	{
		my $xdiff = ($xmax - $xmin);
		my $ydiff = ($ymax - $ymin);
		my $zdiff = ($zmax - $zmin);
		
		if ( ( $xdiff >= $ydiff ) && ( $xdiff >= $zdiff ) ) 
		{
		  $scalefac = $xdiff;
		}
		elsif ( ( $ydiff >= $xdiff ) && ( $ydiff >= $zdiff ) ) 
		{
		  $scalefac = $ydiff;
		}
		else 
		{
		  $scalefac = $zdiff;
		}
		
		$scalefac = 1.0 / $scalefac;
	}
}

sub printInputAndOptions() 
{
	print "Input files: '$inFilenameOBJ', '$inFilenameMTL'\n";
	print "Output files: '$outFilenameOBJ', '$outFilenameMTL'\n";
	print "Object names: '$objectOBJ', '$objectMTL'\n";
	print "Center: <$xcen, $ycen, $zcen>\n";
	print "Scale by: $scalefac\n";
}

sub printStatistics() 
{
	print "----------------\n";
	print "Vertices: $numVerts\n";
	print "Faces: $numFaces\n";
	print "Texture Coords: $numTexture\n";
	print "Normals: $numNormals\n";
	print "Materials: $numMaterials\n";
}


#Reads MTL components for ambient (Ka), diffuse (Kd),
#specular (Ks), and exponent (Ns) values.
#Structure: 
#$mValues[n][0..2] = Ka
#$mValues[n][3..5] = Kd
#$mValues[n][6..8] = Ks
#$mValues[n][9] = Ns
sub loadDataMTL
{	
	# MTL data
	$numMaterials = -1;
	
	open ( INFILEMTL, "<$inFilenameMTL" )
	  || die "Can't find file '$inFilenameMTL' ...exiting \n";
	  
	while ($line = <INFILEMTL>) 
	{
	  	chop $line;
	  	
	  	# materials
	  	if ($line =~ /newmtl\s+.*/)
	  	{
	    	$numMaterials++;
	    	
	    	# initialize material array
	    	for($i = 0; $i < 9; $i++)
	    	{
	    		$mValues[$numMaterials]->[$i] = 0.0;
	    	}
	    	$mValues[$numMaterials]->[9] = 1.0;
	    	
	    	@tokens= split(' ', $line);
	    	$mNames[$numMaterials] = $tokens[1];
	  	}
	  	
	  	# ambient
	  	if ($line =~ /Ka\s+.*/)
	  	{	
	    	@tokens= split(' ', $line);
	    	$mValues[$numMaterials]->[0] = sprintf "%.3f", $tokens[1];
	    	$mValues[$numMaterials]->[1] = sprintf "%.3f", $tokens[2];
	    	$mValues[$numMaterials]->[2] = sprintf "%.3f", $tokens[3];
	  	}
	  	
	  	# diffuse
	  	if ($line =~ /Kd\s+.*/)
	  	{	
	    	@tokens= split(' ', $line);
	    	$mValues[$numMaterials]->[3] = sprintf "%.3f", $tokens[1];
	    	$mValues[$numMaterials]->[4] = sprintf "%.3f", $tokens[2];
	    	$mValues[$numMaterials]->[5] = sprintf "%.3f", $tokens[3];
	  	}
	  	
	  	# specular
	  	if ($line =~ /Ks\s+.*/)
	  	{	
	    	@tokens= split(' ', $line);
	    	$mValues[$numMaterials]->[6] = sprintf "%.3f", $tokens[1];
	    	$mValues[$numMaterials]->[7] = sprintf "%.3f", $tokens[2];
	    	$mValues[$numMaterials]->[8] = sprintf "%.3f", $tokens[3];
	  	} 
	  	
	  	# exponent
	  	if ($line =~ /Ns\s+.*/)
	  	{	
	    	@tokens= split(' ', $line);
	    	$mValues[$numMaterials]->[9] = sprintf "%.3f", $tokens[1];
	  	}   
	}
	close INFILEMTL;
	$numMaterials++;
}

# reads vertices into $xcoords[], $ycoords[], $zcoords[]
#   where coordinates are moved and scaled according to
#   $xcen, $ycen, $zcen and $scalefac
# reads texture coords into $tx[], $ty[] 
#   where y coordinate is mirrowed
# reads normals into $nx[], $ny[], $nz[]
#   but does not normalize, see normalizeNormals()
# reads faces and establishes lookup data where
#   va_idx[], vb_idx[], vc_idx[] for vertices
#   ta_idx[], tb_idx[], tc_idx[] for texture coords
#   na_idx[], nb_idx[], nc_idx[] for normals
#   store indizes for the former arrays respectively
#   also, $face_line[] store actual face string
sub loadDataOBJ 
{
	# OBJ data
	$numVerts = 0;
	$numFaces = 0;
	$numTexture = 0;
	$numNormals = 0;
	
	# MTL data
	$mtl = 0;
	
	open ( INFILEOBJ, "<$inFilenameOBJ" )
	  || die "Can't find file '$inFilenameOBJ' ...exiting \n";
	
	while ($line = <INFILEOBJ>) 
	{
	  	chop $line;
	  
	  	# vertices
	  	if ($line =~ /v\s+.*/)
	  	{
	    	@tokens= split(' ', $line);
	    	$x = ( $tokens[1] - $xcen ) * $scalefac;
	    	$y = ( $tokens[2] - $ycen ) * $scalefac;
	    	$z = ( $tokens[3] - $zcen ) * $scalefac;    
	    	$xcoords[$numVerts] = sprintf "%.3f", $x; 
	    	$ycoords[$numVerts] = sprintf "%.3f", $y;
	    	$zcoords[$numVerts] = sprintf "%.3f", $z;
	
	    	$numVerts++;
	  	}
	  
	  	# texture coords
	  	if ($line =~ /vt\s+.*/)
	  	{
	    	@tokens= split(' ', $line);
	    	$x = $tokens[1];
	    	$y = 1 - $tokens[2];
	    	$tx[$numTexture] = sprintf "%.3f", $x;
	    	$ty[$numTexture] = sprintf "%.3f", $y;
	    
	    	$numTexture++;
	  	}
	  
	  	# normals
	  	if ($line =~ /vn\s+.*/)
	  	{
	    	@tokens= split(' ', $line);
	    	$x = $tokens[1];
	    	$y = $tokens[2];
	    	$z = $tokens[3];
	    	$nx[$numNormals] = sprintf "%.3f", $x; 
	    	$ny[$numNormals] = sprintf "%.3f", $y;
	    	$nz[$numNormals] = sprintf "%.3f", $z;
		
	    	$numNormals++;
	  	}
	  
	  	# faces
	  	if ($line =~ /f\s+([^ ]+)\s+([^ ]+)\s+([^ ]+)(\s+([^ ]+))?/) 
	  	{
	  		@a = split('/', $1);
	  		@b = split('/', $2);
	  		@c = split('/', $3);
	  		$va_idx[$numFaces] = $a[0]-1;
	  		$ta_idx[$numFaces] = $a[1]-1;
	  		$na_idx[$numFaces] = $a[2]-1;
	
	  		$vb_idx[$numFaces] = $b[0]-1;
	  		$tb_idx[$numFaces] = $b[1]-1;
	  		$nb_idx[$numFaces] = $b[2]-1;
	
	  		$vc_idx[$numFaces] = $c[0]-1;
	  		$tc_idx[$numFaces] = $c[1]-1;
	  		$nc_idx[$numFaces] = $c[2]-1;
	  	
	  		$face_line[$numFaces] = $line;
	  		$face_mtl[$numFaces] = $mNames[$mtl];
	  	
			$numFaces++;
		
			# rectangle => second triangle
			if($5 != "")
			{
				@d = split('/', $5);
				$va_idx[$numFaces] = $a[0]-1;
				$ta_idx[$numFaces] = $a[1]-1;
				$na_idx[$numFaces] = $a[2]-1;

				$vb_idx[$numFaces] = $d[0]-1;
				$tb_idx[$numFaces] = $d[1]-1;
				$nb_idx[$numFaces] = $d[2]-1;

				$vc_idx[$numFaces] = $c[0]-1;
				$tc_idx[$numFaces] = $c[1]-1;
				$nc_idx[$numFaces] = $c[2]-1;

				$face_line[$numFaces] = $line;
				$face_mtl[$numFaces] = $mNames[$mtl];

				$numFaces++;
			}
	  	}
	  	
	  	# materials
	  	if ($line =~ /usemtl\s+.*/)
	  	{
	    	@tokens= split(' ', $line);

	    	$i = 0;
	    	foreach(@mNames)
	    	{
	    		if($tokens[1] eq $mNames[$i])
	    		{
	    			$mtl = $i;
	    		}
	    		
	    		$i++;
	    	}
	  	}  
	}
	close INFILEOBJ;
}

sub normalizeNormals 
{
	for ( $j = 0; $j < $numNormals; ++$j) 
	{
	 	$d = sqrt ( $nx[$j]*$nx[$j] + $ny[$j]*$ny[$j] + $nz[$j]*$nz[$j] );
	  
	  	if ( $d == 0 )
	  	{
	    	$nx[$j] = 1;
	    	$ny[$j] = 0;
	    	$nz[$j] = 0;
	  	}
	  	else
	  	{
	    	$nx[$j] = sprintf "%.3f", ($nx[$j] / $d);
	    	$ny[$j] = sprintf "%.3f", ($ny[$j] / $d);
	    	$nz[$j] = sprintf "%.3f", ($nz[$j] / $d);
	  	}  
	}
}

sub writeOutputOBJ 
{	
	open ( OUTFILEOBJ, ">$outFilenameOBJ" ) 
	  || die "Can't create file '$outFilenameOBJ' ... exiting\n";
	
	print OUTFILEOBJ "// Created with mtl2opengl.pl\n\n";

	# some statistics
	print OUTFILEOBJ "/*\n";
	print OUTFILEOBJ "source files: $inFilenameOBJ, $inFilenameMTL\n";
	print OUTFILEOBJ "vertices: $numVerts\n";
	print OUTFILEOBJ "faces: $numFaces\n";
	print OUTFILEOBJ "normals: $numNormals\n";
	print OUTFILEOBJ "texture coords: $numTexture\n";
	print OUTFILEOBJ "*/\n";
	print OUTFILEOBJ "\n\n";
	
	# needed constant for glDrawArrays
	print OUTFILEOBJ "unsigned int ".$objectOBJ."NumVerts = ".($numFaces * 3).";\n\n";
	
	# write verts
	print OUTFILEOBJ "float ".$objectOBJ."Verts \[\] = {\n"; 
	for($i = 0; $i < $numMaterials; $i++) 
	{
		$mCount[$i] = 0;
		
		for( $j = 0; $j < $numFaces; $j++)
		{
			if($face_mtl[$j] eq $mNames[$i])
			{
				$ia = $va_idx[$j];
				$ib = $vb_idx[$j];
				$ic = $vc_idx[$j];
				print OUTFILEOBJ "$xcoords[$ia],$ycoords[$ia],$zcoords[$ia],\n";
				print OUTFILEOBJ "$xcoords[$ib],$ycoords[$ib],$zcoords[$ib],\n";
				print OUTFILEOBJ "$xcoords[$ic],$ycoords[$ic],$zcoords[$ic],\n";
				
				$mCount[$i] += 3;
			}
		}
	}
	print OUTFILEOBJ "};\n\n";
	
	# write normals
	if($numNormals > 0) 
	{
		print OUTFILEOBJ "float ".$objectOBJ."Normals \[\] = {\n"; 
		for($i = 0; $i < $numMaterials; $i++) 
		{
			for( $j = 0; $j < $numFaces; $j++)
			{
				if($face_mtl[$j] eq $mNames[$i])
				{
					$ia = $na_idx[$j];
					$ib = $nb_idx[$j];
					$ic = $nc_idx[$j];
					print OUTFILEOBJ "$nx[$ia],$ny[$ia],$nz[$ia],\n";
					print OUTFILEOBJ "$nx[$ib],$ny[$ib],$nz[$ib],\n";
					print OUTFILEOBJ "$nx[$ic],$ny[$ic],$nz[$ic],\n";
				}
			}
		}
		print OUTFILEOBJ "};\n\n";
	}
	
	# write texture coords
	if($numTexture) 
	{
		print OUTFILEOBJ "float ".$objectOBJ."TexCoords \[\] = {\n"; 
		for($i = 0; $i < $numMaterials; $i++) 
		{
			for( $j = 0; $j < $numFaces; $j++) 
			{
				if($face_mtl[$j] eq $mNames[$i])
				{
					$ia = $ta_idx[$j];
					$ib = $tb_idx[$j];
					$ic = $tc_idx[$j];
					print OUTFILEOBJ "$tx[$ia],$ty[$ia],\n";
					print OUTFILEOBJ "$tx[$ib],$ty[$ib],\n";
					print OUTFILEOBJ "$tx[$ic],$ty[$ic],\n";
				}
			}
		}
		print OUTFILEOBJ "};\n\n";
	}
	
	close OUTFILEOBJ;
}

sub writeOutputMTL 
{
	open ( OUTFILEMTL, ">$outFilenameMTL" ) 
	  || die "Can't create file '$outFilenameMTL' ... exiting\n";
	
	print OUTFILEMTL "// Created with mtl2opengl.pl\n\n";

	# some statistics
	print OUTFILEMTL "/*\n";
	print OUTFILEMTL "source files: $inFilenameOBJ, $inFilenameMTL\n";
	print OUTFILEMTL "materials: $numMaterials\n\n";
	for($i = 0; $i < $numMaterials; $i++) 
	{
		$kaR = $mValues[$i]->[0];
		$kaG = $mValues[$i]->[1];
		$kaB = $mValues[$i]->[2];
		$kdR = $mValues[$i]->[3];
		$kdG = $mValues[$i]->[4];
		$kdB = $mValues[$i]->[5];
		$ksR = $mValues[$i]->[6];
		$ksG = $mValues[$i]->[7];
		$ksB = $mValues[$i]->[8];
		$nsE = $mValues[$i]->[9];
		
		print OUTFILEMTL "Name: $mNames[$i]\n";
		print OUTFILEMTL "Ka: $kaR, $kaG, $kaB\n";
		print OUTFILEMTL "Kd: $kdR, $kdG, $kdB\n";
		print OUTFILEMTL "Ks: $ksR, $ksG, $ksB\n";
		print OUTFILEMTL "Ns: $nsE\n\n";
	}
	print OUTFILEMTL "*/\n";
	print OUTFILEMTL "\n\n";
	
	# needed constant for glDrawArrays
	print OUTFILEMTL "int ".$objectMTL."NumMaterials = ".$numMaterials.";\n\n";
	
	# write firsts
	print OUTFILEMTL "int ".$objectMTL."First [$numMaterials] = {\n";
	for($i = 0; $i < $numMaterials; $i++)
	{
		if($i == 0)
		{
			$first = 0;
		}
		else
		{
			$first += $mCount[$i-1];
		}
		
		print OUTFILEMTL "$first,\n";
	}
	print OUTFILEMTL "};\n\n";
	
	# write counts
	print OUTFILEMTL "int ".$objectMTL."Count [$numMaterials] = {\n";
	for($i = 0; $i < $numMaterials; $i++)
	{
		$count = $mCount[$i];
		
		print OUTFILEMTL "$count,\n";
	}
	print OUTFILEMTL "};\n\n";
	
	# write ambients
	print OUTFILEMTL "float ".$objectMTL."Ambient [$numMaterials][3] = {\n";
	for($i = 0; $i < $numMaterials; $i++)
	{
		$kaR = $mValues[$i]->[0];
		$kaG = $mValues[$i]->[1];
		$kaB = $mValues[$i]->[2];
		
		print OUTFILEMTL "$kaR,$kaG,$kaB,\n";
	}
	print OUTFILEMTL "};\n\n";
	
	# write diffuses
	print OUTFILEMTL "float ".$objectMTL."Diffuse [$numMaterials][3] = {\n";
	for($i = 0; $i < $numMaterials; $i++)
	{
		$kdR = $mValues[$i]->[3];
		$kdG = $mValues[$i]->[4];
		$kdB = $mValues[$i]->[5];
		
		print OUTFILEMTL "$kdR,$kdG,$kdB,\n";
	}
	print OUTFILEMTL "};\n\n";
	
	# write speculars
	print OUTFILEMTL "float ".$objectMTL."Specular [$numMaterials][3] = {\n";
	for($i = 0; $i < $numMaterials; $i++)
	{
		$ksR = $mValues[$i]->[6];
		$ksG = $mValues[$i]->[7];
		$ksB = $mValues[$i]->[8];
		
		print OUTFILEMTL "$ksR,$ksG,$ksB,\n";
	}
	print OUTFILEMTL "};\n\n";
	
	# write exponents
	print OUTFILEMTL "float ".$objectMTL."Exponent [$numMaterials] = {\n";
	for($i = 0; $i < $numMaterials; $i++)
	{
		$nsE = $mValues[$i]->[9];
		
		print OUTFILEMTL "$nsE,\n";
	}
	print OUTFILEMTL "};\n\n";
	    	
	close OUTFILEMTL;
}
