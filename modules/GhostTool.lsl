#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

vector spawnPos;

#include "ObstacleScript/begin.lsl"

onStateEntry()

	if( llGetInventoryType("ToolSet") == INVENTORY_NONE )
		Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$spawned, [] );
    
	spawnPos = llGetPos();
	
	
	Level$raiseEvent(LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$getGhost, []);
	Portal$scriptOnline();
	
end

onPortalLoadComplete( desc )
	
	spawnPos = llGetPos();

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
        
	raiseEvent(GhostToolEvt$pickedUp, []);
	llSetRegionPos(spawnPos-<0,0,10>);
	
end

handleOwnerMethod( GhostToolMethod$dropped )
    
    if( llGetAttached() )
        return;
    
	vector pos = argVec(0);
	rotation rot = argRot(1);
    str data = argStr(2);
	raiseEvent(GhostToolEvt$dropped, data);
	
	llSetLinkPrimitiveParamsFast(LINK_THIS, (list)PRIM_ROTATION + rot);
	llSetRegionPos(pos);
	
    
end

handleOwnerMethod( GhostToolMethod$ghost )

	raiseEvent(GhostToolEvt$ghost, METHOD_ARGS);

end

handleOwnerMethod( GhostToolMethod$trigger )
	
	raiseEvent(GhostToolEvt$trigger, METHOD_ARGS);

end



#include "ObstacleScript/end.lsl"



