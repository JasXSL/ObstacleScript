#define USE_STATE_ENTRY
#define USE_SENSOR
#define USE_NO_SENSOR
#define USE_PLAYERS
#define USE_HUDS
#include "ObstacleScript/index.lsl"

list cObjs; // (key)id

// Searches desc for a specific type
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

// Returns 1 if door, 0 if not door, -1 if not interactive
integer isInteractive( key id ){
    
	if( getDescType(id, Desc$TASK_DOOR_STAT) )
		return 1;
	if( getDescType(id, Desc$TASK_GHOST_INTERACTIVE) )
		return 1;
	
    return -1;

}

#define INTERACT_BUTT 0
#define INTERACT_GROIN 1
#define INTERACT_BREASTS_PINCH 2
#define INTERACT_BREASTS_GRAB 3
interactPlayer( key hud ){
    	
    integer sex = Rlv$getDesc$sex( hud );
    list allowed = [INTERACT_BUTT, INTERACT_GROIN];
    if( sex & GENITALS_BREASTS )
        allowed += (list)INTERACT_BREASTS_PINCH + INTERACT_BREASTS_GRAB;
    
    integer type = (int)randElem(allowed);
    
    string anim = "buttslap_full";
    key sound = "29a4fcd0-88c2-45d1-8173-c0a84a0c8917";
    float dur = 1.4;
    if( type == INTERACT_GROIN ){
        
        anim = "groingrope_full";
        dur = 1.3;
        
    }
    else if( type == INTERACT_BREASTS_PINCH ){
        
        anim = "breastpinch";
        sound = "c6a3ff56-0e88-00af-5256-0a4d25302dd5";
        dur = 0.0;
        
    }
    else if( type == INTERACT_BREASTS_GRAB ){
        
        anim = "breastsqueeze";
        dur = 1.7;
        
    }
    
    AnimHandler$anim(
        hud, 
        anim, 
        TRUE, 
        0, 
        0
    );
    
    if( sound )
        Rlv$triggerSound( hud, sound, .5 );
    
    if( dur ){
    
        Rlv$setFlags( hud, RlvFlags$IMMOBILE, FALSE );
        llSleep(dur);
        Rlv$unsetFlags( hud, RlvFlags$IMMOBILE, FALSE );
        
    }
	
	
    
    
}
stripPlayer( key targ, integer slot ){
    
    AnimHandler$anim(
        targ, 
        "decloth", 
        TRUE, 
        0, 
        0
    );
	++slot;	// 0 is ignore, so we gotta add 1
    Rlv$setFlags( targ, RlvFlags$IMMOBILE, FALSE );
    Rlv$triggerSound( targ, "620fe5e8-9223-10fc-3a5c-0f5e0edc3a35", .5 );
    Rlv$setClothes( targ, slot, slot, slot, slot, slot );
    llSleep(2.2);
    Rlv$unsetFlags( targ, RlvFlags$IMMOBILE, FALSE );
    
}



#include "ObstacleScript/begin.lsl"

onStateEntry()

    llSensorRepeat("", "", ACTIVE|PASSIVE, 3, PI, 2);
	
	#ifdef FETCH_PLAYERS_ON_COMPILE
	Level$forceRefreshPortal();
    #endif
    
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
		
			integer pos = llListFindList(PLAYERS, (list)((str)targ));
			if( ~pos ){
			
				key hud = l2k(HUDS, pos);
				int clothes = Rlv$getDesc$clothes( hud )&1023;	// 1023 = 10 bit
				if( llFrand(1.0) < 0.15 && clothes ){
					
					// 682 = fully dressed. +1 because 0 is ignore
					stripPlayer(hud, clothes >= 682);
					
				}
				else
					interactPlayer(hud);

			}
		
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
			
		GhostInteractive$interact( targ, [] );
	
	}
	
	
	
end

#include "ObstacleScript/end.lsl"



