#define USE_STATE_ENTRY
#include "ObstacleScript/index.lsl"

#include "ObstacleScript/begin.lsl"

onStateEntry()
    
end

handleMethod( GhostToolMethod$hunting )
    
    bool hunting = argInt(0);
    key ghost = argKey(1);
    raiseEvent(GhostToolEvt$hunting, hunting + ghost);
    
end

// Only for the rezzed out assets
handleOwnerMethod( GhostToolMethod$pickedUp )
    
    if( llGetAttached() )
        return;
        
    // Todo: Move to pos
    raiseEvent(GhostToolEvt$pickedUp, []);
    
end

handleOwnerMethod( GhostToolMethod$dropped )
    
    if( llGetAttached() )
        return;
        
    key player = argKey(0);
    str data = argStr(1);
    
    // Todo: Calculate where this should be placed
    raiseEvent(GhostToolEvt$dropped, data);
    
end


#include "ObstacleScript/end.lsl"



