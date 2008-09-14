//Linked Prim Animator Lite - Rotation
//Author: Falados Kapuskas
//Version: 0.7
//Date: 2007/12/30
//Description: 
//	Records changes in rotation

//Global Vars
integer SCRIPT_PIN = 3014;
list frames = [];   //A list of frames that were recorded (Unordered)
list quants = []; // A list parrallel to the frames list which contains the quantities


integer last_frame; //Last frame that was touched (For reference)
//---- ADDITIONAL FUNCTIONS ----//

//---- SNAPSHOT QUANTITY ----//
//==== Rotation ====//

//<<Change this type to the stored quantity type>>
rotation last_quant;

//Function:	new_quant
//Description:	Compares the quantity to the new current quantity
//		Returns TRUE if they are different, False if they are not
integer new_quant(rotation lq) {
	
	last_quant = llGetLocalRot();
	if( lq != last_quant )
		return TRUE;
	return FALSE;

}
//Function:	new_quant
//Description:	Compares the quantity to the new current quantity
//		Returns TRUE if they are different, False if they are not
store_quant(integer frame) {
	
	last_frame = frame;
	integer index = llListFindList( frames, [frame]);
	if( index == -1 ) {
		frames += frame;
		quants += last_quant;
	} else {
			quants = llListReplaceList(quants,[last_quant],index,index);
	}

}
//Function:	set_quant
//Description:	Sets the primitive to the attribute stored at frame
//		Returns TRUE if the frame is found, FALSE otherwise (and no change is made)
integer set_quant( integer frame ) {
	
	integer index = llListFindList( frames, [frame]);
	if( index != -1 ) {
		last_quant = llList2Rot( quants, index );
		llSetLocalRot( last_quant );
		return TRUE;
	}
	return FALSE;

}

//---- END SNAPSHOT QUANTITY ----//

default
{
	state_entry()
	{
		new_quant(ZERO_ROTATION);
		store_quant(0); //Store starting frame
		state capture;
	}

}

//---- COMMON STATES ----//

state capture {
	link_message( integer sender_num, integer num, string str, key id )
	{
		if( id == "loader") {
			if( str == llGetScriptName() ) {
				llRemoteLoadScriptPin( llGetLinkKey(num) , str, SCRIPT_PIN , TRUE, TRUE );
			}
		}
		if( id == "root" ) {
			//Capture Snapshot
			if( str == "cap" ) {
				if( new_quant( last_quant ) ) {
					store_quant( num );   
				}
			}
			if( str == "rwd" ) {
				last_frame = num;
				while(!set_quant(last_frame) && last_frame > 0) { --last_frame; }
			}
			if( str == "ff" ) {
				last_frame = num;
				set_quant(last_frame);
			}
			if( str == "reset" ) {
				set_quant(0);
				store_quant(num);
			}
			//Go into playback mode
			if( str == "pb" ) {
				state playback;
			}
		}
	}
}

state playback
{
	state_entry() {
		if( llGetListLength( frames ) <= 1 ) { //This set only contains the null frame
			//Ditch this script
			llRemoveInventory(llGetScriptName());
		}  else {
			last_frame = llList2Integer(frames, llGetListLength(frames) - 1 );
		} 
	}
	link_message( integer sender_num, integer num, string str, key id )
	{
		if( id == "player") {
			if( str == "frame" ) 
			{
				while(!set_quant(num) && num != 0) {
					--num;
				}
				last_frame = num;
			}
		}
	}
}
