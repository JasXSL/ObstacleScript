#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

list getDescType( key id, str type ){
    
    str test = type+"$";
    integer len = llStringLength(test)-1;
    
    list d = split(prDesc(id), "$$");
    integer s;
    for(; s < count(d); ++s ){
        
        if( llGetSubString(l2s(d, s), 0, len) == test )
            return split(l2s(d, s), "$");
            
    }
    return [];

}

integer still;

#include "ObstacleScript/begin.lsl"

onStateEntry()
    
	Portal$scriptOnline();
    
end

handleTimer( "phys" )
    
    float vel = llVecMag(llGetVel());
    if( vel < .05 ){
        
        if( still ){
            
            unsetTimer("phys");
            llSetStatus(STATUS_PHYSICS, FALSE);
            
        }
        
        still = TRUE;
        
    }
    else
        still = FALSE;    

end

handleOwnerMethod( GhostInteractiveMethod$interact )

    list dt = getDescType(llGetKey(), Desc$TASK_GHOST_INTERACTIVE);
    
	
    // Auto
    if( l2i(dt, 1) & 1 ){
        
        vector dir = l2v(dt, 2);
        if( dir == ZERO_VECTOR )
            dir = <0,0,1>;
        
		dir *= 2;
        float mag = llVecMag(dir);
        vector offs = llVecNorm(<llFrand(1.0)-.5, llFrand(1.0)-.5, llFrand(1.0)-.5>)*mag;
        llSetStatus(STATUS_PHYSICS, TRUE);
        llSleep(.1);
        llApplyImpulse(offs*llGetMass()*3, TRUE);
        setInterval("phys", 1);
        still = FALSE;
        
    }
    
    raiseEvent(GhostInteractiveEvent$trigger, []);
    
    

end

#include "ObstacleScript/end.lsl"



