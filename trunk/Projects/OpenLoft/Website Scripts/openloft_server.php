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
define('OL_INCLUDE','1');

require_once('include/openloft_config.inc.php');
require_once('include/vertex2sculpt.inc.php');
require_once('include/vertex2slice.inc.php');

if(!isset($_REQUEST['action'])) exit;
$action = $_REQUEST['action'];
$image_id = $_REQUEST['image'];

if($is_ll)
{
	if( !file_exists($ll_owner_key) ) mkdir($ll_owner_key);
	$subdirs = array
	(
		"$ll_owner_key/slices",
		"$ll_owner_key/uploads",
		"$ll_owner_key/rendered"
	);
	foreach($subdirs as $subdir)
	{
		if(!file_exists($subdir)) mkdir($subdir);
	}
}
/*
$num = 0;
$original_id = $image_id;
while(file_exists("$ll_owner_key/rendered/$image_id"))
{
	++$num;
	$image_id = "$original_id_$num";
}
*/
switch($action)
{
	case "upload-slice":
		if(!file_exists("$ll_owner_key/slices/$image_id")) mkdir("$ll_owner_key/slices/$image_id");
		upload_slice("$ll_owner_key/slices/$image_id",$image_id);
		break;
	case "upload-render":
		if(!file_exists("$ll_owner_key/uploads/$image_id")) mkdir("$ll_owner_key/uploads/$image_id");
		upload_render("$ll_owner_key/uploads/$image_id",$image_id);
		break;
	case "render-sculpt":
		if(!file_exists("$ll_owner_key/rendered/$image_id")) mkdir("$ll_owner_key/rendered/$image_id");
		$path = render("$ll_owner_key/uploads/$image_id","$ll_owner_key/rendered/$image_id",$image_id);
		if($path)
		{
			echo("Your Sculpt Image:\n<$path>");
		} else {
			echo("Could not render sculpt");
		}
		break;
	case "get-slice-image":
		$path = render_slice("$ll_owner_key/slices/$image_id",$image_id,$_REQUEST['row']);
		if($path)
		{
			echo("Your Slice Image:\n<$path>");
		} else {
			echo("Could not make slice image");
		}
		break;
	case "get-slice":
		$row = $_REQUEST['row'];
		$row_filename = "$ll_owner_key/slices/$image_id/$image_id.slice$row";
		if(file_exists($row_filename))
		{
			echo(file_get_contents($row_filename));
		} else {
			echo("Could not get slice : $row_filename");
		}
		break;
}
?>