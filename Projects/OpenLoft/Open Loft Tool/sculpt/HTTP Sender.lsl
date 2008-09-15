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
integer DISPLAY_CHANNEL 	= -131415;
integer DATA_CHANNEL 		= 0;
integer	BROADCAST_CHANNEL	 = -234567;
integer SUCCESS_CHANNEL		= -2001;
integer ERROR_CHANNEL		= -2002;
string URL;
list HTTP_PARAMS = [
	HTTP_METHOD, "POST",
	HTTP_MIMETYPE,"application/x-www-form-urlencoded"
		];

integer MY_ROW;	//Set on_rez

//-- GLOBALS --//
key gHTTPRequest;
integer gListenHandle_URL;
integer gListenHandle_DISPLAY;
//-- FUNCTIONS --//

sendNodes(integer row, string data) {

	if(DATA_CHANNEL != 0)
	{
		list l = llCSV2List(data);
		if( llGetListLength(l) > 1) {
			llSay(DATA_CHANNEL,llList2CSV([0]+llList2List(l,0,15)));
			llSay(DATA_CHANNEL,llList2CSV([16]+llList2List(l,16,-1)));
		} else {
			llSay(DATA_CHANNEL,data);
		}
	} else {
		MY_ROW = row;
		string request = "action=upload&row=" + (string)row;
		gHTTPRequest = llHTTPRequest(URL + request,HTTP_PARAMS,"verts=" + llEscapeURL(data));	
	}
}

//-- STATES --//

default {
	on_rez(integer param) {
		if( param != 0)
		{
			gListenHandle_URL = llListen(BROADCAST_CHANNEL,"","","");
			gListenHandle_DISPLAY = llListen(DISPLAY_CHANNEL,"","","");
		}
	}
	listen(integer channel, string name, key id, string msg) {
		if( llGetOwner() != llGetOwnerKey(id)) return;
		
		if(channel == BROADCAST_CHANNEL) 
		{
			llListenRemove(gListenHandle_URL);
			URL = llStringTrim(msg,STRING_TRIM);
			if( llSubStringIndex(URL,"?") == -1) URL = URL + "?";
		} else
		if(channel == DISPLAY_CHANNEL)
		{
			DATA_CHANNEL = (integer)msg;
		}
	}

	link_message( integer send_num, integer num, string str, key id) {
		if( num == -10 ) {
			if( URL == "") { llShout(ERROR_CHANNEL,(string)MY_ROW + " - No URL"); return;}
			string row = (string)id;
			sendNodes((integer)row , str);
		}
	}
	http_response(key request_id, integer status, list meta, string message)
	{
		if( request_id == gHTTPRequest) {
			if( llStringTrim(message,STRING_TRIM) == "") {
				llShout(SUCCESS_CHANNEL,(string)MY_ROW);
			} else {
				llShout(ERROR_CHANNEL,(string)MY_ROW + ": " + message);
			}
		}
	}
}


