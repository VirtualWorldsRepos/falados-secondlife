import Template as t
from datetime import date

def Gen():
	FILENAME = "../LPA Frame Capture (Position).lsl"
	TEMPLATE = "LPA Module Template.lsl"
	
	td = date.today()
	
	t.AddAttribute("ATTRIBUTE","Position")
	t.AddAttribute("AUTHOR","Falados Kapuskas")
	t.AddAttribute("VERSION","0.7");
	t.AddAttribute("DATE",str(td.year) + "/" + str(td.month) + "/" + str(td.day))
	t.AddAttribute("DESCRIPTION","Records changes in position")
	t.AddAttribute("TYPE","vector");
	t.AddAttribute("ZERO","ZERO_VECTOR");
	t.AddAttribute("ADDITIONAL GLOBALS","")
	t.AddAttribute("ADDITIONAL FUNCTIONS","")

	t.AddAttribute("NEW_QUANT","""
	last_quant = llGetLocalPos();
	if( lq != last_quant )
		return TRUE;
	return FALSE;
""")

	t.AddAttribute("STORE_QUANT","""
	last_frame = frame;
	integer index = llListFindList( frames, [frame]);
	if( index == -1 ) {
		frames += frame;
		quants += last_quant;
	} else {
			quants = llListReplaceList(quants,[last_quant],index,index);
	}
""")

	t.AddAttribute("SET_QUANT","""
	integer index = llListFindList( frames, [frame]);
	if( index != -1 ) {
		last_quant = llList2Vector( quants, index );
		llSetPos( last_quant );
		return TRUE;
	}
	return FALSE;
""")

	t.GenerateFile(TEMPLATE,FILENAME)

