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
string REZ_OBJECT;		//Set Via LinkMessage
integer MAX_NODES		 = 32;
string POLYREZ_NOTECARD		= "Polyrez Parameters";

//-- GLOBALS --//
list gRezedObjects = [];
key gDataserverRequest;
integer gNotecardLine;
integer gFollowSlope;
list polyx;
list polyy;
list polyz;
list scalex;
list scaley;
list rezscale;
integer n;

//-- FUNCTIONS --//

//Each list (poly and scale) are arbitrary polynomials constnats
//For Instnace, 3 constants describe a 2nd order polynomial: ax^2 + bx + c
//if gFollowSlope is set, the rezed objects are rotated using the derivitive of the polynomial given
rezNodes(){
	integer max_t = MAX_NODES - 1;
	float t;
	vector p = llGetPos();
	vector offset;
	rezscale = [];
	integer x; integer y; integer z;
	integer lx = llGetListLength(polyx);
	integer ly = llGetListLength(polyy);
	integer lz = llGetListLength(polyz);
	integer sx = llGetListLength(scalex);
	integer sy = llGetListLength(scaley);

	vector delta;
	vector scale;
	rotation rot = ZERO_ROTATION;
	rotation rot2 = ZERO_ROTATION;
	for( t = 0; t <= (float)max_t; t+=1.0 ) {
		offset = ZERO_VECTOR;
		delta = ZERO_VECTOR;
		rot2 = ZERO_ROTATION;
		scale = <0,0,0.02>;
		//Position Polynomials
		for(x = 0; x < lx; ++x) offset.x += llList2Float(polyx,x) * llPow(t/max_t,lx-x-1);
		for(y = 0; y < ly; ++y) offset.y += llList2Float(polyy,y) * llPow(t/max_t,ly-y-1);
		for(z = 0; z < lz; ++z) offset.z += llList2Float(polyz,z) * llPow(t/max_t,lz-z-1);

		//Scale Polynomials
		for(x = 0; x < sx; ++x) scale.x += llList2Float(scalex,x) * llPow(t/max_t,sx-x-1);
		for(y = 0; y < sy; ++y) scale.y += llList2Float(scaley,y) * llPow(t/max_t,sy-y-1);

		//Scale is set in another state, information is stored for later
		rezscale = (rezscale = []) + rezscale + scale;

		if(gFollowSlope) {
			//Follow the Slope of the polynomial in each direction (This is the derivative of the polynomial)
			for(x = 0; x < lx-1; ++x) delta.x += (lz-x-1)*llList2Float(polyx,x) * llPow(t/max_t,lx-x-2);
			for(y = 0; y < ly-1; ++y) delta.y += (lz-y-1)*llList2Float(polyy,y) * llPow(t/max_t,ly-y-2);
			for(z = 0; z < lz-1; ++z) delta.z += (lz-z-1)*llList2Float(polyz,z) * llPow(t/max_t,lz-z-2);
			delta = llVecNorm(delta);
			rot2 *= llAxisAngle2Rot( <0,1,0>, PI_BY_TWO - llAtan2(delta.z,delta.x) );
			rot2 *= llAxisAngle2Rot( <0,0,1>, PI_BY_TWO - llAtan2(delta.z,delta.y) );
		}
		llRezObject(REZ_OBJECT,p+offset,ZERO_VECTOR,rot*rot2,(integer)t+1);
	}
}

//-- STATES --//
default
{
	dataserver(key request_id, string data)
	{
		if( request_id == gDataserverRequest) {
			if( gNotecardLine <= 11 ) {

				//Set All Polynomial Coefficient Lists
				if( gNotecardLine == 1 ) polyx = llCSV2List(data);
				if( gNotecardLine == 3 ) polyy = llCSV2List(data);
				if( gNotecardLine == 5 ) polyz = llCSV2List(data);
				if( gNotecardLine == 7 ) scalex = llCSV2List(data);
				if( gNotecardLine == 9 ) scaley = llCSV2List(data);

				if( gNotecardLine == 11 ) gFollowSlope = (integer)data;

				//Every Other Line is a comment, Skip Them
				gDataserverRequest = llGetNotecardLine(POLYREZ_NOTECARD,gNotecardLine+=2);
			} else {
					rezNodes();
			}
		}
	}
	object_rez(key id) {
		++n;
		gRezedObjects = (gRezedObjects = [] ) + gRezedObjects + id;
		if( n == MAX_NODES ) state scale;
	}
	link_message(integer send_num, integer num, string str, key id)
	{
		if( id == "polyrez" ) {
			n = 0;
			REZ_OBJECT = str;
			gNotecardLine = 1;
			gDataserverRequest = llGetNotecardLine(POLYREZ_NOTECARD,gNotecardLine);
		}
		if (id == "rez") {
			n = 0;
			REZ_OBJECT = str;

			//Stack upward in a linear fasion 3 meters high
			polyx = [0];
			polyy = [0];
			polyz = [3,.5];

			//Use Constant Scale
			vector s = llGetScale();
			scalex = [s.x];
			scaley = [s.y];

			rezNodes();
		}
	}
}

state scale {
	state_entry()
	{
		llListen(-2000,"","","");
		n = 0;
		integer i = 0;
		for(i=0;i<MAX_NODES;++i) {
			llShout(-2003,(string)i + "|" + (string)llList2Vector(rezscale,i));
			llSleep(0.1);
		}
		llSetTimerEvent(15.0);
	}
	listen( integer channel, string name, key id, string message )
	{
		if( llListFindList(gRezedObjects,[id]) != -1 ) ++n;
		else return;
		llResetTime();
		llSetTimerEvent(15.0);
		if( n == MAX_NODES ) {
			llMessageLinked(LINK_THIS,-1,"done","");
			llResetScript();
		}
	}
	timer()
	{
		llOwnerSay("PolyRez: Scale Failed");
		llResetScript();
	}
}
