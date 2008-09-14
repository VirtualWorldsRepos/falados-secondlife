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
integer	BROADCAST_CHANNEL	 = -234567;
integer COMM_CHANNEL		= -2000;
integer MY_ROW;			//Set on_rez
//Actions
integer SPAWN_NODES		= 0;
integer ATTACH_VERTS	= 1;
integer SEND_NODES		= 2;
integer RESET_VERTS		= 3;
integer SEND_SCALE		= 4;
//SculptTypes
integer SCULPT_POINT	= 0;
integer SCULPT_DISK		= 1;
integer SCULPT_NODE		= 2;
//LinkCommands
integer COMMAND_CTYPE	= -1;
integer COMMAND_RESET	= -2;
integer COMMAND_SCALE	= -3;
integer COMMAND_VISIBLE = -4;
integer COMMAND_RENDER	= -5;
integer COMMAND_CSECT	= -6;
integer COMMAND_INTERP	= -7;
integer COMMAND_SIZE	= -8;
integer COMMAND_COPY	= -9;

//-- GLOBALS --//
vector gScale;
vector gPosition;
rotation gRotation;
list gRezedNodes;
list gNodeInfo;
integer gSculptType;

//For Interpolation
vector gRootScale;
rotation gRootRot;
list gRootNodes;

//-- FUNCTIONS --//

// Performs actions using a common status notifier
performAction(integer action) {
	vector color = llGetColor(0);
	llMessageLinked(LINK_THIS,0,"<1,1,0>","recolor");
	gPosition = llGetPos();
	gRotation = llGetRot();
	gScale = llGetScale();
	if( action == SPAWN_NODES )
	{
		llSetText("Spawning Nodes\n"+(string)MY_ROW,<1,1,0>,1);
		spawnNodes();
	}
	if( action == ATTACH_VERTS )
	{
		llSetText("Attaching Verticies\n"+(string)MY_ROW,<1,1,0>,1);
		storeNodeInfo();
	}
	if( action == SEND_NODES )
	{
		llSetText("Sending Nodes\n"+(string)MY_ROW,<1,1,0>,1);
		sendNodes();
	}
	if( action == RESET_VERTS )
	{
		llSetText("Resetting Verticies\n"+(string)MY_ROW,<1,1,0>,1);
		resetVerts();
	}
	if( action == SEND_SCALE )
	{
		llSetText("Sending Scale Information\n"+(string)MY_ROW,<1,1,0>,1);
		sendScaleInfo();
	}
	llMessageLinked(LINK_THIS,0,(string)color,"recolor");
	llSetText("",<0,0,1>,1);
}

// Spawns the individual nodes that can be moved around
spawnNodes(){
	gRezedNodes = [];
	integer channel = (integer)llFrand(-1000)*1000;
	integer i;
	integer MAX = 32;
	vector offset;
	integer DUMP = (gNodeInfo == []);
	for( i = 0; i < MAX; ++i) {
		float t = ((float)i/MAX)*TWO_PI;
		if(DUMP)
			offset = <llCos(t),llSin(t),0>;
		else
			offset = (vector)llList2String(gNodeInfo,i);
		llRezObject("node",unpackNode(offset),ZERO_VECTOR,llEuler2Rot(<0,0,t>)*gRotation, channel - i );
	}
	llSleep(1.0);
	llShout(channel,(string)BROADCAST_CHANNEL);
}

// Resets the verticies back into a disk
resetVerts(){
	integer i;
	integer MAX = 32;
	gNodeInfo = [];
	float t;
	for( i = 0; i < MAX; ++i) {
		t = ((float)i/MAX)*TWO_PI;
		gNodeInfo = (gNodeInfo = []) + gNodeInfo + <llCos(t),llSin(t),0>;
	}
}

// Applys the new position, rotation, and gScale information to normalized data
vector unpackNode(vector node) {
	node.x *= (gScale.x/2);
	node.y *= (gScale.y/2);
	return node * gRotation+gPosition;
}

// Removes all relative information, thereby normalizing the data
vector packNode(vector node) {
	node -= gPosition;
	node /= gRotation;
	node.x /= (gScale.x/2);
	node.y /= (gScale.y/2);
	return node;
}

// Retrieves and normalizes all individual nodes, storing them in the dumplist
storeNodeInfo() {
	gNodeInfo = [];
	integer MAX = llGetListLength(gRezedNodes);
	integer i;
	for( i = 0; i < MAX; ++i)
	{
		gNodeInfo = (gNodeInfo = []) + gNodeInfo +
			packNode(llList2Vector(llGetObjectDetails(llList2Key(gRezedNodes,i),[OBJECT_POS]),0));
	}
}

// Sends nodes to the server for processing
sendNodes(){
	string r = (string)MY_ROW;
	if( gSculptType == SCULPT_POINT ) { llMessageLinked(LINK_THIS,-10,(string)llGetPos(),r); return; }
	if( gNodeInfo == []) resetVerts();
	integer i;
	integer MAX = llGetListLength(gNodeInfo);
	string dump;
	for( i = 0; i < MAX; ++i) {
		dump += (string)( unpackNode((vector)llList2String(gNodeInfo,i)) );
		if( i < MAX-1 ) dump += ",";
	}
	llMessageLinked(LINK_THIS,-10,dump,r);
}

//Rescale the box based on extrema
rescale()
{
	storeNodeInfo();
	list d = getExtrema();
	vector scale  = llList2Vector(d,1) - llList2Vector(d,0);
	scale.z = 0.02;
	llSetScale(scale);
}

//Get extreme points
list getExtrema()
{
	integer i;
	integer MAX = llGetListLength(gNodeInfo);
	vector v;
	vector max = <1,1,1>*-999;
	vector min = <1,1,1>*999;
	for( i = 0; i < MAX; ++i) {
		v = unpackNode(llList2Vector(gNodeInfo,i));
		if( v.x > max.x ) max.x = v.x;
		if( v.y > max.y ) max.y = v.y;
		if( v.z > max.z ) max.z = v.z;

		if( v.x < min.x ) min.x = v.x;
		if( v.y < min.y ) min.y = v.y;
		if( v.z < min.z ) min.z = v.z;
	}
	return [min,max];
}

// Announces the extreme points, used for scaling the bounding box
sendScaleInfo() {
	llSleep(llFrand(3.0));
	if( gSculptType == SCULPT_POINT ) {
		llShout(COMM_CHANNEL,(string)llGetPos());
		return;
	}
	list d;
	if( gNodeInfo == [] ) {
		vector p = llGetPos();
		rotation r = llGetRot();
		d = llGetBoundingBox(llGetKey());
		d = ( d=[]) + [llList2Vector(d,0)*r + p,llList2Vector(d,1)*r + p];
	} else {
			d = getExtrema();
	}
	llShout(COMM_CHANNEL,llList2String(d,0) + "|" + llList2String(d,1));
}

//Hashes the color using a simple hashing function
vector getColorHash()
{
	integer i;
	integer MAX = llGetListLength(gNodeInfo);
	vector v = ZERO_VECTOR;
	for( i = 0; i < MAX; ++i) {
		v += ((vector)llList2String(gNodeInfo,i));
	}
	v.x = llFabs(v.x);
	v.y = llFabs(v.y);
	v.z = llFabs(v.z);
	return llVecNorm(v);
}

//-- STATES --//

default
{
	on_rez(integer param)
	{
		if (!param) return;
		MY_ROW = param - 1;
		gSculptType = SCULPT_DISK;
		gRezedNodes = [];
		llSetText("",<1,1,1>,1);
	}
	link_message( integer send_num, integer num, string str, key id)
	{
		if( num == COMMAND_CTYPE) {
			integer new = (integer)str;
			if( new == gSculptType) return;
			if( new == SCULPT_NODE ) { performAction(SPAWN_NODES); }
			if( new == SCULPT_DISK )
			{
				performAction(ATTACH_VERTS);
				if( gNodeInfo != [] )
				{
					llMessageLinked(LINK_THIS,0,(string)getColorHash(),"recolor");
				}
				gRezedNodes = [];
				llShout(BROADCAST_CHANNEL,"die");
			}
			if( new == SCULPT_POINT) { gRezedNodes = []; gNodeInfo = []; }
			gSculptType = new;
		}
		if( num == COMMAND_VISIBLE) {
			if( (integer)str ) {
				llSetAlpha(1.0,ALL_SIDES);
			} else {
					llSetAlpha(0.0,ALL_SIDES);
			}
		}
		if( num == COMMAND_RESET ) {
			if( gSculptType == SCULPT_DISK ) {
				performAction(RESET_VERTS);
				llMessageLinked(LINK_THIS,0,"<1,1,1>","recolor");
			}
		}
		if( num == COMMAND_RENDER ) {
			if( gSculptType == SCULPT_NODE ) performAction(ATTACH_VERTS);
			performAction(SEND_NODES);
		}
		if( num == COMMAND_SCALE ) {
			if( gSculptType == SCULPT_NODE) performAction(ATTACH_VERTS);
			performAction(SEND_SCALE);
		}
		if( num == COMMAND_SIZE ) {
			if( (string)id == "nodes" && gSculptType == SCULPT_NODE ) {
				rescale();
				llMessageLinked(LINK_THIS,0,(string)getColorHash(),"recolor");
			}
			if( (string)id == "set") {
				llSetScale((vector)str);
			}
		}
		if( num == COMMAND_CSECT ) {
			if( gSculptType == SCULPT_NODE) llShout(BROADCAST_CHANNEL,"csect");
		}
		if( num == COMMAND_INTERP ) {
			if( (string)id == "scale" ) {
				gRootScale = (vector)str;
				if( llGetNumberOfPrims() == llGetLinkNumber() ) llMessageLinked(LINK_ALL_CHILDREN,COMMAND_INTERP,(string)llGetScale(),"scale-tail");
			}
			if( (string)id == "rot" ) {
				gRootRot = (rotation)str;
				if( llGetNumberOfPrims() == llGetLinkNumber() ) llMessageLinked(LINK_ALL_CHILDREN,COMMAND_INTERP,(string)llGetLocalRot(),"rot-tail");
			}
			if( (string)id == "node" && llGetLinkNumber() == 1 ) {
				llMessageLinked(LINK_ALL_CHILDREN,COMMAND_INTERP,llList2CSV(gNodeInfo),"node-head");
			}
			if( (string)id == "node-head" ) {
				gRootNodes = llCSV2List(str);
				if( llGetNumberOfPrims() == llGetLinkNumber() ) llMessageLinked(LINK_ALL_CHILDREN,COMMAND_INTERP,llList2CSV(gNodeInfo),"node-tail");
			}
			if(llGetNumberOfPrims() == llGetLinkNumber()) return;
			float p = (float)(llGetLinkNumber()-1) / (float)(llGetNumberOfPrims()-1);
			if( (string)id == "scale-tail" )
			{
				vector tail = (vector)str;
				vector final = gRootScale * (1.0-p) + tail * p;
				final.z = 0.02;
				llSetScale(final);
			}
			if( (string)id == "rot-tail" )
			{
				llSetLocalRot(llEuler2Rot( llRot2Euler(gRootRot/llGetRootRotation())*(1.0-p) + llRot2Euler( (rotation)str )*p ));
			}
			if( (string)id == "node-tail" )
			{
				gNodeInfo = [];
				list tailnodes = llCSV2List(str);
				integer i = 0;
				integer len = llGetListLength(tailnodes);
				for( i = 0; i < len; ++i)
				{
					gNodeInfo = (gNodeInfo = []) + gNodeInfo + [(vector)llList2String(gRootNodes,i)*(1.0-p) + (vector)llList2String(tailnodes,i)*p];
				}
				tailnodes = [];
				gRootNodes = [];
				llMessageLinked(LINK_THIS,0,(string)getColorHash(),"recolor");
			}
		}
		if( num == COMMAND_COPY ) {
			if( gSculptType != SCULPT_POINT) {
				if( str == "" ) {
					if( gSculptType == SCULPT_NODE ) performAction(ATTACH_VERTS);
					llMessageLinked(LINK_ALL_OTHERS,COMMAND_COPY,llList2CSV(gNodeInfo),"");
				} else {
						gNodeInfo = (gNodeInfo = []) + llCSV2List(str);
					llMessageLinked(LINK_THIS,0,(string)getColorHash(),"recolor");
				}
			}
		}
	}
	object_rez(key id)
	{
		gRezedNodes = (gRezedNodes = []) + gRezedNodes + id;
	}
}

