/*
#define USE_RUN_TIME_PERMISSIONS
#define USE_STATE_ENTRY
#define USE_ATTACH
#define USE_TIMER
#define USE_LISTEN
*/
//#include "ObstacleScript/index.lsl"








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
    
    ini();
    
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

onPortalLclickStarted( hud )
    
	integer tool = activeType();
	list toggled = (list)
		ToolsetConst$types$ghost$owometer +
		ToolsetConst$types$ghost$flashlight +
		ToolsetConst$types$ghost$spiritbox
	;
	if( tool == ToolsetConst$types$ghost$glowstick ){
		
		if( getActiveToolInt() )
			return;
			
		setActiveToolVal(llGetUnixTime());
		onDataUpdate();
		// Todo: Animation and sound
		Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + llGetUnixTime() );
		return;
	}
	
	if( ~llListFindList(toggled, (list)tool) ){
	
		integer v = !getActiveToolInt();
		setActiveToolVal(v);
		onDataUpdate();
		llTriggerSound("691cc796-7ed6-3cab-d6a6-7534aa4f15a9", .5);
		// Tell level
		Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + v );
		return;
		
	}
	

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
		if( id == "" )
			return;
			
		rotation fwd = llGetRootRotation();
		vector base = llGetRootPosition()+<0,0,.5>;
		if( llGetPermissions() & PERMISSION_TRACK_CAMERA ){
			
			fwd = llGetCameraRot();
			if( llGetAgentInfo(llGetOwner()) & AGENT_MOUSELOOK )
				base = llGetCameraPos();
			
		}
		
		list ray = llCastRay(base, base+llRot2Fwd(fwd)*2.5, RC_DEFAULT + RC_DATA_FLAGS + RC_GET_NORMAL );
		if( l2i(ray, -1) < 1 )
			return;
			
		vector n = l2v(ray, 2);
		
		// Todo: Handle wall placed assets
		if( n.z < .9 )
			return;
		
		vector vr = llRot2Euler(fwd);
		vr = <0,0,vr.z>;
		
		Level$raiseEvent( 
			LevelCustomType$TOOLSET, 
			LevelCustomEvt$TOOLSET$drop, 
			id + l2v(ray, 1) + llEuler2Rot(vr)
		);
	
	}

end

handleMethod( ToolSetMethod$addTool )
	
	addTool(argInt(0), llList2List(METHOD_ARGS, 1, 1), argKey(2));
	
end

handleMethod( ToolSetMethod$remTool )
	
	removeToolById(argKey(0));
	
end


#include "ObstacleScript/end.lsl"





