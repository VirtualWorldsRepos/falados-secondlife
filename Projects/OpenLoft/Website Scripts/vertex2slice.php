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
//	Authors: Falados Kapuskas, JoeTheCatboy Freelunch

require_once('openloft_config.inc.php');

if( defined(ENABLE_AUTH) && !$is_allowed) die('Not Allowed');

//Make the directories if they are missing
if( !file_exists("cache") ) mkdir("cache");
if( !file_exists("slices") ) mkdir("slices");

$row = 0;

function fullpath($file){
	$host  = $_SERVER['HTTP_HOST'];
	$uri  = rtrim($_SERVER['PHP_SELF'], "/\\");
	$uri = str_replace(basename($_SERVER['PHP_SELF']),"",$uri);
	return "http://$host$uri$file";
}


class vertex {
	var $x=0.0;
	var $y=0.0;
	var $z=0.0;
	function load(/*.array.*/ $arr) {
		$this->x = floatval($arr[0]);
		$this->y = floatval($arr[1]);
		$this->z = floatval($arr[2]);
	}
	function mult($scalar=1.0)
	{
		$this->x *=floatval($scalar);
		$this->y *=floatval($scalar);
		$this->z *=floatval($scalar);
	}
	function combine(/*.vertex.*/ $vector)
	{
		$this->x /= $vector->x;
		$this->y /= $vector->y;
		$this->z /= $vector->z;
	}
	function add(/*.vertex.*/ $vertex)
	{
		$this->x += $vertex->x;
		$this->y += $vertex->y;
		$this->z += $vertex->z;
	}
	function get_array() {
		return array($this->x,$this->y,$this->z);
	}
	function toString() {
		return "<$this->x,$this->y,$this->z>";
	}
};

function make_slice($verts,$width,$height) {
	global $owner_key,$object_key;
	global $row;

	$center = new vertex;
	$center->x = 0;
	$center->y = 0;

	$image = imagecreatetruecolor($width,$height);

	if(isset($_REQUEST['usealpha']))
	{
		$trans_color = imagecolorallocatealpha ( $image , 255 ,255 ,255 ,0 );
		imagefill ($image,0,0,$trans_color);
	}

	$verticies = explode("|",$verts);
	
	$start = new vertex;
	$start->load(explode(",",$verticies[0]));

	$count = count($verticies);
	$x = 0.0;
	$t = 0.0;

	$start_color = new vertex;
	$start_color->x = 0;
	$start_color->y = 128;
	$start_color->z = 0;

	$end_color = new vertex;
	$end_color->x = 255;
	$end_color->y = 255;
	$end_color->z = 255;
	
	$previous = $start;

	$redcolor =  imagecolorallocate($image,255,0,0);

	foreach( $verticies as $point ) //Get Center
	{
		$current = new vertex;
		$current->load(explode(",",$point));
		$center->add( $current );
		++$x;
	}
	$center->mult(1.0/$x);
	$x = 0;

	imagesetthickness ( $image , 2 );
	foreach( $verticies as $point ) //Columns
	{
		$t = $x / $count;

		$current = new vertex;
		$current->load(explode(",",$point));

		if($verticies[0] != $point)
		{
			$red = intval($start_color->x * (1.0-$t) + $end_color->x*$t);
			$green = intval($start_color->y * (1.0-$t) + $end_color->y*$t);
			$blue = intval($start_color->z * (1.0-$t) + $end_color->z*$t);

			$color = imagecolorallocate($image,$red,$green,$blue);
			imagefilledpolygon ( $image , array(
				intval(($center->x+1.0)/2.0*$width),	intval((1-($center->y+1.0)/2.0)*$height),
				intval(($previous->x+1.0)/2.0*$width),	intval((1-($previous->y+1.0)/2.0)*$height),
				intval(($current->x+1.0)/2.0*$width),	intval((1-($current->y+1.0)/2.0)*$height)
			) , 3 , $color );
			imageline 
			(
				$image,
				intval(($previous->x+1.0)/2.0*$width),	intval((1-($previous->y+1.0)/2.0)*$height),
				intval(($current->x+1.0)/2.0*$width),	intval((1-($current->y+1.0)/2.0)*$height),
				$redcolor
			);
		}

		$previous = $current;
		++$x;
	}
	$color = imagecolorallocate($image,$end_color->x,$end_color->y,$end_color->z);
	imagefilledpolygon ( $image , array(
		intval(($center->x+1.0)/2.0*$width),	intval((1-($center->y+1.0)/2.0)*$height),
		intval(($previous->x+1.0)/2.0*$width),	intval((1-($previous->y+1.0)/2.0)*$height),
		intval(($start->x+1.0)/2.0*$width),	intval((1-($start->y+1.0)/2.0)*$height)
	) , 3 , $color );
	imageline 
	(
		$image,
		intval(($previous->x+1.0)/2.0*$width),	intval((1-($previous->y+1.0)/2.0)*$height),
		intval(($start->x+1.0)/2.0*$width),	intval((1-($start->y+1.0)/2.0)*$height),
		$redcolor
	);

	$x = 0;
	foreach( $verticies as $point ) //Draw Vertex Points
	{
		++$x;
		$t = $x / $count;

		$current = new vertex;
		$current->load(explode(",",$point));
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

	//Name it after the object and owner key, otherwise the name given during the render command
	$imagename = "$owner_key-$object_key-slice$row.png";
	if(isset($_REQUEST['name'])) $imagename = $_REQUEST['name'];

	imagepng($image,"slices/$imagename");
	imagedestroy($image);
	echo("\nYour Slice: <" . fullpath("slices/$imagename") . ">\n");
}

$action = $_REQUEST['action'];

//Make 'unique' filename
$image_id = $owner_key;

if($action == "upload")
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
	$nverts = preg_replace("/> *, *</","|",$verts);
	$nverts = preg_replace("/[> <]/","",$nverts);

	//Write vertex packet splits to a split file
	//Populate the verticies on the row when all splits are received
	if($issplit) {

		$fd = fopen("cache/$image_id.split","a+");
		$fd || die("Could not open file: " . "$image_id.split$row");
		fwrite($fd,$nverts);
		if($start == $end) {
			$nverts = fread($fd, filesize("$image_id.split$row"));
			fclose($fd);
			$fd = FALSE;
			unlink("cache/$image_id.split");
		} else {
			$nverts = FALSE;
		}
		if($fd) fclose($fd);
	}
	
	$row_filename = "cache/$image_id-$row.slice";

	//Write vertex dump to file
	if( $nverts ) {
		$fd = fopen($row_filename,"w");
		$fd || die("Could not open file: $row_filename");
		fwrite($fd,"$nverts");
		fclose($fd);
	}
}

if( $action == "slice") {
	$input = array();
	$row = stripslashes($_REQUEST['row']);
	$row_filename = "cache/$image_id-$row.slice";
	if( $input = file_get_contents($row_filename) ) {
		unlink($row_filename);
	} else {
		die("Couldn't open file for row $row");
	}
	make_slice($input,512,512);
}
?>
