vector focus;
vector cam_pos;
float dist = 4.8;
default
{
	state_entry()
	{
		llSetText("Sit Here",<0,1,0>,1.0);
		llSitTarget(<0,0,.01>,ZERO_ROTATION);	
	}
	changed(integer change) {
		if( change & CHANGED_LINK)
		{
			key av = llAvatarOnSitTarget();
			if(av != NULL_KEY)
			{
				if(av != llGetOwner()) 
				{
					llUnSit(av);
				} else {
					llRequestPermissions(av,PERMISSION_CONTROL_CAMERA|PERMISSION_TRACK_CAMERA);
				}
			}	
		}
	}
	run_time_permissions(integer perm)
	{
		if(!perm) return;
		focus = llGetRootPosition();
		cam_pos = focus + dist*<1,0,0>*llGetRot();  
		llClearCameraParams();   
		llSetCameraParams([
			CAMERA_ACTIVE,TRUE,
			CAMERA_BEHINDNESS_ANGLE, 0.0,
			CAMERA_FOCUS,focus,
			CAMERA_FOCUS_LOCKED, TRUE,
			CAMERA_POSITION,cam_pos,
			CAMERA_POSITION_LOCKED,TRUE,
			CAMERA_POSITION_THRESHOLD,0.0,
			CAMERA_FOCUS_THRESHOLD,0.0,
			CAMERA_FOCUS_LAG,0.0,
			CAMERA_PITCH,0.0
		]);
	}
}

