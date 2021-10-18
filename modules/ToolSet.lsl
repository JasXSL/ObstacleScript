#define USE_RUN_TIME_PERMISSIONS
#define USE_STATE_ENTRY
#define USE_ATTACH
#define USE_TIMER
#define USE_LISTEN
#include "ObstacleScript/resources/SubHelpers/GhostHelper.lsl"
#include "ObstacleScript/index.lsl"


integer BFL;
#define BFL_USING 0x1   // Using an item

// Equipped tools
integer ACTIVE_TOOL;    // index of stride in TOOLS. Use activeType for type
// (int)tool, (var)setting, (key)id
list TOOLS;
#define TOOLSTRIDE 3
#define TTEMPLATE (list)0 + 0 + 0    // Empty slot

#define activeType() l2i(TOOLS, ACTIVE_TOOL*TOOLSTRIDE)

#define PP llSetLinkPrimitiveParamsFast
#define AL llSetLinkAlpha

#define getActiveToolInt() l2i(TOOLS, ACTIVE_TOOL*TOOLSTRIDE+1)
#define getActiveToolStr() l2s(TOOLS, ACTIVE_TOOL*TOOLSTRIDE+1)
#define getActiveToolWorldId() l2k(TOOLS, ACTIVE_TOOL*TOOLSTRIDE+2)
#define getActiveToolList() llList2List(TOOLS, ACTIVE_TOOL*TOOLSTRIDE+1, ACTIVE_TOOL*TOOLSTRIDE+1)
// Raises active tool event
#define sendActiveTool( tool ) raiseEvent(ToolSetEvt$activeTool, tool + getActiveToolList())
// Accepts one argument, can be any type. Lists passed must be JSON encoded
#define setActiveToolVal( val ) TOOLS = llListReplaceList(TOOLS, (list)(val), ACTIVE_TOOL*TOOLSTRIDE+1, ACTIVE_TOOL*TOOLSTRIDE+1)

integer P_OWOMETER;
integer P_FLASHLIGHT;
integer P_FLASHLIGHTBEAM;
integer P_HOTS;
integer P_HOTSBALL;
integer P_ECCHISKETCH;
integer P_SPIRITBOX;
integer P_SALT;
integer P_VAPE;
integer P_OUIJA;
integer P_PLANCHETTE;
integer P_PILLS;
integer P_PIR;
integer P_PIR_CAN;
integer P_BAT;
integer P_GSTICK;
integer P_PARA;
integer P_PARAMON;
integer P_CAM;
integer P_THERMO;


vector SOUND_SPOT;
float SOUND_TIME;
float TEMP_TIME;
integer TEMPERATURE;

string curAnim;




// Attachment data received for the active asset
onDataUpdate(){
    
    integer tool = activeType();
    integer on = getActiveToolInt();
	
    if( tool == ToolsetConst$types$ghost$flashlight ){

        PP(
            P_FLASHLIGHTBEAM, 
            GhostHelper$flashlightSettings
        );
        PP(
            P_FLASHLIGHT,
            (list)PRIM_FULLBRIGHT + 2 + on + PRIM_GLOW + 2 + on*0.5
        );
        
    }
    else if( tool == ToolsetConst$types$ghost$ecchisketch ){
        
        AL(P_ECCHISKETCH, on, 4);
        if( on ){
            
            --on;
            PP(
                P_ECCHISKETCH, 
                (list)PRIM_TEXTURE + 4 + "9b2f4cf3-2796-4a6a-e5f4-0b93693c86aa" + <.5, .5, 0> + <-.25+(on%2)*.5, .25-(on/2)*.5, 0> + 0
            );
            
        }
        
    }
    else if( tool == ToolsetConst$types$ghost$glowstick )
        onTick();
    else if( tool == ToolsetConst$types$ghost$parabolic ){
        
        PP( P_PARAMON, (list)
            PRIM_COLOR + 4 + ZERO_VECTOR + on +
            PRIM_COLOR + 5 + ZERO_VECTOR + on +
            PRIM_COLOR + 6 + ZERO_VECTOR + on +
            PRIM_COLOR + 7 + ZERO_VECTOR + on +
            PRIM_FULLBRIGHT + 3 + on
        );
        onTick();
        
    }
	else if( tool == ToolsetConst$types$ghost$camera ){
		
		integer pics = GhostHelper$CAM_MAX_PICS-on;
		if( pics < 0 )
			pics = 0;
			
		PP( P_CAM, (list)
			PRIM_TEXTURE + 4 + "2aaf7eb6-4ebb-52da-b32a-7e2d4d45c73d" + <0.06250,0.7,0> + <-0.46875+0.0625*pics,0,0> + 0
		);
		
	}
    else if( tool == ToolsetConst$types$ghost$thermometer ){
	
		integer f = getActiveToolInt();
		llSetLinkPrimitiveParamsFast(P_THERMO, (list)
			PRIM_TEXTURE + 6 + "2aaf7eb6-4ebb-52da-b32a-7e2d4d45c73d" + <1.0/16, 1, 0> + <-0.46875+.0625*(14-f*2), 0, 0> + 0
		);
		TEMP_TIME = 0;
		onTick();
		
	}    
    
    sendActiveTool(tool);
    
}


// Draws the currently active tool
drawActiveTool(){
    
    integer tool = activeType();
    list remFullbright = (list)PRIM_GLOW + ALL_SIDES + 0 + PRIM_FULLBRIGHT + ALL_SIDES + 0;
    list remLight = (list)PRIM_POINT_LIGHT + FALSE + <1.000, 0.928, 0.710> + 1 + 4 + 1;

    // Owometer
    AL(P_OWOMETER, tool == ToolsetConst$types$ghost$owometer, ALL_SIDES);
    if( tool != ToolsetConst$types$ghost$owometer )
        PP(P_OWOMETER, remFullbright);
    
    // Flashlight
    AL(P_FLASHLIGHT, tool == ToolsetConst$types$ghost$flashlight, ALL_SIDES);
    PP(P_FLASHLIGHT, remFullbright);
    PP(P_FLASHLIGHTBEAM, remLight);

    // HOTS
    AL(P_HOTS, tool == ToolsetConst$types$ghost$hots, ALL_SIDES);
    AL(P_HOTSBALL, tool == ToolsetConst$types$ghost$hots , ALL_SIDES);
    AL(P_ECCHISKETCH, tool == ToolsetConst$types$ghost$ecchisketch, ALL_SIDES);
    AL(P_SPIRITBOX, tool == ToolsetConst$types$ghost$spiritbox, ALL_SIDES);
    AL(P_SPIRITBOX, 0, 4);
    AL(P_SALT, tool == ToolsetConst$types$ghost$salt, ALL_SIDES);
    AL(P_VAPE, tool == ToolsetConst$types$ghost$vape, ALL_SIDES);
    AL(P_OUIJA, tool == ToolsetConst$types$ghost$weegieboard, ALL_SIDES);
	AL(P_PLANCHETTE, 0, ALL_SIDES);
    AL(P_PILLS, tool == ToolsetConst$types$ghost$pills, ALL_SIDES);
    AL(P_PIR, tool == ToolsetConst$types$ghost$motionDetector, ALL_SIDES);
    AL(P_PIR_CAN, tool == ToolsetConst$types$ghost$motionDetector, ALL_SIDES);
    AL(P_BAT, tool == ToolsetConst$types$ghost$hornybat, ALL_SIDES);
    AL(P_GSTICK, tool == ToolsetConst$types$ghost$glowstick, ALL_SIDES);
    PP(P_GSTICK, remFullbright + remLight);
    
    AL(P_PARAMON, tool == ToolsetConst$types$ghost$parabolic, ALL_SIDES);
    AL(P_PARA, tool == ToolsetConst$types$ghost$parabolic, ALL_SIDES);
    AL(P_PARA, (tool == ToolsetConst$types$ghost$parabolic)*.5, 1);
    AL(P_CAM, tool == ToolsetConst$types$ghost$camera, ALL_SIDES);
    AL(P_THERMO, tool == ToolsetConst$types$ghost$thermometer, ALL_SIDES);
    

    onDataUpdate();
    
    string anim;
    if( llGetPermissions()&PERMISSION_TRIGGER_ANIMATION ){
        
        if( tool ){
            anim = "default_hold";
            
            if( tool == ToolsetConst$types$ghost$parabolic )
                anim = "paramic_hold";
            else if( tool == ToolsetConst$types$ghost$camera )
                anim = "camera_hold";
            else if( tool == ToolsetConst$types$ghost$thermometer )
                anim = "thermometer_hold";
			else if( tool == ToolsetConst$types$ghost$hornybat )
				anim = "bat_idle";
            
        }
            
        
        if( curAnim != anim ){
            
            if( curAnim )
                llStopAnimation(curAnim);
            if( anim )
                llStartAnimation(anim);
            
            curAnim = anim;
        } 

    }
        
    
}


onTick(){
    
    integer type = activeType();
    integer toolInt = getActiveToolInt();
    if( type == ToolsetConst$types$ghost$glowstick && toolInt )
        PP(P_GSTICK, GhostHelper$getGlowstickSettings( toolInt ));
    else if( type == ToolsetConst$types$ghost$parabolic ){
        
        key texture = "87aea93e-75df-8a53-a016-7e0497530e19";
        float between;
        
        if( SOUND_TIME > 0 && llGetTime()-SOUND_TIME < 6 ){
            
            vector pos = SOUND_SPOT;
            
            vector temp = (pos-llGetCameraPos())/llGetCameraRot(); 
            between = 1.0 - llFabs(llAtan2(temp.y,temp.x))/PI;
            between = llPow(between, 3);
            float dist = llVecDist(pos, llGetRootPosition());
            between *= (1.0-dist/10.0);
            if( between < 0 )
                between = 0;
            
            between *= 70;
            
        }
        
        string text = (string)between;
        integer p = llSubStringIndex(text, ".");
        text = llGetSubString(text, 0, p+1);
        if( between < 10 )
            text = "0"+text;
        
        PP( P_PARAMON, (list)
            PRIM_TEXTURE + 4 + texture + <0.0625,1,0> + <-0.46875+0.0625*(float)llGetSubString(text,0,0),0,0> + 0 +
            PRIM_TEXTURE + 5 + texture + <0.0625,1,0> + <-0.46875+0.0625*(float)llGetSubString(text,1,1),0,0> + 0 +
            PRIM_TEXTURE + 7 + texture + <0.0625,1,0> + <-0.46875+0.0625*(float)llGetSubString(text,-1,-1),0,0> + 0
        );
        
    }
	else if( type == ToolsetConst$types$ghost$thermometer && llGetTime()-TEMP_TIME > 2 ){
	
		// Request a reading
		TEMP_TIME = llGetTime();
		Nodes$getTempQuick( ToolSetMethod$temp );
	
	}
        
}


integer addTool( integer tool, list data, key id ){
    
    if( !count(data) )
        data = [0];
    
    integer i;
    for( ; i < count(TOOLS); i += TOOLSTRIDE ){
        
        integer n = (i+ACTIVE_TOOL*TOOLSTRIDE) % count(TOOLS);
        
        integer type = l2i(TOOLS, n);
        if( !type ){
            
            // Attach it here
            TOOLS = llListReplaceList(TOOLS, (list)tool + llList2List(data, 0, 0) + id, n, n+TOOLSTRIDE-1);
            
            if( n == ACTIVE_TOOL*TOOLSTRIDE )
                drawActiveTool();
				
			if( tool == ToolsetConst$types$ghost$motionDetector ){
				Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, id + 0 );
			}
            return TRUE;
            
        }
        
    }
    
    return FALSE;
}

removeToolById( key id ){
	
	integer pos = llListFindList(TOOLS, (list)id);
	if( pos == -1 )
		return;
		
	TOOLS = llListReplaceList(TOOLS, TTEMPLATE, pos-(TOOLSTRIDE-1), pos);
	drawActiveTool();
    
}


// Raycasts for a placement pos, returns empty on fail
// If wall is TRUE it only allows placement on vertical objects
// Otherwise it only allows horizontal
// Returns (vec)pos, (vec)normal
list getRcPlacement( integer wall ){
	
	rotation fwd = llGetRootRotation();
	vector base = llGetRootPosition()+<0,0,.5>;
	if( llGetPermissions() & PERMISSION_TRACK_CAMERA ){
		
		fwd = llGetCameraRot();
		if( llGetAgentInfo(llGetOwner()) & AGENT_MOUSELOOK )
			base = llGetCameraPos();
		
	}
	
	list ray = llCastRay(base, base+llRot2Fwd(fwd)*2.5, RC_DEFAULT + RC_DATA_FLAGS + RC_GET_NORMAL );
	if( l2i(ray, -1) < 1 )
		return [];
		
	vector n = l2v(ray, 2);
	if( (n.z < .95 && !wall) || (wall && llFabs(n.z) > .05) )
		return [];
		
	return (list)l2v(ray, 1) + n;

}




#include "ObstacleScript/begin.lsl"


onAttach( id )
    llResetScript();
end

handleTimer( "T" )
	onTick();
end

onStateEntry()

    integer i;
    for(; i < ToolSetConst$MAX_ACTIVE; ++i )
        TOOLS += TTEMPLATE;
    
    forLink( nr, name )
        
        if( name == "OWOMETER" )
            P_OWOMETER = nr;
        else if( name == "FLASHLIGHT" )
            P_FLASHLIGHT = nr;
        else if( name == "FLASHLIGHTBEAM" )
            P_FLASHLIGHTBEAM = nr;
        else if( name == "HOTS" )
            P_HOTS = nr;
        else if( name == "HOTSBALL" )
            P_HOTSBALL = nr;
        else if( name == "ECCHISKETCH" )
            P_ECCHISKETCH = nr;
        else if( name == "SPIRITBOX" )
            P_SPIRITBOX = nr;
        else if( name == "SALT" )
            P_SALT = nr;
        else if( name == "VAPE" )
            P_VAPE = nr;
        else if( name == "OUIJA" )
            P_OUIJA = nr;
        else if( name == "PILLS" )
            P_PILLS = nr;
        else if( name == "PIR" )
            P_PIR = nr;
        else if( name == "PIR_CAN" )
            P_PIR_CAN = nr;
        else if( name == "BAT" )
            P_BAT = nr;
        else if( name == "GSTICK" )
            P_GSTICK = nr;
        else if( name == "PARA" )
            P_PARA = nr;
        else if( name == "PARAMON" )
            P_PARAMON = nr;
        else if( name == "CAM" )
            P_CAM = nr;
        else if( name == "THERMO" )
            P_THERMO = nr;
        else if( name == "PLANCHETTE" )
            P_PLANCHETTE = nr;
        
    end
    
    setInterval("T", 1);
    
    if( llGetAttached() )
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION|PERMISSION_TRACK_CAMERA);
    
    // Facelight
    PP(P_FLASHLIGHT, (list)PRIM_POINT_LIGHT + 1 + <1.000, 0.928, 0.710> + .1 + 1.5 + 2);
    
    llSetAlpha(0, ALL_SIDES);
    //addTool(ToolsetConst$types$ghost$flashlight, (list)0, "");
	//addTool(ToolsetConst$types$ghost$owometer, (list)0, "");
	//addTool(ToolsetConst$types$ghost$spiritbox, (list)1, "");
	
	#ifdef DEBUG_TOOL
	addTool(DEBUG_TOOL, (list)
		#ifdef DEBUG_TOOL_DATA
			DEBUG_TOOL_DATA
		#else
			0
		#endif
		, 
	"");
	#endif
	
    drawActiveTool();
	llListen(3, "", llGetOwner(), "");
	
	Level$raiseEvent( LevelCustomType$TOOLSET, LevelCustomEvt$TOOLSET$get, [] );    

end

// USE
onPortalLclickStarted( hud )

	integer tool = activeType();
    list toggled = (list)
        ToolsetConst$types$ghost$owometer +
        ToolsetConst$types$ghost$flashlight +
        ToolsetConst$types$ghost$spiritbox +
        ToolsetConst$types$ghost$parabolic +
		ToolsetConst$types$ghost$thermometer
    ;
    if( tool == ToolsetConst$types$ghost$glowstick ){
        
        if( getActiveToolInt() )
            return;
            
        setActiveToolVal(llGetUnixTime());
        onDataUpdate();
        Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + llGetUnixTime() );

    }
    
    if( ~llListFindList(toggled, (list)tool) ){
    
        integer v = !getActiveToolInt();
        setActiveToolVal(v);
        onDataUpdate();
        llTriggerSound("691cc796-7ed6-3cab-d6a6-7534aa4f15a9", .5);
        // Tell level
        Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + v );

        
    }
	
	if( tool == ToolsetConst$types$ghost$vape ){
        
        BFL = BFL|BFL_USING;
        setTimeout("USE", 3);
		setTimeout("DESTROY", 2.5);
				
    }
	
	if( tool == ToolsetConst$types$ghost$pills ){
        
        BFL = BFL|BFL_USING;
        setTimeout("USE", 3.5);
		Level$raiseEvent( LevelCustomType$TOOLSET, LevelCustomEvt$TOOLSET$pills, []);
		setTimeout("DESTROY", 3);
				
    }
	
	if( tool == ToolsetConst$types$ghost$camera ){
		
		int pics = getActiveToolInt();
		if( pics >= GhostHelper$CAM_MAX_PICS )
			return;
	
		++pics;
		setActiveToolVal(pics);
        onDataUpdate();
		
		Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + pics );
		Level$raiseEvent(LevelCustomType$TOOLSET, LevelCustomEvt$TOOLSET$camera, llGetCameraPos() + llGetCameraRot());
		
		BFL = BFL|BFL_USING;
		setTimeout("USE", 1);
	
	}
	
	if( tool == ToolsetConst$types$ghost$salt ){
			
		int ch = getActiveToolInt();
		if( ch >= GhostHelper$SALT_MAX_CHARGES )
			return;
			
		list rc = getRcPlacement(FALSE);
		if( rc == [] )
			return;
		
		vector norm = l2v(rc, 1);
		rotation r = llRotBetween(<0,0,1>, norm);

		++ch;
		setActiveToolVal(ch);
        onDataUpdate();
		Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + ch );
		Level$raiseEvent(LevelCustomType$TOOLSET, LevelCustomEvt$TOOLSET$salt, l2v(rc, 0) + r);
		
		BFL = BFL|BFL_USING;
		setTimeout("USE", 1);
		if( ch >= GhostHelper$SALT_MAX_CHARGES )
			setTimeout("DESTROY", 0.2);
			
		
	}
	
	if( tool == ToolsetConst$types$ghost$motionDetector ){
		
		list rc = getRcPlacement(TRUE);
		if( rc == [] )
			return;
			
		vector norm = l2v(rc, 1);
		rotation r = llRotBetween(<0,0,1>, norm);
		Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + 1 );
		BFL = BFL|BFL_USING;
		setTimeout("USE", 1);
		
		Level$raiseEvent( 
			LevelCustomType$TOOLSET, 
			LevelCustomEvt$TOOLSET$drop, 
			getActiveToolWorldId() + l2v(rc, 0) + r
		);
	
	}
	
	raiseEvent(ToolSetEvt$visual, tool);

end


onRunTimePermissions( perm )

    if( perm & PERMISSION_TRIGGER_ANIMATION )
        drawActiveTool();
    
end

// Hotkeys
onListen( ch, msg )
	
	if( ch != 3 )
		return;
	
	// Cycle asset
	if( msg == "sheathe" ){
		
		ACTIVE_TOOL = (ACTIVE_TOOL+1) % ToolSetConst$MAX_ACTIVE;
		
		drawActiveTool();
		
	}
	
	else if( msg == "Q" ){
	
		key id = getActiveToolWorldId();
		if( id == "" || BFL&BFL_USING )
			return;
			
		list rc = getRcPlacement(FALSE);
		if( rc == [] )
			return;
		
		vector vr = llRot2Euler(llGetRootRotation());
		vr = <0,0,vr.z>;
				
		Level$raiseEvent( 
			LevelCustomType$TOOLSET, 
			LevelCustomEvt$TOOLSET$drop, 
			id + l2v(rc, 0) + llEuler2Rot(vr)
		);
	
	}

end

handleMethod( ToolSetMethod$addTool )
	
	addTool(argInt(0), llList2List(METHOD_ARGS, 1, 1), argKey(2));
	
end

handleMethod( ToolSetMethod$remTool )
	
	removeToolById(argKey(0));
	
end

handleTimer( "USE" )

    BFL = BFL&~BFL_USING;

end

handleTimer( "DESTROY" )

	Level$raiseEvent( 
		LevelCustomType$TOOLSET, 
		LevelCustomEvt$TOOLSET$destroy, 
		getActiveToolWorldId()
	);

end

// External interactions on our handheld items
handleMethod( ToolSetMethod$trigger )
	
	if( BFL&BFL_USING )
        return;
		
	int tool = argInt(0);
	METHOD_ARGS = llDeleteSubList(METHOD_ARGS, 0, 0);

    if( tool == ToolsetConst$types$ghost$parabolic ){
        
        SOUND_SPOT = argVec(0);
        SOUND_TIME = llGetTime();
        if( activeType() == ToolsetConst$types$ghost$parabolic )
            Ghost$playSoundOnMe(SENDER_KEY);
        
    }
	// Negative ouija meant it was used
	else if( tool == -ToolsetConst$types$ghost$weegieboard )
		raiseEvent(ToolSetEvt$visual, tool + METHOD_ARGS);

    
end

handleMethod( ToolSetMethod$temp )

	float t = argFloat(0);
	t += llFrand(8)-6;
	
	if( getActiveToolInt() )
		t = (t * 9.0/5.0) + 32;
	str nr = (str)floor(t);
	while( llStringLength(nr) < 3 )
		nr = "0"+nr;
		
		
	list set;
	integer i;
	for(; i < 3; ++i ){
		
		set += (list)
			PRIM_TEXTURE +
			(3+i) +
			"2aaf7eb6-4ebb-52da-b32a-7e2d4d45c73d" +
			<1.0/16, 1, 0> + 
			<-0.46875+.0625*(int)llGetSubString(nr, i, i), 0, 0> + 
			0
		;
		
	}
	llSetLinkPrimitiveParamsFast(P_THERMO, set);
	
end


#include "ObstacleScript/end.lsl"





