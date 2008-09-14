//Linked Prim Animator Lite - <<ATTRIBUTE>>
//Author: <<AUTHOR>>
//Version: <<VERSION>>
//Date: <<DATE>>
//Description: 
//	<<DESCRIPTION>>

//Global Vars
integer SCRIPT_PIN = 3014;
list frames = [];   //A list of frames that were recorded (Unordered)
list quants = []; // A list parrallel to the frames list which contains the quantities
<<ADDITIONAL GLOBALS>>

integer last_frame; //Last frame that was touched (For reference)
//---- ADDITIONAL FUNCTIONS ----//
<<ADDITIONAL FUNCTIONS>>
//---- SNAPSHOT QUANTITY ----//
//==== <<ATTRIBUTE>> ====//

//<<Change this type to the stored quantity type>>
<<TYPE>> last_quant;

//Function:	new_quant
//Description:	Compares the quantity to the new current quantity
//		Returns TRUE if they are different, False if they are not
integer new_quant(<<TYPE>> lq) {
	<<NEW_QUANT>>
}
//Function:	new_quant
//Description:	Compares the quantity to the new current quantity
//		Returns TRUE if they are different, False if they are not
store_quant(integer frame) {
	<<STORE_QUANT>>
}
//Function:	set_quant
//Description:	Sets the primitive to the attribute stored at frame
//		Returns TRUE if the frame is found, FALSE otherwise (and no change is made)
integer set_quant( integer frame ) {
	<<SET_QUANT>>
}

//---- END SNAPSHOT QUANTITY ----//

default
{
	state_entry()
	{
		new_quant(<<ZERO>>);
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
