#define USE_STATE_ENTRY
#define USE_COLLISION_START
#include "ObstacleScript/index.lsl"

string ID;
integer FLAGS;

#include "ObstacleScript/begin.lsl"

onStateEntry()
    
    Portal$scriptOnline();  // required for portal to function
    
end

onPortalLoadComplete( desc )
    
	list json = llJson2List(desc);
	vector size = (vector)l2s(json, 0);
	if( size == ZERO_VECTOR )
		return;
		
	ID = l2s(json, 1);
	FLAGS = l2i(json, 2);
		
	llSetScale(size);
	llVolumeDetect(TRUE);
	
	if( PortalHelper$isLive() )
		llSetAlpha(0, ALL_SIDES );
    
end

onCollisionStart( total )
	
	if( !isPlayer( llDetectedKey(0) ) )
		return;
	
	
	Level$raiseEvent( LevelCustomType$TRIGGER, LevelCustomEvt$TRIGGER$trigger, llDetectedKey(0) );
	
	if( FLAGS & TriggerConst$F_TRIGGER_ONCE ){
	
		llSleep(2);
		llDie();
		llSleep(3);
		
	}

end


#include "ObstacleScript/end.lsl"

