<?php
//	This file is part of Open Babel Fish.
//
//	Open Babel Fish is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	Open Babel Fish is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with Open Babel Fish.  If not, see <http://www.gnu.org/licenses/>.


//Change to 1 if you want to use lib_curl.  Otherwise change to 0 to use raw sockets
define("USE_CURL",1);

//Set to 1 if you want to save every translation
//This may signicifantly speed up translations if the same word or phrase is said
//over and over again.
define("CACHE_TRANSLATIONS",0);
define("CACHE_DIRECTORY","cache/");

//Log file for translations
define("LOGFILE","log.txt");

//Debug Off=0, Debug On =1
define("DEBUG",0);

//Google Translate: http://translate.google.com/translate_t
define("TRANSLATE_HOST","translate.google.com");
define("TRANSLATE_PATH","/translate_t");
define("LANGUAGE_LIST_FROM","lang-sl.txt");
define("LANGUAGE_LIST_TO","lang-tl.txt");



header("Content-Type: text/plain; charset=" . "UTF-8");

$trans = "translate";
if(CACHE_TRANSLATIONS)
{
	$trans = "cache_translation";
}

if(DEBUG) {
	error_reporting(E_ALL);
	ini_set('display_errors', '1');
}

function logRequest($lang,$input_text,$output_text)
{
	$fd = fopen(LOGFILE,"a");
	fwrite($fd,"$lang: $input_text -> $output_text \n");
	fclose($fd);
}

function cache_translation($text,$from_lang,$to_lang)
{
	//Don't translate auto-detects
	if( $from_lang == "auto" ) return translate($text,$from_lang,$to_lang);

	$key = "$from_lang|$to_lang|" . strtolower(trim($text));
	$file = CACHE_DIRECTORY . sha1($key) . ".txt";
	$linebreak = "\n\n\n";

	if( file_exists($file) )
	{
		$find = explode($linebreak,file_get_contents($file));
		$index = array_search($key,$find);
		if( $index !== FALSE ) {
			return $find[$index+1];
		}
	}
	$trans = translate($text,$from_lang,$to_lang);
	$fd = fopen($file,"a");
	if( $fd !== FALSE ) {
		fwrite($fd,"$key$linebreak" . $trans . "$linebreak");
		fclose($fd);
	}
	return $trans;
}

//Gets the url body
function getPage($opts) {
	$html = "";
	$req = "?";
	foreach($opts as $var => $value) {
		$req .= "$var=".urlencode($value)."&";
	}
	$req = substr($req, 0, -1);
	if( USE_CURL ) {
		$ch = curl_init(TRANSLATE_HOST . TRANSLATE_PATH . $req);
		curl_setopt($ch, CURLOPT_USERAGENT, "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.12) Gecko/20070508 Firefox/1.5.0.12");
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
		curl_setopt($ch, CURLOPT_HEADER, 0);
		curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 1);
		curl_setopt($ch, CURLOPT_AUTOREFERER, 1);
		curl_setopt($ch, CURLOPT_TIMEOUT, 5);
		$html = curl_exec($ch);
		if(curl_errno($ch)) {
			$html = "";
		}
		curl_close ($ch);
	} else { //Raw Sockets
		$fd = fsockopen(TRANSLATE_HOST,80);
		fputs($fd,"GET " . TRANSLATE_PATH .  "$req HTTP/1.1\r\n");
		fputs($fd,"Host: ". TRANSLATE_HOST ."\r\n");
		fputs($fd,"Accept-Charset: UTF-8;q=0.7,*;q=0.7\r\n");
		fputs($fd,"User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.12) Gecko/20070508 Firefox/1.5.0.12\r\n");
		fputs($fd,"Connection: close\r\n\r\n");			
		while(!feof($fd))
		{
			$html .= fgets($fd);
		}			
		fclose($fd);
	}
	return $html;
}



//Back substitutes text that should not have been translated.
function back_trans($text,$translation) {
	$orig = preg_split  ( "/\|([^|]+)\|/" , $text,  -1, PREG_SPLIT_DELIM_CAPTURE );
	$new = preg_split  ( "/\|([^|]+)\|/" , $translation,  -1, PREG_SPLIT_DELIM_CAPTURE );
	$map =  array_map("replace_odd",$new,$orig,array_keys($new));
	return substr( array_reduce($map, "cat" , "" ), 1);
}
function replace_odd($token,$replace,$index)
{
	if( $index & 1 ) return $replace;
	return $token;
}
function cat($a,$b) { return $a.$b; }



//Translates actual text using the language pairs
function translate($text, $from_lang, $to_lang) {
	$out = "";
	$gphtml = getPage(array("sl" => $from_lang, "tl" => $to_lang, "text" => $text));

	if(DEBUG) { $fd = fopen("html.txt","w");	fwrite($fd,$gphtml);	fclose($fd); }
	
	$gphtml = ereg_replace(">",">\n",$gphtml);



	$out = ereg_replace('.+<div id="?result_box"? dir="?[lr]t[lr]+"?>',"",$gphtml);
	$out = ereg_replace('</div>.*',"",$out);
	$out = strip_tags($out);
	
	if( preg_match("/\|([^|]+)\|/",$text) )	$out = back_trans($text,trim($out));

	$r = html_entity_decode ( $out, ENT_QUOTES,"UTF-8");
	if(DEBUG) logRequest("$from_lang|$to_lang",$text,$r);
	return $r;
}

//Forces translation for unsupported languages, by using english as an intermediate language
function force_translate($text, $from_lang, $to_lang)
{
	return translate(translate($text, $from_lang , "en"), "en" , $to_lang);
}

function getLangList() {
	$direction = array("tl"=>NULL,"sl"=>NULL);
	if( file_exists(LANGUAGE_LIST_FROM) and file_exists(LANGUAGE_LIST_TO) )
	{

		$tolist = explode("\n",file_get_contents(LANGUAGE_LIST_TO));
		$fromlist = explode("\n",file_get_contents(LANGUAGE_LIST_FROM));
		foreach($tolist as $entry)
		{
			$t = explode("=",$entry);
			if( count($t) == 2 ) $direction['tl'][$t[0]] = $t[1];
		}
		foreach($fromlist as $entry)
		{
			$t = explode("=",$entry);
			if( count($t) == 2 ) $direction['sl'][$t[0]] = $t[1];
		}		
		return $direction;
	}
	
	$gphtml = getPage(array());
	$gphtml = ereg_replace("<select","\n<select",$gphtml);
	$lines = explode("\n",$gphtml);

	foreach ($lines as $line) {
		$matches = array();
		if( preg_match('/<select name=(sl|tl) .+?>(.+?)<\/select>/i',$line,$matches) ) {
			$dir = $matches[1];
			$out = preg_replace('/class=line-below /','',$matches[2]);
			$out = preg_replace('/<option (SELECTED)? value="([A-Za-z-]+?)">([A-Za-z() ]+?)<\/option>/',"\\2=\\3\n",$out);
			$direction[$dir] = $out;
		}
	}

	$fd = NULL;
	foreach($direction as $dir => $text)
	{
		if( $dir == "tl" ) $fd = fopen(LANGUAGE_LIST_TO,"w+");
		else $fd = fopen(LANGUAGE_LIST_FROM,"w+");
		$p = explode("\n",$text);
		$langlines = array();
		foreach( $p as $l )
		{
			$kvpair = explode("=",$l); 
			if( count($kvpair) < 2 ) { continue; }
			$to_lang = $kvpair[0];
			$text = $kvpair[1];
			$langlines[$to_lang] = trim(translate($text,"en",$to_lang)) . "," . trim(translate("What Language?","en",$to_lang));
			fwrite($fd,"$to_lang={$langlines[$to_lang]}\n");
		}
		fclose($fd);
		$direction[$dir] = $langlines;
	}
	return $direction;
}


$action = $_REQUEST['action'];

$langs = getLangList();

if( $action == 'getinfo' ) {
	$list = strtolower($_REQUEST['dir']);
	$info = strtolower($_REQUEST['info']);
	if( isset($langs[$list]) ) {
		foreach( $langs[$list] as $code => $desc)
		{
			$t = explode(",",$desc);
			if( $info == 'names' ) echo "$code\n{$t[0]}\n";
			if( $info == 'questions' ) echo "{$t[1]}\n";
		}
	}
}


//The actual translated output is here
if ($action == 'translate') {
	$lp = split("\|",$_REQUEST['langpair']);
	
	$sl = $lp[0];
	$tl = $lp[1];
	$text = stripslashes($_REQUEST['text']);


	
	if( $sl == $tl ) {
	//Why would you do this? I don't know but if you want to translate your own language into your own language
	//We'll take a shortcut
		echo $text;
	} else {
		if( array_key_exists  ( $sl , $langs['sl'] ) &&  array_key_exists  ( $tl , $langs['tl'] ) )
		{
			$tr = $trans($text,$sl,$tl);
			if( $tr === FALSE ) $tr = force_translate($text,$sl,$tl);
			echo $tr;
		}
	}
}
?>

