integer DISPLAY_CHANNEL	 = -131415;
integer DATA_CHANNEL		 = 0;
key target;
integer gListenHandle;

list prims = [
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,
	0,0,0,0,0,0,0						
];

list faces = [3,7,4,6,1];
vector scale;
vector orig;

set_color(integer x, integer y, vector color)
{
	integer prim = llFloor(x/5) + (31-y)*7;
	integer face = x % 5;
		
	color = color - orig;
	
	color.x /= scale.x;
	color.y /= scale.y;
	color.z /= scale.z;
				 
	color.x = llFloor(127*color.x) + 128;
	color.y = llFloor(127*color.y) + 128;
	color.z = llFloor(127*color.z) + 128; 
	
	   
	
	if(color.x > 255) color.x = 255;
	if(color.y > 255) color.y = 255;
	if(color.z > 255) color.z = 255;
	
	if(color.x < 0) color.x = 0;
	if(color.y < 0) color.y = 0;
	if(color.z < 0) color.z = 0;
	
	llSetLinkColor( llList2Integer(prims,prim), (color / 255), llList2Integer(faces,face));
	
//llMessageLinked(LINK_THIS, llList2Integer(prims,prim), (string)(color / 255) , (string)llList2Integer(faces,face));
}

default
{
	state_entry()
	{
		

		integer num = llGetNumberOfPrims();
		integer i;
		list l;
		integer r;
		for( i = 2; i <= num; ++i)
		{
			l = llParseString2List( llGetLinkName(i) , ["-"],[] );
			if( llList2String(l,0) == "xyzzytext" ) 
			{																								 
				r = llList2Integer(l,1)*7 + llList2Integer(l,2);
				prims = llListReplaceList(prims,[i],r,r);
			}
		}
		llOwnerSay("Setup Complete");
		
	}
	touch_start(integer i)
	{
		string name = llGetLinkName(llDetectedLinkNumber(0));
		if(name == "start")
		{
			DATA_CHANNEL = 1 + (integer)llFrand(-(DEBUG_CHANNEL-100));
			llListenRemove(gListenHandle);
			gListenHandle = llListen(DATA_CHANNEL,"","","");
			llSay(DISPLAY_CHANNEL,(string)DATA_CHANNEL);
			llSensor("Open Loft Tool","",SCRIPTED,40,PI);
			llOwnerSay("Using This Grid");						 
		}
		if(name == "stop")
		{
			llListenRemove(gListenHandle);
			llSay(DISPLAY_CHANNEL,"0");
			DATA_CHANNEL = 0;
			llOwnerSay("Using URL Notecard");
		}
	}
	sensor(integer i)
	{
		if( llGetOwnerKey(llDetectedKey(0)) == llGetOwner() )
		{
			target = llDetectedKey(0);
		}
	}
	listen(integer channel, string name, key id, string message)
	{
		if( llSubStringIndex(name,"sculpt") != -1) {
			orig = llList2Vector(llGetObjectDetails(target,[OBJECT_POS]),0);
			list l = llGetBoundingBox(target);
			scale = (llList2Vector(l,1) - llList2Vector(l,0)) * .5;
						
			integer i = 0;
			l = llCSV2List(message);
			vector color;
			integer len = llGetListLength(l);			
			integer POINT = ( len == 1);
			integer r = (integer)llGetSubString(name,7,-1);
			integer c = 0;

			if( POINT )  
			{
				c = 0;
				len = 32;
				color = (vector)llList2String(l,0);			
			} else {
				c = llList2Integer(l,0);
				l = llDeleteSubList(l,0,0);
			}
					 
			while(len > 1)
			{
				if( !POINT ) {
					color = (vector)llList2String(l,i);
					++i;
				}
				set_color(c,r,color);
				--len;
				++c;
			}
		}
	}
}

