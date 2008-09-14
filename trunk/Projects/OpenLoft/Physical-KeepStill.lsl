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


//Makes the object physical
//And keeps it in place
vector pos;
rotation rot;
default
{
	state_entry()
	{
		//Make Physical
		llSetStatus(STATUS_PHYSICS,TRUE);
		
		//Save Position
		pos = llGetPos();
		rot = llGetRot();
		
		llSetTimerEvent(0.05);
	}
	timer()
	{
		//Jitter
		llApplyImpulse(<1,1,1>*0.001,TRUE);
		
		//Keep In Place
		llMoveToTarget(pos,0.1);
		llRotLookAt(rot,100,0.1);		
	}
}

