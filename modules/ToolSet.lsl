#include "ObstacleScript/resources/SubHelpers/GhostHelper.lsl"
#define USE_RUN_TIME_PERMISSIONS
#define USE_STATE_ENTRY
#define USE_ATTACH
#define USE_TIMER
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
// (int)tool, (var)setting
list TOOLS;
#define activeType() l2i(TOOLS, ACTIVE_TOOL*2)

list EMF_SPOTS; // uuid, strength, time

#define PP llSetLinkPrimitiveParamsFast
#define AL llSetLinkAlpha

#define getActiveToolInt() l2i(TOOLS, ACTIVE_TOOL*2+1)
#define getActiveToolStr() l2s(TOOLS, ACTIVE_TOOL*2+1)


// Draws the currently active tool
drawActiveTool(){
    
    integer tool = activeType();
    list remFullbright = (list)PRIM_GLOW + ALL_SIDES + 0 + PRIM_FULLBRIGHT + ALL_SIDES + 0;
    list remLight = (list)PRIM_POINT_LIGHT + FALSE + <1.000, 0.928, 0.710> + 1 + 4 + 1;

    // Owometer
    AL(P_OWOMETER, tool == ToolsetConst$types$ghost$owometer, ALL_SIDES);
    if( tool == ToolsetConst$types$ghost$owometer )
        setInterval("EMF", .5);
    else{
        
        PP(P_OWOMETER, remFullbright);
        unsetTimer("EMF");
        
    }
    
    // Flashlight
    AL(P_FLASHLIGHT, tool == ToolsetConst$types$ghost$flashlight, ALL_SIDES);
    if( tool != ToolsetConst$types$ghost$flashlight ){
        
        PP(P_FLASHLIGHT, remFullbright);
        PP(P_FLASHLIGHTBEAM, remLight);
        
    }
    
    // HOTS
    AL(P_HOTS, tool == ToolsetConst$types$ghost$hots, ALL_SIDES);
    AL(P_HOTSBALL, tool == ToolsetConst$types$ghost$hots , ALL_SIDES);
    AL(P_ECCHISKETCH, tool == ToolsetConst$types$ghost$ecchisketch, ALL_SIDES);

    onDataUpdate();
    
}

// Attachment data received for the active asset
onDataUpdate(){
    
    integer tool = activeType();
    integer on = getActiveToolInt();
    if( tool == ToolsetConst$types$ghost$owometer )
        PP(P_OWOMETER, (list)PRIM_FULLBRIGHT + 1 + on + PRIM_GLOW + 1 + on*.25);
        
    else if( tool == ToolsetConst$types$ghost$flashlight ){

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
    
}

integer addTool( integer tool, list data ){
    
    if( !count(data) )
        data = [0];
    
    integer i;
    for( ; i < count(TOOLS); i += 2 ){
        
        integer n = (i+ACTIVE_TOOL*2) % count(TOOLS);
        
        integer type = l2i(TOOLS, n);
        if( !type ){
            
            // Attach it here
            TOOLS = llListReplaceList(TOOLS, (list)tool + llList2List(data, 0, 0), n, n+1);
            
            if( n == ACTIVE_TOOL*2 )
                drawActiveTool();
            return TRUE;
            
        }
        
    }
    
    return FALSE;
}

removeActiveTool(){
    
}

#include "ObstacleScript/begin.lsl"

handleTimer( "EMF" )

    // off
    if( !getActiveToolInt() )
        return;

end








onAttach( id )
    llResetScript();
end

onStateEntry()

    integer i;
    for(; i < ToolSetConst$MAX_ACTIVE; ++i )
        TOOLS += (list)0 + 0;
    
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
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
    
    // Facelight
    PP(P_FLASHLIGHT, (list)PRIM_POINT_LIGHT + 1 + <1.000, 0.928, 0.710> + .1 + 1.5 + 2);
    
    llSetAlpha(0, ALL_SIDES);
    //addTool(ToolsetConst$types$ghost$ecchisketch, (list)2);
    drawActiveTool();
    
end



onRunTimePermissions( perm )

    if( perm & PERMISSION_TRIGGER_ANIMATION )
        llStartAnimation("default_hold");
    
    

end


#include "ObstacleScript/end.lsl"





