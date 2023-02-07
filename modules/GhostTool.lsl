#include "ObstacleScript/helpers/Ghost/GhostHelper.lsb"
#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

vector spawnPos;
rotation spawnRot;

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
	spawnRot = llGetRot();
	Level$raiseEvent(LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$getGhost, []);

end

handleMethod( GhostToolMethod$hunting )
    
    bool hunting = argInt(0);
    key ghost = argKey(1);
    raiseEvent(GhostToolEvt$hunting, hunting + ghost);
    
end

handleOwnerMethod( GhostToolMethod$setData )
	raiseEvent(GhostToolEvt$data, METHOD_ARGS);
end


handleOwnerMethod( GhostToolMethod$emp )
	
	vector pos = prPos(SENDER_KEY);
	vector g = llGetPos();
	float z = llFabs(pos.z-g.z);
	
	if( z > 2 )
		return;
	
	if( llVecDist(pos, g) > 8 )
		return;
	
	raiseEvent(GhostToolEvt$emp, []);
	
end


// Only for the rezzed out assets
handleOwnerMethod( GhostToolMethod$pickedUp )
    
    if( llGetAttached() )
        return;
        
	raiseEvent(GhostToolEvt$pickedUp, []);
	llSetStatus(STATUS_PHYSICS, FALSE);
	llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
	llSleep(.1);
	llSetRegionPos(spawnPos-<0,0,10>);
	
end

handleOwnerMethod( GhostToolMethod$dropped )
    
    if( llGetAttached() )
        return;
    
	vector pos = argVec(0);
	rotation rot = argRot(1);
	if( pos == ZERO_VECTOR )
		pos = spawnPos;
	if( rot == ZERO_ROTATION )
		rot = spawnRot;
	
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



