<?
//	This file is part of OpenLoft.
//
//	OpenLoft is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	OpenLoft is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with OpenLoft.  If not, see <http://www.gnu.org/licenses/>.
//
//	Authors: Falados Kapuskas
require_once('include/openloft_config.inc.php');
require_once('include/gdbundle.inc.php');
require_once('include/vertex.class.inc.php');

defined('OL_INCLUDE') || die("Can't access this page directly");

function fill_pie(&$image,$center,$prev,$curr,$width,$height,&$color)
{
	$redcolor =  imagecolorallocate($image,255,0,0);
	imagefilledpolygon ( $image , array(
		intval(($center->x+1.0)/2.0*$width),	intval((1-($center->y+1.0)/2.0)*$height),
		intval(($prev->x+1.0)/2.0*$width),	intval((1-($prev->y+1.0)/2.0)*$height),
		intval(($curr->x+1.0)/2.0*$width),	intval((1-($curr->y+1.0)/2.0)*$height)
	) , 3 , $color );
	imageline 
	(
		$image,
		intval(($prev->x+1.0)/2.0*$width),	intval((1-($prev->y+1.0)/2.0)*$height),
		intval(($curr->x+1.0)/2.0*$width),	intval((1-($curr->y+1.0)/2.0)*$height),
		$redcolor
	);
}

function make_slice($row,$verts,$width,$height) {
	$center = new vertex(0,0,0);

	$image = imagecreatetruecolor($width,$height);

	if(isset($_REQUEST['usealpha']))
	{
		$trans_color = imagecolorallocatealpha ( $image , 255 ,255 ,255 ,0 );
		imagefill ($image,0,0,$trans_color);
	}

	$verticies = explode("\n",$verts);
	
	$start = new vertex(0,0,0);
	$start->parse_llvector($verticies[0]);

	$count = count($verticies);
	$x = 0.0;
	$t = 0.0;

	$start_color = new vertex(0,128,0);
	$end_color = new vertex(255,255,255);
	
	$previous = $start;
	
	foreach( $verticies as $point ) //Get Center
	{
		$current = new vertex(0,0,0);
		$current->parse_llvector($point);
		$center->add( $current );
		++$x;
	}
	$center->mult(1.0/$x);
	$x = 0;

	imagesetthickness ( $image , 2 );
	foreach( $verticies as $point ) //Columns
	{
		$t = $x / $count;

		$current = new vertex(0,0,0);
		$current->parse_llvector($point);

		if($verticies[0] != $point)
		{
		
			$vcolor = $start_color->get_interp($end_color,$t);
			$color = $vcolor->allocate_color($image);
			fill_pie($image,$center,$previous,$current,$width,$height,$color);
		}

		$previous = $current;
		++$x;
	}
	$color = imagecolorallocate($image,$end_color->x,$end_color->y,$end_color->z);
	fill_pie($image,$center,$previous,$start,$width,$height,$color);

	$x = 0;
	foreach( $verticies as $point ) //Draw Vertex Points
	{
		++$x;
		$t = $x / $count;

		$current = new vertex(0,0,0);
		$current->parse_llvector($point);
		$current->x = ($current->x+1)*0.5;
		$current->y = 1.0 - ($current->y+1)*0.5;
		$current->x *= $width;
		$current->y *= $height;

		$color = $color = imagecolorallocate($image,255*$t,0,255*(1-$t));

		imagefilledellipse($image,
			intval($current->x),intval($current->y),
			8,8,
		$color);

	}
	return $image;
}

function upload_slice($slice_dir,$image_id)
{
	//Convinence Variables
	$issplit = FALSE;
	if(isset($_REQUEST['split']))
	{
		$issplit = TRUE;
		$s = explode("of",stripslashes($_REQUEST['split']));
		$start = $s[0];
		$end = $s[1];
	}

	$verts = stripslashes($_REQUEST['verts']);
	$row = stripslashes($_REQUEST['row']);
	$params = stripslashes($_REQUEST['params']);

	//Parse Verticies
	$nverts = preg_replace("/> *, *</",">\n<",$verts);
	//Write vertex packet splits to a split file
	//Populate the verticies on the row when all splits are received
	if($issplit) {

		$fd = fopen("$slice_dir/$image_id-$row.split","a+");
		$fd || die("Could not open file: " . "$slice_dir/$image_id-$row.split");
		fwrite($fd,$nverts);
		if($start == $end) {
			$nverts = fread($fd, filesize("$slice_dir/$image_id-$row.split"));
			fclose($fd);
			$fd = FALSE;
			unlink("$slice_dir/$image_id-$row.split");
		} else {
			$nverts = FALSE;
		}
		if($fd) fclose($fd);
	}
	
	$row_filename = "$slice_dir/$image_id.slice$row";

	//Write vertex dump to file
	if( $nverts ) {
		$fd = fopen($row_filename,"w");
		$fd || die("Could not open file: $row_filename");
		fwrite($fd,"$nverts");
		fclose($fd);
	}
}

function render_slice($slice_dir,$image_id,$row)
{
	$input = array();
	$row_filename = "$slice_dir/$image_id.slice$row";
	if( $input = file_get_contents($row_filename) ) {
		//Do Nothing	
	} else {
		die("Couldn't open file $row_filename");
	}
	$imagename = "$slice_dir/${image_id}_slice$row.png";
	$image = make_slice($row,$input,512,512);
	if(imagepng($image,$imagename))
	{
		return fullpath($imagename);
	}
	return false;
}
?>