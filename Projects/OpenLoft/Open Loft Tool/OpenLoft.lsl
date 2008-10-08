//    This file is part of OpenLoft.
//
//    OpenLoft is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    OpenLoft is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with OpenLoft.  If not, see <http://www.gnu.org/licenses/>.
//
//    Authors: Falados Kapuskas, JoeTheCatboy Freelunch

//-- CONSTANTS --//
list HTTP_PARAMS = [
    HTTP_METHOD, "POST",
    HTTP_MIMETYPE,"application/x-www-form-urlencoded"
];

list MAIN_DIALOG = [
"[RESOLUTION] Change Resolution","RESOLUTION",
"[REZ] Open the Rez MEnu","REZ",
"[RENDERING] Render Menu","RENDERING",
"[TOOLS] Tools Menu","TOOLS",
"[SPLINE] Spline Menu","SPLINE",
"[ACCESS] Access Levels","ACCESS",
"[CLEANUP] Delete Everything","CLEANUP"
];

list REZ_DIALOG = [
    "[REZ_C] Creates a Column","REZ_C",
    "[REZ_T] Creates a Torus","REZ_T"
];

list RENDER_DIALOG = 
[
"[ENCLOSER] Rez an encloser.","ENCLOSER",
"[RENDER] Render the sculpt under the encloser.","RENDER",
"[SMOOTH] Change the smoothing parameter","SMOOTH"
];

list TOOLS_DIALOG =
[
"[SHOW] Shows all slices and verts","SHOW",
"[HIDE] Hides all slices and verts","HIDE",
"[COPY] Create Copy Tool","COPY",
"[MIRROR] Create Node Mirror Tool","MIRROR"
];

list ACCESS_DIALOG =
[
    "[EVERYONE] Everyone can use this","EVERYONE",
    "[GROUP] Group-members can you this","GROUP",
    "[OWNER] Only Owner can use this","OWNER"
];

list SPLINE_DIALOG =
[
    "[BEZ STOP] Stops slices from following the spline","BEZ STOP",
    "[BEZ START] Lets slices follow the bezier curve","BEZ START",
    "[ADD CTRL] Adds a control point","ADD CTRL",
    "[DEL CTRL] Deletes the last control point","DEL CTRL",
    "[BEZ SCALE] Scale slices along the bezier","BEZ SCALE",
    "[BEZ ROT] Rotate slices along the bezier","BEZ ROT",
    "[STOP SCALE] Stop scaling slices","STOP SCALE",
    "[STOP ROT] Stop rotating slices","STOP ROT"
];

list SMOOTH_DIALOG =
[
    "[NONE] No smoothing, use raw vertex data","NONE",
    "[LINEAR] Blurs the image slightly to smooth out bumps","LINEAR",
    "[GAUSSIAN] Blurs the image, but preserves some finer details","GAUSSIAN"
];

list RESOLUTIONS =
[
    "32x32",<32,32,0>,
    "16x16",<16,16,0>,
    "8x8",<8,8,0>,
    "64x16",<64,16,0>,
    "128x8",<128,8,0>,
    "256x4",<256,4,0>,
    "16x64",<16,64,0>,
    "8x128",<8,128,0>,
    "4x256",<4,256,0>
];

list ACCESS_LEVELS = [
"OWNER",2,
"GROUP",1,
"EVERYONE",0
];

string  NODE_NAME = "sculpt";
string  CONTROL_NAME = "control";
integer BROADCAST_CHANNEL;
integer COMMON_CHANNEL = -2101; //War was begining
integer CHANNEL_MASK = 0xFFFFFF00;
integer CONTROL_POINT_MASK = 0xFF;
integer DIALOG_CHANNEL  = 4209249;
integer ENCLOSE_CHANNEL;
integer RESOLUTION_CHANNEL = 123913;
integer MAX_NODES       = 32;
integer ENCLOSED        = FALSE;
string  URL;            //Set Via Notecard
integer ACCESS_LEVEL    = 2;
integer COLUMNS         = 32;
//-- Globals --//
key gCurrentKey;
key gDataserverRequest;
key gHTTPRequest;
string gBlurType = "none";
integer gHasRezed;
integer gRenderOnDataserver;
integer gToolRez;
vector gEncloseScale = ZERO_VECTOR;
vector gEnclosePos = ZERO_VECTOR;
integer gListenHandle_Broadcast;
integer gListenHandle_Enclose;         //Listen for Nodes
integer gListenHandle_Agent;         //Avatar listen callback
integer gListenHandle_Errors;        //Render Errors
integer gListenHandle_Success;        //Render Success
integer n;


vector bbox_lower;
vector bbox_higher;

//-- FUNCTIONS --//

rezSculptNodes(integer i)
{
    gEncloseScale = ZERO_VECTOR;
    gEnclosePos = ZERO_VECTOR;
    llRegionSay(BROADCAST_CHANNEL,"#die#");
    list params;
    if(i == 1) {
        params = [13,MAX_NODES,CONTROL_NAME,NODE_NAME,1];
    } else {
        params = [2,MAX_NODES,CONTROL_NAME,NODE_NAME,0];
    }
    llMessageLinked(LINK_THIS,BROADCAST_CHANNEL,llList2CSV(params),"#rez#");
}

announceSetupParams()
{
    llShout(BROADCAST_CHANNEL,"#setup#" + llList2CSV([COLUMNS,ACCESS_LEVEL,MAX_NODES]));
}

//Starts the Rendering Process by announcing and waiting
//for replies.  Once all replies are in, a final request
//is sent that informs the server to compile the image.
render()
{
    n = 0;
    llListenRemove(gListenHandle_Errors);
    llListenRemove(gListenHandle_Success);
    gListenHandle_Errors = llListen(-2002,"","","");
    gListenHandle_Success = llListen(-2001,"","","");
    llShout(BROADCAST_CHANNEL,"#render#"+URL);
}



dialog(string message, list dialog, key id, integer channel)
{
    gListenHandle_Agent = llListen(channel,"",id,"");
    string m = message + llDumpList2String( llList2ListStrided(dialog,0,-1,2) , "\n");
    llDialog(id,m,llList2ListStrided( llDeleteSubList(dialog,0,0), 0,-1,2),channel);
}

//Get Access Allowed/Denited
integer has_access(key agent)
{
    //Everyone has access
    if(ACCESS_LEVEL == 0) return TRUE;
    else
    //Owner has access
    if(ACCESS_LEVEL == 2)
    {
        return agent == llGetOwner();
    }
    else
    //Group has access
    if(ACCESS_LEVEL == 1)
    {
        return llSameGroup(agent);
    }
    //Failed
    return FALSE;
}

//-- STATES --//

default
{
    state_entry()
    {
        BROADCAST_CHANNEL = (-(integer)(llFrand(1e+6) + 1e+6)) & CHANNEL_MASK;
        llListen(BROADCAST_CHANNEL,"","","");
        llListen(COMMON_CHANNEL,"","","");
    }
    on_rez(integer p){
        llResetScript();
    }
    listen(integer c, string st, key id, string m)
    {
    	if(!has_access(id)) return;
    	
        if( c == BROADCAST_CHANNEL)
        {
            if(llSubStringIndex(m,"#enc-size#") == 0)
            {
                list enc = llCSV2List(llGetSubString(m,10,-1));
                gEnclosePos = (vector)llList2String(enc,0);
                gEncloseScale = (vector)llList2String(enc,1);
            }
        }
        if( c == DIALOG_CHANNEL ) {
            llListenRemove(gListenHandle_Agent);
            //--- SUB MENUS ---///
            if (m == "RENDERING") 
            {
                dialog("Choose an action:\n",RENDER_DIALOG,id,DIALOG_CHANNEL);
                return;
            }
            if (m == "RESOLUTION") 
            {
                gListenHandle_Agent = llListen(RESOLUTION_CHANNEL,"",id,"");
                llDialog(id,"Pick a resolution",llList2ListStrided(RESOLUTIONS,0,-1,2),RESOLUTION_CHANNEL);
                return;
            }
            if (m == "SMOOTH")
            {
                dialog("Pick a smoothing option\n",SMOOTH_DIALOG,id,DIALOG_CHANNEL);
                return;
            }
            if (m == "SPLINE")
            {
                dialog("Pick a SPLINE action:\n",SPLINE_DIALOG,id,DIALOG_CHANNEL);  
                return;
            }
            if (m == "TOOLS")
            {
                dialog("Choose an action:\n",TOOLS_DIALOG,id,DIALOG_CHANNEL);
                return;
            }
            if (m == "ACCESS")
            {
                dialog("Choose an access level:\n",ACCESS_DIALOG,id,DIALOG_CHANNEL);
                return;
            }
            // - REZ BUTTON - //
            if (m == "REZ")
            {
                if(!gHasRezed) dialog("Choose a rez mode:\n",REZ_DIALOG,id,DIALOG_CHANNEL);
                else llDialog(id,"Cannot rez new cuts when cuts are already out.\nPlease use the CLEANUP button first",[],-1);
                return;
            }
            // - REZ BUTTON - //
            if (m == "REZ_T"){
                if(gHasRezed) return;
                llShout(BROADCAST_CHANNEL,"#die#");
                rezSculptNodes(1);
                return;
            }
            // - REZ BUTTON - //
            if (m == "REZ_C"){
                if(gHasRezed) return;
                llShout(BROADCAST_CHANNEL,"#die#");
                rezSculptNodes(0);
                return;
            }
            if (m == "CLEANUP")
            {
                list d = [
                    "[DELETE] Yes, Delete everything","DELETE",
                    "[CANCEL] No way! Get me the hell out of here!","CANCEL"
                ];
                dialog("Are you sure you want to clean up? This will delete everything!\n",d,id,DIALOG_CHANNEL);
                return;
            }
            if ( m == "DELETE" )
            {
                llRegionSay(BROADCAST_CHANNEL,"#die#");
                gHasRezed = FALSE;
            }
            // - RENDER MENU - //
            if (m == "ENCLOSER"){
                list d = llGetObjectDetails(id,[OBJECT_POS,OBJECT_ROT]);
                vector pos = llList2Vector(d,0) + llRot2Fwd(llList2Rot(d,1))*2;
                llRegionSay(BROADCAST_CHANNEL,"#enc-die#");
                gToolRez = TRUE;
                llRezObject("Enclose Tool",llGetPos(),ZERO_VECTOR,ZERO_ROTATION,BROADCAST_CHANNEL);
            }
            if (m == "RENDER"){
                if(gEncloseScale != ZERO_VECTOR) {
                    gCurrentKey=id;
                    gRenderOnDataserver = TRUE;
                    gDataserverRequest = llGetNotecardLine("OpenLoft URL",0);
                } else {
                    llOwnerSay("You must first ENCLOSE the sculpt before you can render it");
                }
                return;
            }            
            // - TOOLS MENU - //   
            if( m == "SHOW" || m == "HIDE") {
                llShout(BROADCAST_CHANNEL,"#" +llToLower(m)+"#");
                return;
            }         
            if (m == "MIRROR") {
                list d = llGetObjectDetails(id,[OBJECT_POS,OBJECT_ROT]);
                vector pos = llList2Vector(d,0) + llRot2Fwd(llList2Rot(d,1))*2;
                gToolRez = TRUE;
                llRezObject("Mirror Tool",pos,ZERO_VECTOR,ZERO_ROTATION,BROADCAST_CHANNEL);
            }
            if (m == "COPY") {
                list d = llGetObjectDetails(id,[OBJECT_POS,OBJECT_ROT]);
                vector pos = llList2Vector(d,0) + llRot2Fwd(llList2Rot(d,1))*2;
                gToolRez = TRUE;
                llRezObject("Node Tool",pos,ZERO_VECTOR,llEuler2Rot(<-PI_BY_TWO,0,0>),BROADCAST_CHANNEL);
            }            
            // - SMOOTH MENU - //
            if (m == "LINEAR" || m== "GAUSSIAN" || m =="NONE"){
                gBlurType = llToLower(m);
                return;
            }
            // - SPLINE MENU -- //
            if( m == "ADD CTRL")
            {
                llMessageLinked(LINK_THIS,BROADCAST_CHANNEL,"","#add_control#");
                return;
            }
            if( m == "DEL CTRL")
            {
                llMessageLinked(LINK_THIS,BROADCAST_CHANNEL,"","#remove_control#");
                return;
            }
            if( m == "BEZ STOP")
            {
                llShout(BROADCAST_CHANNEL,"#bezier-stop#");                
                return;
            }
            if( m == "BEZ START")
            {
                llShout(BROADCAST_CHANNEL,"#bezier-start#");    
                return;
            }
            if( m == "BEZ SCALE" )
            {
                llShout(BROADCAST_CHANNEL,"#bez-caps#" + llList2CSV(["scale",1]));
                return;
            }
            if( m == "STOP SCALE" )
            {
                llShout(BROADCAST_CHANNEL,"#bez-caps#" + llList2CSV(["scale",0]));
                return;
            }
            if( m == "BEZ ROT" )
            {
                llShout(BROADCAST_CHANNEL,"#bez-caps#" + llList2CSV(["rot",1]));
                return;
            }
            if( m == "STOP ROT" )
            {
                llShout(BROADCAST_CHANNEL,"#bez-caps#" + llList2CSV(["rot",0]));
                return;
            }

            // - ACCESS LEVELS -
            integer ac = llListFindList(ACCESS_LEVELS,[m]);
            if (ac != -1 ) {
                ACCESS_LEVEL = llList2Integer(ACCESS_LEVELS,ac+1);
                announceSetupParams();
                return;
            }
        }
        if( c == RESOLUTION_CHANNEL)
        {
            llListenRemove(gListenHandle_Agent);
            integer i = llListFindList(RESOLUTIONS,[m]);
            if(i != -1)
            {
                vector v = llList2Vector(RESOLUTIONS,i+1);
                MAX_NODES = (integer)v.x;
                COLUMNS = (integer)v.y;
            }
        }

        //Successful Upload Responses
        if( c == -2001 ) {
            ++n;
            float t = (float)n/MAX_NODES;
            llSetText("Render Progress : " + (string)llCeil(t*100) + "%",<1,1,0>,1.0);
            llSetColor(<1,0,0>*(1-t) + <0,1,0>*(t),ALL_SIDES);
            if( n == MAX_NODES ) {
                if(URL != "" && URL != "none") {
                    gHTTPRequest = llHTTPRequest(URL + "action=render",HTTP_PARAMS,
                        "scale=" + llEscapeURL((string)gEncloseScale) +
                        "&org=" + llEscapeURL((string)gEnclosePos) +
                        "&smooth=" + gBlurType +
                        "&w=" + (string)COLUMNS +
                        "&h=" + (string)MAX_NODES
                    );
                }
                llSetColor(<1,1,1>,ALL_SIDES);
                llSetText("",ZERO_VECTOR,0.0);
            }
        }
        //Errored Responses
        if( c == -2002 ) {
            llOwnerSay("Error on row " + m);
        }
        if( c == COMMON_CHANNEL)
        {
        	if(m == "#send-bcast#") llRegionSay(COMMON_CHANNEL,"#bcast#" + (string)BROADCAST_CHANNEL);
        }
    }

    link_message(integer sn, integer n, string s, key id)
    {
        //Done Rezing
        if( id == "#rez_fin#" )
        {
        	gHasRezed = TRUE;
            gDataserverRequest = llGetNotecardLine("OpenLoft URL",0);
        }
    }

    touch_start(integer total_number)
    {
        if(!has_access(llDetectedKey(0))) return;
        dialog("Choose an action:\n",MAIN_DIALOG,llDetectedKey(0),DIALOG_CHANNEL);
    }

    dataserver( key request_id, string data)
    {
        if( gDataserverRequest == request_id) {
            URL = data;
            if( URL != "URL HERE") {
                if(llSubStringIndex(URL,"?") == -1) URL = URL + "?";
            } else {
                llOwnerSay("You must replace the url in the 'OpenLoft URL' notecard");
                URL = "none";
            }
            if(gRenderOnDataserver) 
            {
                gRenderOnDataserver = FALSE;
                render();
            }
            announceSetupParams();
        }
    }
    
    object_rez(key id)
    {
        if(gToolRez)
        {
            announceSetupParams();
            gToolRez = FALSE;
        }
    }

    //This is here simply to echo the links that the server replies with
    http_response( key request_id, integer status, list meta, string data)
    {
        if(gHTTPRequest != request_id) return;
        if( status == 200 ) { //OK
            if( llStringTrim(data,STRING_TRIM) != "" )
                llInstantMessage(gCurrentKey,data);
        } else {
                llInstantMessage(gCurrentKey,"Server Error: " + (string)status + "\n" + llList2CSV(meta) + "\n" + data);
        }
    }
}