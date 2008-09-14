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
//	along with Open Babel Fish.  If not, see <http://www.gnu.org/licenses/>
//
//	  Author: Falados Kapuskas
//	  Date: 7/20/2008
//	  Version: 1.4

//NoteCards
integer line;
integer card = 0;

//Dialogs
integer DIALOG_CHANNEL = -40;	//Dialog Channel to listen for requests
float DIALOG_TIMEOUT = 30.0;	//Amount of time for the ask dialog to time out
integer dialog_index = 0;
key read_key;
integer PAGE;
integer MAX_PAGE = 0;
string URL;
key gHTTPRequest;
key gDataserverRequest;
integer gHTTPStage;
list http_parm = [
	HTTP_METHOD, "POST",
	HTTP_MIMETYPE,"application/x-www-form-urlencoded"
];

list language_names = [];
list what_language = [];
list dialog_wait = [];


get_pages() {
	PAGE = 0;
	integer n = llGetListLength(language_names)/2;
	if( n <= 12 ) MAX_PAGE = 0;
	else {
		//First Page
		n -= 11;
		
		//Middle Pages
		while(n > 11) 
		{
			n-=10;
			++MAX_PAGE;
		}
		
		//Last Page
		++MAX_PAGE;
	}
}

dialog(key id) {
	integer page=0;
	integer i = llListFindList(dialog_wait,[id]);
	if( i == -1) {
		dialog_wait += [id,0,llListen(DIALOG_CHANNEL,"",id,""),llGetWallclock()+DIALOG_TIMEOUT];
	} else {
		page = llList2Integer(dialog_wait,i+1);
		llListenRemove(llList2Integer(dialog_wait,i+2));
		//Update with new listen handle and timeout
		dialog_wait = llListReplaceList(dialog_wait,[llListen(DIALOG_CHANNEL,"",id,""),llGetWallclock()+DIALOG_TIMEOUT],i+2,i+3);
	}	
	
	string next = ">>";
	string back = "<<";
	
	list codes = llList2ListStrided(llDeleteSubList(language_names, 0, 0), 0, -1, 2);
	
	list b;
	integer START = 0;
	integer END = -1;
	if( page == 0 ) {
		if( page == MAX_PAGE )
			b = llList2List(codes,0,-1);
		else
			b = llList2List(codes,0,1) + [next] + llList2List(codes,2,10);
	}
	else if( page == MAX_PAGE) {
		START = 11 + 10*(MAX_PAGE-1);
		END = -1;
		b = [back] + llList2List(codes,START,END);		
	} else {
		START = 11 + 10*(MAX_PAGE-2);
		END = START + 9;
		b = [back] + llList2List(codes,START,START) + [next] + llList2List(codes,START+1,END);
	}
	string message = " " + llGetSubString(llDumpList2String(llList2List(what_language,START,END),"\n"),0,250);
	llDialog(id,message,b,DIALOG_CHANNEL);
}

default {
	state_entry()
	{
		gDataserverRequest = llGetNotecardLine("URL",0);
		gHTTPStage = 0;
	}
	
	http_response( key request_id, integer status, list metadata, string body )
	{
		if( gHTTPRequest == request_id )
		{
			if( status != 200 ) { llOwnerSay("Error loading languages"); state error; }
			if( gHTTPStage == 0 ) {
				language_names = llParseString2List(body,["\n"],[]);
				integer i = 0;
				string s;
				//Make sure the buttons are not too big.
				for(i=0;i<llGetListLength(language_names);++i) 
				{
					s = llList2String(language_names,i);
					if( llStringLength(s) > 24 ) {
						language_names = (language_names=[]) + llListReplaceList(language_names,[s],i,i);
					}
				}
				gHTTPRequest = llHTTPRequest(URL,http_parm,"action=getinfo&dir=tl&info=questions");
				gHTTPStage = 1;
			} else {
				what_language = llParseString2List(body,["\n"],[]);
				state ready;
			}
		}
	}
	dataserver(key req, string data)
	{
		if( req == gDataserverRequest )
		{
			URL = data;
			gHTTPRequest = llHTTPRequest(URL,http_parm,"action=getinfo&dir=tl&info=names");
		}
	}	
}

state error 
{
	changed(integer change) {
		if( change & CHANGED_INVENTORY ) llResetScript();
	}
}

state ready {
	state_entry()
	{
		get_pages();
		llMessageLinked(LINK_THIS,0,"init","dialog");
	}
	link_message(integer sender_number, integer number, string message, key id)
	{
		//Display Ask Dialog
		if( message == "ask_lang") {
			dialog(id);
			llSetTimerEvent(1.0);
		}
		//Verify Auto-translate Langpair
		if(number == -2) {
			integer i = llListFindList(language_names,[message]);
			if( i != -1 ) {
				llMessageLinked(LINK_THIS,-1,llList2String(language_names,i),id);
			}
		}
		//Tell setup we are ok
		if( number == -3 && message == "setup" && id == "root" ) {
			llMessageLinked(LINK_THIS,0,"init","dialog");
		}
	}
	changed(integer change) {
		if( change & CHANGED_INVENTORY ) llResetScript();
	}
	listen(integer channel, string name, key id, string message)
	{
		integer i = llListFindList(language_names,[message]);
		if( i != -1 ) {	//Response is a valid langugage
			llMessageLinked(LINK_THIS,-1,llList2String(language_names,i-1),id);
			i = llListFindList(dialog_wait,[id]);
			if( i != -1) {
				dialog_wait = llDeleteSubList(dialog_wait,i,i+3);
			}
			if( dialog_wait == [] ) llSetTimerEvent(0.0);
		} else {
				integer j = llListFindList(dialog_wait,[id]);
			integer page;
			if( j != -1 ) {
				page = llList2Integer(dialog_wait,j+1);
				if( message == ">>") ++page;
				if( message == "<<") --page;
				if(page < 0) page = 0;
				if(page > MAX_PAGE) page = MAX_PAGE;

				dialog_wait = llListReplaceList(dialog_wait,[page],j+1,j+1);
				dialog(id);
				llSetTimerEvent(1.0);
			}
		}
	}
	timer()
	{
		integer len = llGetListLength(dialog_wait)/4;
		if(len == 0) { llSetTimerEvent(0.0); return; }
		integer i;
		for( i = 0; i < len; ++i) {
			if( llGetWallclock() > llList2Float(dialog_wait,i*4+3) ) { //Timeout
				//Tell them they timed out
				llMessageLinked(LINK_THIS,-4,"timeout",llList2Key(dialog_wait,i*4));
				//Remove their listen entry
				llListenRemove(llList2Integer(dialog_wait,i*4+2));
				dialog_wait = llDeleteSubList(dialog_wait,i*4,i*4+3);
				--len;
				--i;
			}
		}
	}
}

