#define USE_STATE_ENTRY
#define USE_SENSOR
#define USE_NO_SENSOR
#define USE_PLAYERS
#include "ObstacleScript/index.lsl"

list cObjs; // (key)id

// Searches desc for a specific type
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

// Returns 1 if door, 0 if not door, -1 if not interactive
integer isInteractive( key id ){
    
	if( getDescType(id, Desc$TASK_DOOR_STAT) )
		return 1;
	if( getDescType(id, Desc$TASK_GHOST_INTERACTIVE) )
		return 1;
	
    return -1;

}


#include "ObstacleScript/begin.lsl"

onStateEntry()

    llSensorRepeat("", "", ACTIVE|PASSIVE, 3, PI, 2);
    
end

onSensor( total )
    
    cObjs = [];
    integer i;
    for(; i < total; ++i ){
        
        integer intr = isInteractive(llDetectedKey(i));
        if( ~intr ){
		
            cObjs += (list)llDetectedKey(i);
			
        }
		
    }
    
end

onNoSensor()
    
    cObjs = [];

end



handleMethod( GhostInteractionsMethod$interact )
	
	int maxItems = argInt(0);
	if( maxItems < 1 )
		maxItems = 1;
	
	list viable = cObjs;
	vector gp = llGetPos();
	forPlayer( index, player )
		
		if( llVecDist(prPos(player), gp) < 2.5 )
			viable += player;
		
	end

	if( !count(viable) )
		return;
	
	viable = llListRandomize(viable, 1);
	
	integer i;
	for(; i < count(viable) && i < maxItems; ++i ){
	
		key targ = l2k(viable, i);
		Level$raiseEvent( LevelCustomType$GHOSTINT, LevelCustomEvt$GHOSTINT$interacted, targ );
		
		// Player interactions
		if( llGetAgentSize(targ) != ZERO_VECTOR ){
		
			qd("Todo: Interact with player");
			return;
			
		}
		
		list door = getDescType(targ, Desc$TASK_DOOR_STAT);
		if( door ){
		
			integer st = l2i(door, 1);
			float perc = 0;
			if( !st || st == 2 )
				perc = 0.5;
			else if( llFrand(1) < 0.5 )
				perc = 1.0;
			Door$setRotPercTarg( targ, "*", perc );
			
			return;
			
		}
			
		GhostInteractive$interact( targ );
	
	}
	
	
	
end

#include "ObstacleScript/end.lsl"



