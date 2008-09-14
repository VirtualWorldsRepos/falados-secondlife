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

//-- CONSTANTS --//
list HTTP_PARAMS = [
	HTTP_METHOD, "POST",
	HTTP_MIMETYPE,"application/x-www-form-urlencoded"
		];
string  NODE_NAME = "sculpt";
integer BROADCAST_CHANNEL = -234567;
integer DIALOG_CHANNEL  = 4209249;
integer MAX_NODES	   = 32;
integer ENCLOSED		= FALSE;
string  URL;			//Set Via Notecard

//-- Globals --//
key gCurrentKey;
key gDataserverRequest;
string gBlurType = "none";
integer gHasRezed;
integer gListenHandle_Enclose;		 //Listen for Nodes
integer gListenHandle_Agent;		 //Avatar listen callback
integer gListenHandle_Errors;		//Render Errors
integer gListenHandle_Success;		//Render Success
integer n;

vector bbox_lower;
vector bbox_higher;

//-- FUNCTIONS --//

//Trigger PolyRez to rez the sculpting nodes
rezSculptNodes(string rez_type){
	gHasRezed = TRUE;
	llMessageLinked(LINK_THIS,-1,NODE_NAME,rez_type);
}

//Starts the Rundering Process by announcing and waiting
//for replies.  Once all replies are in, a final request
//is sent that informs the server to compile the image.
render(){
	n = 0;
	llListenRemove(gListenHandle_Errors);
	llListenRemove(gListenHandle_Success);
	gListenHandle_Errors = llListen(-2002,"","","");
	gListenHandle_Success = llListen(-2001,"","","");
	llShout(-2000,"announce");
}

minmax(vector vert) {
	//Min
	if( vert.x < bbox_lower.x ) bbox_lower.x = vert.x;
	if( vert.y < bbox_lower.y ) bbox_lower.y = vert.y;
	if( vert.z < bbox_lower.z ) bbox_lower.z = vert.z;

	//Max
	if( vert.x > bbox_higher.x ) bbox_higher.x = vert.x;
	if( vert.y > bbox_higher.y ) bbox_higher.y = vert.y;
	if( vert.z > bbox_higher.z ) bbox_higher.z = vert.z;
}

//-- STATES --//

default
{
	on_rez(integer p){
		//If the key changed, inform the sculpting nodes about it.
		if( llGetKey() != gCurrentKey )
		{
			llSleep(0.5);
			llShout(BROADCAST_CHANNEL,gCurrentKey); //Automatically carries the new key (listen event)
			gCurrentKey = llGetKey();
		}
		gDataserverRequest = llGetNotecardLine("OpenLoft URL",0);
	}
	listen(integer c, string st, key id, string m)
	{
		if (llGetOwnerKey(id) != llGetOwner()) return;
		if( c == DIALOG_CHANNEL ) {
			if (m == "RENDER"){
				if(ENCLOSED) {
					render();
				} else {
					llOwnerSay("You must first ENCLOSE the sculpt before you can render it");
				}
			}
			if (m == "REZ"){
				if(gHasRezed) llShout(-2000,"die");
				rezSculptNodes("rez");
			}
			if (llListFindList(["REZ","SHOW","HIDE","CSECT","VERTS","RESIZE","ATTACH"],[m]) != -1 ) {
				llShout(-2000,llToLower(m));
			}
			if (m == "POLYREZ"){
				if(gHasRezed) llShout(-2000,"die");
				rezSculptNodes("polyrez");
			}
			if (m == "LINEAR" || m== "GAUSSIAN" || m =="NONE"){
				gBlurType = llToLower(m);
			}
			if (m == "ENCLOSE"){
				n = 0;
				ENCLOSED = FALSE;
				llShout(-2000,"scale");
				llListenRemove(gListenHandle_Enclose);
				gListenHandle_Enclose = llListen(-2000,"","","");
				bbox_lower = <999,999,999>;
				bbox_higher = <-999,-999,-999>;
				llResetTime();
				llSetTimerEvent(15.0);
			}
			if (m == "SMOOTH"){
				llDialog(llGetOwner(),"Current Smoothing Type: " + llToUpper(gBlurType) +"\n\n" +
					"[NONE] - No smoothing, use raw vertex data\n" +
					"[LINEAR] - Blurs the image slightly to smooth out bumps\n" +
					"[GAUSSIAN] - Blurs the image, but preserves some finer details",
					["NONE","LINEAR","GAUSSIAN"],DIALOG_CHANNEL);
			} else {
					llListenRemove(gListenHandle_Agent);
			}
		}
		//Size Reponses
		if( c == -2000 )
		{
			llResetTime();
			llSetTimerEvent(15.0);
			++n;
			integer break = llSubStringIndex(m,"|");
			if( break != -1 )
			{
				minmax((vector)llGetSubString(m,0,break-1));
				minmax((vector)llGetSubString(m,break+1,-1));
			} else {
					minmax((vector)m);
			}

			if( n >= MAX_NODES ) {
				vector scale = bbox_higher - bbox_lower;
				vector pos = bbox_lower + scale*.5;
				if( llVecMag(scale) < 17.4 ) {
					llSetPos(pos);
					llSetScale(scale*1.01);
					ENCLOSED = TRUE;
				} else {
						llOwnerSay("Enclose Failed - Size Too Big");
				}
				llSetTimerEvent(0.0);
				llListenRemove(gListenHandle_Enclose);
			}
		}
		//Successful Upload Responses
		if( c == -2001 ) {
			++n;
			if( n == MAX_NODES ) {
				llHTTPRequest(URL + "action=render",HTTP_PARAMS,
					"scale=" + llEscapeURL((string)llGetScale()) +
					"&org=" + llEscapeURL((string)llGetPos()) +
					"&smooth=" + gBlurType
						);
			}
		}
		//Errored Responses
		if( c == -2002 ) {
			llOwnerSay("Error on row " + m);
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		llListenRemove(gListenHandle_Enclose);
		llOwnerSay("Enclose Failed - Not All Nodes Responded");
	}
	link_message(integer sn, integer n, string s, key id)
	{
		//PolyRez Done Rezing
		if( n == -1 && s == "done" )
		{
			gDataserverRequest = llGetNotecardLine("OpenLoft URL",0);
		}
	}

	touch_start(integer total_number)
	{
		if(llDetectedKey(0) != llGetOwner()) return;

		llListenRemove(gListenHandle_Agent);
		gListenHandle_Agent = llListen(DIALOG_CHANNEL,"",llGetOwner(),"");
		llDialog(llGetOwner(),"Sculpt Options\n\n"+
			"[RENDER] - Render verticies.\n" +
			"[REZ] - Creates disk column\n" +
			"[POLYREZ] - Disks that follow a polynomial.\n" +
			"[SHOW] - Shows all disks and nodes\n" +
			"[HIDE] - Hides all disks and nodes\n" +
			"[VERTS] - Detach all verticies\n" +
			"[RESIZE] - Rescale all node disks\n" +
			"[ATTACH] - Attach all verticies\n" +
			"[CSECT] - Cross section the physical prim enclosed\n" +
			"[ENCLOSE] - Auto-encloses the sculpture\n" +
			"[SMOOTH] - Change the smoothing parameter"
				,["RENDER","REZ","POLYREZ","SHOW","HIDE","VERTS","RESIZE","ATTACH","CSECT","ENCLOSE","SMOOTH"],DIALOG_CHANNEL);
	}

	dataserver( key request_id, string data)
	{
		if( gDataserverRequest == request_id) {
			URL = data;
			if( URL != "URL HERE") {
				if(llSubStringIndex(URL,"?") == -1) URL = URL + "?";
				llShout(BROADCAST_CHANNEL,URL);
			} else {
				llOwnerSay("You must replace the url in the 'OpenLoft URL' notecard");
			}
		}
	}

	//This is here simply to echo the links that the server replies with
	http_response( key request_id, integer status, list meta, string data)
	{
		if( status == 200 ) { //OK
			if( llStringTrim(data,STRING_TRIM) != "" )
				llOwnerSay(data);
		} else {
				llOwnerSay("Server Error: " + (string)status + "\n" + llList2CSV(meta) + "\n" + data);
		}
	}
}
