#define USE_STATE_ENTRY
#define USE_CHANGED
#define USE_RUN_TIME_PERMISSIONS
#define USE_CONTROL
#define USE_TIMER
#include "ObstacleScript/index.lsl"

vector BASEPOS; // Fetched from player when they first hit the down button
rotation BASEROT;
integer enabled;
float zOffs;
key victim;

integer gLevel;

#include "ObstacleScript/begin.lsl"

onStateEntry()
    
	Portal$scriptOnline();
	
end

onChanged( change )

    if( ~change & CHANGED_LINK )
        return;
    key ast = llAvatarOnSitTarget();
    if( ast == NULL_KEY )
        return; 
    
    
    victim = ast;
    
    llRequestPermissions(ast, PERMISSION_TAKE_CONTROLS);
        
end

onRunTimePermissions( perm )

    if( perm & PERMISSION_TAKE_CONTROLS ){
        
        enabled = gLevel = 0;
        zOffs = 0;
        BASEPOS = ZERO_VECTOR;
        setTimeout("IN", 2);
        llTakeControls(CONTROL_UP|CONTROL_DOWN, TRUE, FALSE);
        
    }

end

onControl( level, edge )

    level = level & (CONTROL_UP|CONTROL_DOWN);
    if( level != gLevel ){
        
        gLevel = level;
        if( level )
            setInterval("T", 0.1);
        else
            unsetInterval("T");
        
    }

end

handleTimer( "IN" )
    enabled = TRUE;
    
end

handleTimer( "T" )

    if( !enabled )
        return;
    
    integer dir = 1;
    if( gLevel & CONTROL_DOWN )
        dir = -1;
    
    // Get character position
    if( BASEPOS == ZERO_VECTOR ){
        
        key sitter = llAvatarOnSitTarget();
        forLink( nr, name )
            
            if( sitter == llGetLinkKey(nr) ){
                
                list data = llGetLinkPrimitiveParams(nr, (list)PRIM_POS_LOCAL + PRIM_ROT_LOCAL);
                BASEPOS = (vector)llLinksetDataRead("_BASEPOS_");
                BASEROT = (rotation)llLinksetDataRead("_BASEROT_");

                jump found;
            }        
        end
        @found;
        
        
    }    
    
    zOffs += 0.005*dir;
    if( zOffs > 1 )
        zOffs = 1;
    else if( zOffs < -1 )
        zOffs = -1;
    
    updateLinkSitTargetAbsolute(1, (BASEPOS+<0,0,zOffs>), BASEROT);
    
end


#include "ObstacleScript/end.lsl"


