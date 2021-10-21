#define USE_STATE_ENTRY
#define USE_SENSOR
#define USE_NO_SENSOR
#define USE_PLAYERS
#define USE_HUDS
#define USE_TIMER
#include "ObstacleScript/resources/SubHelpers/GhostHelper.lsl"
#include "ObstacleScript/index.lsl"

list cObjs; // (key)id
int EVIDENCE_TYPES;
key lastSound;
float LAST_SOUND_TIME;

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
    
	str name = llKey2Name(id);
	if( name == "HOTS" && EVIDENCE_TYPES & GhostConst$evidence$hots )
		return 0;
	if( name == "Ecchisketch" && EVIDENCE_TYPES & GhostConst$evidence$writing )
		return 0;
	
	if( getDescType(id, Desc$TASK_DOOR_STAT) )
		return 1;
	if( getDescType(id, Desc$TASK_GHOST_INTERACTIVE) ){
		
		// Stains should start with STAIN in order to properly filter out
		if( llGetSubString(name, 0, 4) == "STAIN" && ~EVIDENCE_TYPES&GhostConst$evidence$stains )
			return 0;
		return 0;
		
	}
	
    return -1;

}

list touchedPlayers;

#define INTERACT_BUTT 0
#define INTERACT_GROIN 1
#define INTERACT_BREASTS_PINCH 2
#define INTERACT_BREASTS_GRAB 3
#define INTERACT_BUTT_SMALL 4
#define INTERACT_GROIN_SMALL 5
#define INTERACT_BREASTS_SMALL 6
interactPlayer( key hud, int power ){
    	
    integer sex = Rlv$getDesc$sex( hud );
    list allowed = [INTERACT_BUTT, INTERACT_GROIN];
    if( sex & GENITALS_BREASTS )
        allowed += (list)INTERACT_BREASTS_PINCH + INTERACT_BREASTS_GRAB;
		
	if( !power ){
		
		allowed = (list)INTERACT_BUTT_SMALL + INTERACT_GROIN_SMALL;
		if( sex & GENITALS_BREASTS )
			allowed += INTERACT_BREASTS_SMALL;
		
	}
    
    integer type = (int)randElem(allowed);
    
    string anim = "buttslap_full";
    key sound = "29a4fcd0-88c2-45d1-8173-c0a84a0c8917";
	float vol = .25;
    float dur = 1.4;
    if( type == INTERACT_GROIN ){
        
        anim = "groingrope_full";
        dur = 1.3;
        
    }
	else if( type == INTERACT_BUTT_SMALL ){
		
		anim = "butt_touch_small";
		dur = 0;
		sound = "c6a3ff56-0e88-00af-5256-0a4d25302dd5";
		vol = .05;
		
	}
	else if( type == INTERACT_GROIN_SMALL ){
		
		anim = "groin_touch_small";
		vol = .05;
		dur = 0;
		sound = "c6a3ff56-0e88-00af-5256-0a4d25302dd5";
		
	}
	else if( type == INTERACT_BREASTS_SMALL ){
		
		anim = "breast_touch_small";
		sound = "";
		vol = .05;
		dur = 0;
		
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
    
    if( sound ){
	
		lastSound = sound;
        Rlv$triggerSoundOn( hud, sound, vol, llGetOwnerKey(hud) );
		
    }
	
	triggerParabolic(prPos(hud), (sound != ""));
	
    if( dur ){
    
        Rlv$setFlags( hud, RlvFlags$IMMOBILE, FALSE );
		setTimeout("GI", dur);
		touchedPlayers += hud;
        
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

triggerParabolic( vector pos, integer sound ){

	forPlayer( idx, targ )
		ToolSet$trigger( targ, ToolsetConst$types$ghost$parabolic, pos + sound );
	end
	
}


#include "ObstacleScript/begin.lsl"

onStateEntry()

    llSensorRepeat("", "", ACTIVE|PASSIVE, 3, PI, 2);
	
	Portal$scriptOnline();
	
	#ifdef FETCH_PLAYERS_ON_COMPILE
	Level$forceRefreshPortal();
    #endif
    
end

handleTimer( "GI" )
	
	integer i;
	for(; i < count(touchedPlayers); ++i )
		Rlv$unsetFlags( l2k(touchedPlayers, i), RlvFlags$IMMOBILE, FALSE );
	touchedPlayers = [];
	
end

onSensor( total )
    
    cObjs = [];
    integer i;
    for(; i < total; ++i ){
        
        integer intr = isInteractive(llDetectedKey(i));
        if( ~intr )
            cObjs += (list)llDetectedKey(i);
			
		
    }
    
end

onNoSensor()
    
    cObjs = [];

end

onGhostType( type, evidence )
	
	EVIDENCE_TYPES = evidence;
	
end

handleMethod( GhostInteractionsMethod$playSoundOnMe )
	
	vector pos = prPos(SENDER_KEY);
	vector p1 = <.1,.1,.1>;
	float vol = argFloat(0);
	llTriggerSoundLimited(lastSound, vol, pos+p1, pos-p1);

end


handleMethod( GhostInteractionsMethod$interact )
	
	int maxItems = argInt(0);
	if( maxItems < 1 )
		maxItems = 1;
		
	list viable = cObjs;
	vector gp = llGetPos();
	
	if( llFrand(1.0) < .5 ){
		forPlayer( index, player )
			
			if( llVecDist(prPos(player), gp) < 2.5 )
				viable += player;
			
		end
	}

	// We can generate a sound if there's nothing viable
	if( !count(viable) ){
		
		if( llGetTime()-LAST_SOUND_TIME > 10 ){
		
			// Todo: Replace with a ghost sound
			list sounds = [
				"0c12069d-4963-f5e8-b1c7-3f8f0a89cdf7",
				"952dfaba-c30f-1ddd-798d-e5e90f7d8156",
				"49f24b04-fea1-9d3e-ff20-4e5691b72270",
				"ca631edd-4725-c03f-3fa8-08c0bf6ffbf9"
			];
			LAST_SOUND_TIME = llGetTime();
			lastSound = randElem(sounds);
			triggerParabolic(llGetPos(), TRUE);

		}
		
		return;
	}
	
	viable = llListRandomize(viable, 1);
	
	
	integer i;
	for(; i < count(viable) && i < maxItems; ++i ){
	
		key targ = l2k(viable, i);
		int power = llFloor(llFrand(2));	// Powerful interact
		Level$raiseEvent( LevelCustomType$GHOSTINT, LevelCustomEvt$GHOSTINT$interacted, targ + power );
		
		// Player interactions
		if( llGetAgentSize(targ) != ZERO_VECTOR ){
		
			integer pos = llListFindList(PLAYERS, (list)((str)targ));
			if( ~pos ){
			
				key hud = l2k(HUDS, pos);
				//qd(HUDS);
				int clothes = Rlv$getDesc$clothes( hud )&1023;	// 1023 = 10 bit
				if( llFrand(1.0) < 0.15 && clothes && power ){
					
					// 682 = fully dressed. +1 because 0 is ignore
					stripPlayer(hud, clothes >= 682);
					
				}
				else
					interactPlayer(hud, power);

				//qd("Interacted with player" + llKey2Name(llGetOwnerKey(hud)));
				return;
				
			}
			
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
			
			if( EVIDENCE_TYPES&GhostConst$evidence$stains ){
				//qd("Setting stains on " + llKey2Name(targ));
				Door$setStainsTarg( targ, "*", TRUE );
			}
			
			//qd("Door interact" + llKey2Name(targ));
			triggerParabolic(prPos(targ), FALSE);
			return;
			
		}
			
		// HOTS is a tool, not an interactive
		if( llKey2Name(targ) == "HOTS" || llKey2Name(targ) == "Ecchisketch" )
			GhostTool$trigger( targ, [] );
		else
			GhostInteractive$interact( targ, [] );
		triggerParabolic(prPos(targ), FALSE);
		//qd("Normal interact" + llKey2Name(targ));
	
	}
	
	
	
end

#include "ObstacleScript/end.lsl"



