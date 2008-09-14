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
integer SCALE_CHANNEL		= -2003;
integer MY_ROW;			//Set on_rez

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
integer gRezedFromInventory = FALSE;
integer gListenHandle_Broadcast;
integer gListenHandle_Dialog;
key gLoftRoot;
vector gScale;
integer gSculptType;

//-- FUNCTIONS --//

//Get Color based on divisibility by 4
vector get_color(integer r)
{
	list colors = [<0,0,1>,<0,1,0>,<1,0,0>];
	vector color = <0,0,1>;
	while( r % 4 == 0 && r != 0)
	{
		r /= 2;
		colors = llDeleteSubList(colors,0,0);
	}
	if( llGetListLength(colors) > 0 && r != 0) return llList2Vector(colors,0);
	else return <1,0,0>;
}

//Shoot a beam of particles from one disk center to the next
particleBeam(key target)
{
	if( target)
		llParticleSystem([
			PSYS_PART_FLAGS,
		PSYS_PART_EMISSIVE_MASK|
		PSYS_PART_FOLLOW_VELOCITY_MASK|
		PSYS_PART_FOLLOW_SRC_MASK|
		PSYS_PART_TARGET_POS_MASK,
		PSYS_PART_MAX_AGE, 1.0,
		PSYS_PART_START_ALPHA,0.99,
		PSYS_PART_START_COLOR,<1,1,1>,
		PSYS_PART_START_SCALE,<1,1,1>*0.05,
		PSYS_SRC_BURST_RADIUS,0.0,
		PSYS_SRC_BURST_RATE,0.0,
		PSYS_SRC_BURST_PART_COUNT,1,
		PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_DROP,
		PSYS_SRC_TARGET_KEY,target,
		PSYS_SRC_TEXTURE,"a0eb4021-1b20-4a53-892d-8faa9265a6f5"
			]);
	else llParticleSystem([]);
}

//Sets the shape of the prim depending on the type
setShape(vector color)
{
	vector DEFAULT_COLOR = get_color(MY_ROW);
	if( gSculptType == SCULPT_POINT ) {
		llSetPrimitiveParams([
			PRIM_TYPE,PRIM_TYPE_SPHERE,PRIM_HOLE_DEFAULT ,<0,1,0>,0.0,<0,0,0>,<0,1,0>,
			PRIM_TEXTURE,ALL_SIDES,"5748decc-f629-461c-9a36-a35a221fe21f", <1,1,0>, <0,0,0>, 0,
			PRIM_COLOR,ALL_SIDES,DEFAULT_COLOR,1.0,
			PRIM_SIZE,<.05,.05,.05>
		]);
	}
	if( gSculptType == SCULPT_DISK) {
		llSetPrimitiveParams([
			PRIM_TYPE,PRIM_TYPE_CYLINDER, PRIM_HOLE_DEFAULT, <0,1,0>, 0.0, <0,0,0>, <1,1,0>, <0,0,0>,
			PRIM_TEXTURE,0,"2cc5dcb6-595d-cbb9-e559-7d9e78270f2c", <1,1,0>, <0,0,0>, -PI_BY_TWO,
			PRIM_TEXTURE,1,"5748decc-f629-461c-9a36-a35a221fe21f", <1,1,0>, <0,0,0>, 0,
			PRIM_TEXTURE,2,"2cc5dcb6-595d-cbb9-e559-7d9e78270f2c", <1,1,0>, <0,0,0>, -PI_BY_TWO,
			PRIM_COLOR,0,color,1.0,
			PRIM_COLOR,1,DEFAULT_COLOR,1.0,
			PRIM_COLOR,2,color,1.0,
			PRIM_SIZE,gScale
		]);
	}
	if( gSculptType == SCULPT_NODE) {
		llSetPrimitiveParams([
			PRIM_TYPE,PRIM_TYPE_BOX,PRIM_HOLE_DEFAULT,<0, 1, 0>, 0, <0, 0, 0>, <1, 1, 0>, <0, 0, 0>,
			PRIM_TEXTURE,0,"2cc5dcb6-595d-cbb9-e559-7d9e78270f2c", <1, 1, 0>, <0, 0, 0>, -PI_BY_TWO,
			PRIM_TEXTURE,1,"5748decc-f629-461c-9a36-a35a221fe21f", <1, 1, 0>, <0, 0, 0>, 0,
			PRIM_TEXTURE,2,"5748decc-f629-461c-9a36-a35a221fe21f", <1, 1, 0>, <0, 0, 0>, 0,
			PRIM_TEXTURE,3,"5748decc-f629-461c-9a36-a35a221fe21f", <1, 1, 0>, <0, 0, 0>, 0,
			PRIM_TEXTURE,4,"5748decc-f629-461c-9a36-a35a221fe21f", <1, 1, 0>, <0, 0, 0>, 0,
			PRIM_TEXTURE,5,"2cc5dcb6-595d-cbb9-e559-7d9e78270f2c", <1, 1, 0>, <0, 0, 0>, -PI_BY_TWO,
			PRIM_COLOR,0,color, .9,
			PRIM_COLOR,1,DEFAULT_COLOR, .9,
			PRIM_COLOR,2,DEFAULT_COLOR, .9,
			PRIM_COLOR,3,DEFAULT_COLOR, .9,
			PRIM_COLOR,4,DEFAULT_COLOR, .9,
			PRIM_COLOR,5,color, .9,
			PRIM_SIZE,gScale
		]);
	}
}

integer handleRootCommand(string message) {
	integer s = gSculptType;
	if( message == "show" ) llMessageLinked(LINK_THIS,COMMAND_VISIBLE,"1","");
	if( message == "hide" ) llMessageLinked(LINK_THIS,COMMAND_VISIBLE,"0","");
	if( message == "csect" ) llMessageLinked(LINK_THIS,COMMAND_CSECT,"","");
	if( message == "verts" && gSculptType == SCULPT_DISK) { s=SCULPT_NODE; llSleep(1.25*MY_ROW); llMessageLinked(LINK_THIS,COMMAND_CTYPE,(string)s,""); }
	if( message == "resize" && gSculptType == SCULPT_NODE ) llMessageLinked(LINK_THIS,COMMAND_SIZE,"","nodes");
	if( message == "attach" && gSculptType == SCULPT_NODE ) {s=SCULPT_DISK; llMessageLinked(LINK_THIS,COMMAND_CTYPE,(string)s,""); }
	if( message == "reset" && gSculptType == SCULPT_DISK ) { llMessageLinked(LINK_THIS,COMMAND_RESET,"",""); }
	if( message == "scale" ) { llMessageLinked(LINK_THIS,COMMAND_SCALE,"",""); }
	if( message == "announce" ) { llMessageLinked(LINK_THIS,COMMAND_RENDER,"",""); }
	if( message == "die") { llDie(); }
	return s;
}

//-- STATES --//

default
{
	on_rez(integer param)
	{
		if (!param) return;
		MY_ROW = param - 1;
		gSculptType = SCULPT_DISK;
		gScale = <0.5,0.5,0.01>;
		gRezedFromInventory = FALSE;
		llSetObjectName("sculpt:" + (string)MY_ROW);
		setShape(<1,1,1>);
		llSetAlpha(0.25,ALL_SIDES);
		llListen(BROADCAST_CHANNEL,"","","");
		llListen(SCALE_CHANNEL,"","","");
	}
	state_entry() {
		gSculptType = SCULPT_DISK;
		gRezedFromInventory = FALSE;
		if( gScale != ZERO_VECTOR) setShape(<1,1,1>);
	}
	listen( integer channel, string name, key id, string message )
	{
		if( llGetOwner() != llGetOwnerKey(id) ) return;
		//From Polyrez - Scales this disk (if applicable)
		if(channel == SCALE_CHANNEL)
		{
			list l = llParseString2List(message,["|"],[]);
			if( llList2Integer(l,0) == MY_ROW ) {
				llSetScale((vector)llList2String(l,1));
				gScale = llGetScale();
				llSetAlpha(1.0,ALL_SIDES);
				llSleep(llFrand(3.0));
				llShout(COMM_CHANNEL,"scaled");
			}
		}
		//Establishes Link between the loft-root and this disk
		if(channel == BROADCAST_CHANNEL)
		{
			gLoftRoot = id;
			state link_disks;
		}
	}
}

//Links a particle beam between the disks
state link_disks {
	state_entry() {
		//ROW 32 *should* trigger no_sensor
		llSensor("sculpt:" + (string)(MY_ROW+1),"",SCRIPTED,10.0,TWO_PI);
	}
	sensor(integer total_number)
	{
		particleBeam(llDetectedKey(0));
		if(gSculptType == SCULPT_POINT) state point;
		else state disk;
	}
	no_sensor() {
		if(gSculptType == SCULPT_POINT) state point;
		else state disk;
	}
}

//Handles Actions in the DISK state

state point {
	on_rez(integer i) {
		llListenRemove(gListenHandle_Broadcast);
		gListenHandle_Broadcast = llListen(BROADCAST_CHANNEL,"","",gLoftRoot);
	}
	state_entry() {
		gSculptType=SCULPT_POINT;
		setShape(ZERO_VECTOR);
		llMessageLinked(LINK_THIS,COMMAND_CTYPE,(string)SCULPT_POINT,gLoftRoot);
		llListen(COMM_CHANNEL,"",gLoftRoot,"");
	}
	listen( integer channel, string name, key id, string message)
	{
		if( channel == BROADCAST_CHANNEL )
		{
			llListenRemove(gListenHandle_Broadcast);
			gListenHandle_Broadcast = llListen(BROADCAST_CHANNEL,"",id,"");
			gLoftRoot = id;
			state link_disks; //Relink Disks
		}
		if( channel == COMM_CHANNEL ) {
			integer i = handleRootCommand(message);
			if( i != gSculptType ) {
				if( i == SCULPT_NODE ) state nodes;
				if( i == SCULPT_DISK ) state disk;
			}
		}
		if( message == "Make Disk" ) {
			state disk;
		}
		if( message == "Cancel" ) {
			llListenRemove(gListenHandle_Dialog);
		}
	}
	touch_start(integer n) {
		if( llDetectedKey(0) != llGetOwner()) return;
		llListenRemove(gListenHandle_Dialog);
		integer a = (integer)llFrand(-100000);
		gListenHandle_Dialog = llListen(a,"",llDetectedKey(0),"");
		if( llGetLinkNumber() == 0) { //Not Linked
			llDialog(
				llDetectedKey(0),
				"Pick an action for Row "  + (string)MY_ROW + "\n\n" +
				"[Make Disk] - Expand back into a disk\n",
				["Make Disk","Cancel"],
				a);
		}
		if( llGetLinkNumber() == 1) { //Linked (Is Root)
			llDialog(llDetectedKey(0),"No Operations for points",[],a);
		}
	}
	link_message(integer sender_number, integer num, string str, key id)
	{
		if( (string)id == "recolor" ) {
			setShape((vector)str);
		}
	}
}
state disk {
	on_rez(integer i) {
		llListenRemove(gListenHandle_Broadcast);
		gListenHandle_Broadcast = llListen(BROADCAST_CHANNEL,"","",gLoftRoot);
	}
	state_entry() {
		if( gRezedFromInventory ) {
			gRezedFromInventory = FALSE;
			llListenRemove(gListenHandle_Broadcast);
			gListenHandle_Broadcast = llListen(BROADCAST_CHANNEL,"","",gLoftRoot);
		} else {
				llListen(COMM_CHANNEL,"",gLoftRoot,"");
		}
		gSculptType=SCULPT_DISK;
		setShape(<1,1,1>);
		llMessageLinked(LINK_THIS,COMMAND_CTYPE,(string)SCULPT_DISK,gLoftRoot);
	}
	state_exit()
	{
		gScale = llGetScale();
	}
	touch_start(integer n) {
		if( llDetectedKey(0) != llGetOwner()) return;
		llListenRemove(gListenHandle_Dialog);
		integer a = (integer)llFrand(-100000);
		gListenHandle_Dialog = llListen(a,"",llDetectedKey(0),"");
		if( llGetLinkNumber() == 0) { //Not Linked
			llDialog(
				llDetectedKey(0),
				"Pick an action for Row "  + (string)MY_ROW + "\n\n" +
				"[Detach Verts] - Detach Verticies into individual nodes (Custom Shapes).\n" +
				"[Make Point] - Bring all of the verticies into one single point\n" +
				"[Reset Verts] - Reset all Verticies to the Disk shape",
				["Detach Verts","Make Point","Reset Verts","Cancel"],
				a);
		}
		if( llGetLinkNumber() == 1) { //Linked (Is Root)
			llDialog(
				llDetectedKey(0),
				"Pick an action to perform on this set.\n\n" +
				"[Copy Verts] - Copy the root verticies to the rest of the set.\n" +
				"[Clear Set] - Clear all custom verticies in this set (Disk Shape)\n" +
				"[Resize] - Scale all other disks to match the root disk.\n" +
				"[Interpolate] - Scale + interpolate size between the root and the tail.",
				["Copy Verts","Clear Set","Resize Set","Interpolate","Cancel"],
				a);
		}
	}
	listen( integer channel, string name, key id, string message)
	{
		if( channel == BROADCAST_CHANNEL )
		{
			llListenRemove(gListenHandle_Broadcast);
			gListenHandle_Broadcast = llListen(BROADCAST_CHANNEL,"",id,"");
			llListen(COMM_CHANNEL,"",id,"");
			gLoftRoot = id;
			state link_disks; //Relink Disks
		}
		if( channel == COMM_CHANNEL ) {
			integer i = handleRootCommand(message);
			if( i != gSculptType ) {
				if( i == SCULPT_NODE ) state nodes;
				if( i == SCULPT_POINT ) state point;
			}
		}
		if( message == "Detach Verts" ) {
			state nodes;
		}
		if( message == "Make Point" ) {
			state point;
		}
		if( message == "Reset Verts" ) {
			llMessageLinked(LINK_THIS, COMMAND_RESET,"","");
		}
		if( message == "Copy Verts") {
			llMessageLinked(LINK_THIS,COMMAND_COPY,"","");
		}
		if( message == "Interpolate") {
			llDialog(
				id,
				"Interpolate Which Values?\n\n" +
				"[Scale] - Copy the root verticies to the rest of the set.\n" +
				"[Node Data] - Clear all custom verticies in this set (Disk Shape)\n" +
				"[Rotation] - Scale all other disks to match the root disk.\n" +
				"[Cancel] - Scale + interpolate size between the root and the tail.",
				["Scale","Node Data","Rotation","Cancel"],
				channel);
		}
		if( message == "Scale") {
			llMessageLinked(LINK_THIS,COMMAND_CTYPE,(string)SCULPT_DISK,gLoftRoot);
			llSleep(1.0);
			llMessageLinked(LINK_SET,COMMAND_INTERP,(string)llGetScale(),"scale");
		}
		if( message == "Rotation") {
			llMessageLinked(LINK_THIS,COMMAND_CTYPE,(string)SCULPT_DISK,gLoftRoot);
			llSleep(1.0);
			llMessageLinked(LINK_SET,COMMAND_INTERP,(string)llGetRot(),"rot");
		}
		if( message == "Node Data") {
			llMessageLinked(LINK_THIS,COMMAND_CTYPE,(string)SCULPT_DISK,gLoftRoot);
			llSleep(1.0);
			llMessageLinked(LINK_SET,COMMAND_INTERP,"","node");
		}
		if( message == "Clear Set") {
			llMessageLinked(LINK_SET,COMMAND_RESET,"","");
		}
		if( message == "Resize Set") {
			llMessageLinked(LINK_SET,COMMAND_SIZE,(string)llGetScale(),"set");
		}
		if( message == "Cancel" ) {
			llListenRemove(gListenHandle_Dialog);
		}
	}
	link_message(integer sender_number, integer num, string str, key id)
	{
		if( (string)id == "recolor" ) {
			gScale = llGetScale();
			setShape((vector)str);
		}
	}
}

//Handles actions for the NODE state
//Will Revert back to DISK if anything happens
state nodes {
	on_rez(integer p) {
		gRezedFromInventory = TRUE;
		state disk;
	}
	state_entry() {
		gSculptType=SCULPT_NODE;
		setShape(<1,1,1>);
		llMessageLinked(LINK_THIS,COMMAND_CTYPE,(string)SCULPT_NODE,gLoftRoot);
		llListen(COMM_CHANNEL,"",gLoftRoot,"");
	}
	touch_start(integer n) {
		if( llDetectedKey(0) != llGetOwner()) return;
		llListenRemove(gListenHandle_Dialog);
		integer a = (integer)llFrand(-100000);
		gListenHandle_Dialog = llListen(a,"",llDetectedKey(0),"");
		llDialog(
			llDetectedKey(0),
			"Pick an action for Row " + (string)MY_ROW + "\n\n" +
			"[Attach  Verts] - Save the custom verticies back into the shape.\n"+
			"[Cross Section] - Attempt to cross section whatever physical object is inside the disk.",
			["Attach Verts","Cross Section","Cancel"],
			a);
	}
	state_exit()
	{
		gScale = llGetScale();
	}
	//Node Actions
	listen( integer channel, string name, key id, string message)
	{
		if( channel == COMM_CHANNEL ) {
			integer i = handleRootCommand(message);
			if( i != gSculptType ) {
				if( i == SCULPT_POINT ) state point;
				if( i == SCULPT_DISK ) state disk;
			}
		}
		if( message == "Attach Verts" ) {
			state disk;
		}
		if( message == "Cross Section" ) {
			llMessageLinked(LINK_SET,COMMAND_CSECT,"","");
		}
		if( message == "Cancel" ) {
			llListenRemove(gListenHandle_Dialog);
		}
	}

	link_message( integer send_num, integer num, string str, key id)
	{
		if( (string)id == "recolor" ) {
			gScale = llGetScale();
			setShape((vector)str);
		}
		if( num == -5 ) {
			if( str == "disk" ) {
				state disk;
			}
		}
	}
	//Collapse All Children if this becomes ROOT
	//If they have verticies outside of the disk, they
	//are instantly attached
	changed( integer i )
	{
		if( llGetLinkNumber() == LINK_ROOT) {
			llMessageLinked(LINK_ALL_OTHERS, -5, "disk","");
			state disk;
		}
	}
}

