#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

str DESC;
list getDescType( key id, str type ){
	
	list d = split(prDesc(id), "$$");
    integer s;
    for(; s < count(d); ++s ){
        
		list sub = split(l2s(d, s), "$");
        if( l2s(sub, 0) == type )
			return sub;
			
    }
	return [];

}

toggleStains( int on ){

	forLink( link, name )
		
		if( name == "STAINS" )
			llSetLinkAlpha(link, on > 0, ALL_SIDES);
		
	end

}

integer still;

#include "ObstacleScript/begin.lsl"

onStateEntry()
    
	Portal$scriptOnline();
	
	toggleStains(FALSE);
    
end

handleTimer( "phys" )
    
    float vel = llVecMag(llGetVel());
    if( vel < .05 ){
        
        if( still > 4 ){
            
            unsetTimer("phys");
            llSetStatus(STATUS_PHYSICS, FALSE);
            
        }
        
		++still;
        
    }
    else
        still = 0;    

end

handleOwnerMethod( GhostInteractiveMethod$interact )

    list dt = getDescType(llGetKey(), Desc$TASK_GHOST_INTERACTIVE);
    int flags = l2i(dt, 1);		// Tells the script what it can handle automatically
	vector dir = l2vs(dt, 2);	// Direction of push if push is enabled
	
	int intFlags = argInt(0);	// Flags for the method call
	float pushStrength = argFloat(1);
	
    // Auto
    if( flags & DescConst$GI$auto_push && pushStrength > 0 ){
        
        if( dir == ZERO_VECTOR )
            dir = <0,0,1>;
        
		dir *= 2;
        float mag = llVecMag(dir);
        vector offs = llVecNorm(<llFrand(1.0)-.5, llFrand(1.0)-.5, llFrand(1.0)-.5>)*mag;
        llSetStatus(STATUS_PHYSICS, TRUE);
        llSleep(.1);
        llApplyImpulse(offs*llGetMass()*3*pushStrength, TRUE);
        setInterval("phys", 1);
        still = FALSE;
        
    }

	// Handle stains
	if( flags & DescConst$GI$auto_stains && intFlags & GhostInteractiveConst$INTERACT_ALLOW_STAINS ){
		
		toggleStains(TRUE);
		setTimeout("STAINS", 120);
		
	}
    
    raiseEvent(GhostInteractiveEvent$trigger, METHOD_ARGS);
    
    

end


handleTimer("STAINS")
	toggleStains(FALSE);
end

#include "ObstacleScript/end.lsl"



