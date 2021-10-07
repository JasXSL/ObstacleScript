#include "ObstacleScript/resources/SubHelpers/GhostHelper.lsl"

#define USE_RUN_TIME_PERMISSIONS
#define USE_STATE_ENTRY
#define USE_ATTACH
#define USE_TIMER
#define USE_LISTEN
#include "ObstacleScript/index.lsl"

integer P_OWOMETER;
integer P_FLASHLIGHT;
integer P_FLASHLIGHTBEAM;
integer P_HOTS;
integer P_HOTSBALL;
integer P_ECCHISKETCH;
integer P_SPIRITBOX;

// Equipped tools
integer ACTIVE_TOOL;    // index of stride in TOOLS. Use activeType for type
// (int)tool, (var)setting, (key)id
list TOOLS;
#define TOOLSTRIDE 3
#define TTEMPLATE (list)0 + 0 +0	// Empty slot
#define activeType() l2i(TOOLS, ACTIVE_TOOL*TOOLSTRIDE)

list EMF_SPOTS; // uuid, strength, time

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
	PP(P_SPIRITBOX, (list)PRIM_FULLBRIGHT + 3 + FALSE);

    onDataUpdate();
	
	if( tool )
		llStartAnimation("default_hold");
	else
		llStopAnimation("default_hold");
		
	
}

// Attachment data received for the active asset
onDataUpdate(){
    
    integer tool = activeType();
    integer on = getActiveToolInt();
    if( tool == ToolsetConst$types$ghost$flashlight ){

        PP(
            P_FLASHLIGHTBEAM, 
            (list)PRIM_POINT_LIGHT + on + <1.000, 0.928, 0.710> + 1 + 4 + 1
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
	else if( tool == ToolsetConst$types$ghost$spiritbox ){
	
		// Todo: interface with spirit box script
	
	}
	
	sendActiveTool(tool);
    
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
        
        
    end
    
    if( llGetAttached() )
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION|PERMISSION_TRACK_CAMERA);
    
    // Facelight
    PP(P_FLASHLIGHT, (list)PRIM_POINT_LIGHT + 1 + <1.000, 0.928, 0.710> + .1 + 1.5 + 2);
    
    llSetAlpha(0, ALL_SIDES);
    //addTool(ToolsetConst$types$ghost$flashlight, (list)0);
	//addTool(ToolsetConst$types$ghost$owometer, (list)0);
	//addTool(ToolsetConst$types$ghost$spiritbox, (list)1);
	
    drawActiveTool();
	llListen(3, "", llGetOwner(), "");
	
	
    
end

onPortalLclickStarted( hud )
    
	integer tool = activeType();
	list toggled = (list)
		ToolsetConst$types$ghost$owometer +
		ToolsetConst$types$ghost$flashlight +
		ToolsetConst$types$ghost$spiritbox
	;
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





