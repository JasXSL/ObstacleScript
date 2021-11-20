#define USE_STATE_ENTRY
#define USE_SENSOR
#define USE_NO_SENSOR
#define USE_PLAYERS
#define USE_HUDS
#define USE_TIMER
#include "ObstacleScript/resources/SubHelpers/GhostHelper.lsl"
#include "ObstacleScript/index.lsl"

list cObjs; // (key)id
int GHOST_TYPE;
int EVIDENCE_TYPES;
key lastSound;
float LAST_SOUND_TIME;
float LAST_POWER;

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
		
		// GHOST BEHAVIOR :: BARE - Don't turn on lights
		list ls = getDescType(id, Desc$TASK_LIGHT_SWITCH);
		if( GHOST_TYPE == GhostConst$type$bare && ls != [] && !l2i(ls, 1) )
			return -1;
			
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
    
	if( sound == "" )
		sound = "29a4fcd0-88c2-45d1-8173-c0a84a0c8917";
	else
		Rlv$triggerSoundOn( hud, sound, vol, llGetOwnerKey(hud) ); // Trigger sound on victim
	// Parabolic
	lastSound = sound;
	
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

int getGhostPower(){
	return llFloor(llFrand(2));
}

// Set the global lastSound before calling this
onGhostTouch( key targ, int power ){
	
	Level$raiseEvent( LevelCustomType$GHOSTINT, LevelCustomEvt$GHOSTINT$interacted, targ + power );
	
	if( lastSound ){
		triggerParabolic(prPos(targ), TRUE);
		LAST_SOUND_TIME = llGetTime();
	}
	// Lazily sent to any target
	if( EVIDENCE_TYPES&GhostConst$evidence$stains ){
		//qd("Setting stains on " + llKey2Name(targ));
		Door$setStainsTarg( targ, "*", TRUE );
	}

}


// Uses a ghost power, returns TRUE on success
int usePower( list viable, int isPlayerInteract ){

	// GHOST BEHAVIOR - GOORYO - Teleport
	if( GHOST_TYPE == GhostConst$type$gooryo ){
		
		// Todo: teleport
		return TRUE;
		
	}
	// GHOST BEHAVIOR - Obukakke - Leave stains on everything nearby without EMF
	if( GHOST_TYPE == GhostConst$type$obukakke && !isPlayerInteract && count(viable) ){
		
		integer i;
		for(; i < count(viable); ++i ){
		
			key targ = l2k(viable, i);
			Door$setStainsTarg( targ, "*", TRUE );
			GhostInteractive$interact( targ, GhostInteractiveConst$INTERACT_ALLOW_STAINS, 0 );
			
		}
		Level$raiseEvent(LevelCustomType$GHOSTINT, LevelCustomEvt$GHOSTINT$power, []);

		return TRUE;
	}
		
	// Failed, reset last time we used power
	return FALSE;
	
}





#include "ObstacleScript/begin.lsl"

onStateEntry()

    llSensorRepeat("", "", ACTIVE|PASSIVE, 2, PI, 1);
	
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
	
	GHOST_TYPE = type;
	EVIDENCE_TYPES = evidence;
	
end

handleMethod( GhostInteractionsMethod$playSoundOnMe )
	
	vector pos = prPos(SENDER_KEY);
	vector p1 = <.1,.1,.1>;
	float vol = argFloat(0);
	llTriggerSoundLimited(lastSound, vol, pos+p1, pos-p1);

end

handleMethod( GhostInteractionsMethod$objectTouched )
	
	key obj = argKey(0);
	lastSound = "8c8a6c69-f859-d559-0498-14cce9510635";	// In the future you may wanna provide the sound for parabolic
	onGhostTouch(obj, getGhostPower());
	

end

handleMethod( GhostInteractionsMethod$interact )
	/*
	maxItems is no longer used because it causes problems with the microphone
	int maxItems = argInt(0);
	if( maxItems < 1 )
		maxItems = 1;
	*/
	list viable = cObjs;
	vector gp = llGetPos();
	int power = getGhostPower();
	
	int isUnlitBare = GHOST_TYPE == GhostConst$type$bare && !GhostGet$inLitRoom( llGetObjectDesc() );
	
	float playerChance = 0.3;	// 30% chance of touching a player if there's other things nearby
	// GHOST BEHAVIOR :: POWOLTERGEIST
	if( GHOST_TYPE == GhostConst$type$powoltergeist )
		playerChance = 0.05;
	// GHOST BEHAVIOR :: IMP
	else if( GHOST_TYPE == GhostConst$type$imp )
		playerChance = 0.75;
	// GHOST BEHAVIOR :: BARE
	else if( isUnlitBare )
		playerChance = 0.5;
	
	int isPlayerInteract = llFrand(1.0) < playerChance || !count(viable);
	if( isPlayerInteract ){
	
		list objs = viable;
		viable = [];
		forPlayer( index, player )
			
			if( llVecDist(prPos(player), gp) < 2.5 && ~llGetAgentInfo(player) & AGENT_SITTING )
				viable += player;
			
		end
		// No viable players, try going back to objs
		if( !count(viable) ){
			
			isPlayerInteract = FALSE;
			viable = objs;
			
		}
		
	}
	
	
	// 10% chance of using its power. Can only use its power every 30 sec
	if( llFrand(1.0) < 0.1 && llGetTime()-LAST_POWER > 30 ){
		
		if( usePower(viable, isPlayerInteract) ){
			
			LAST_POWER = llGetTime();
			return;
			
		}
	
	}
	

	// We can generate a sound if there's nothing viable
	if( !count(viable) ){
		
		if( llGetTime()-LAST_SOUND_TIME > 10 ){
		
			list sounds = [
				"edb881de-3d1c-775a-7e35-46a00f6b7a30",
				"e59ab35b-9d96-1c49-af60-aae586272e67",
				"b7f92130-398b-ddab-5525-060cfca2f9da",
				"66a0c5a8-3718-2126-d3f6-e4dfbdcda2df"
			];
			lastSound = randElem(sounds);

		}
		
		return;
	}
	

	lastSound = "";

	key targ = randElem(viable);
	list door = getDescType(targ, Desc$TASK_DOOR_STAT);
	
	// Player interactions
	if( llGetAgentSize(targ) != ZERO_VECTOR ){
	
		integer pos = llListFindList(PLAYERS, (list)((str)targ));
		if( ~pos ){
		
			key hud = l2k(HUDS, pos);
			//qd(HUDS);
			int clothes = Rlv$getDesc$clothes( hud )&1023;	// 1023 = 10 bit
			float cc = 0.15;
			if( isUnlitBare )
				cc *= 3;
			
			if( llFrand(1.0) < cc && clothes && power ){
				
				// 682 = fully dressed. +1 because 0 is ignore
				stripPlayer(hud, clothes >= 682);
				lastSound = "620fe5e8-9223-10fc-3a5c-0f5e0edc3a35";
				
			}
			else{
				interactPlayer(hud, power);
			}
			
		}
		
	}
	// Door interactions
	else if( door ){
	
		integer st = l2i(door, 1);
		float perc = 0;
		if( !st || st == 2 )
			perc = 0.5;
		else if( llFrand(1) < 0.5 )
			perc = 1.0;
		Door$setRotPercTarg( targ, "*", perc );
		//qd("Door interact" + llKey2Name(targ));
		lastSound = "8c8a6c69-f859-d559-0498-14cce9510635";
		
	}
	// Tool interactions
	else if( llKey2Name(targ) == "HOTS" || llKey2Name(targ) == "Ecchisketch" ){
		GhostTool$trigger( targ, [] );
	}
	// Regular interactions
	else{
		
		integer flags; float speed = 1.0;
		if( EVIDENCE_TYPES & GhostConst$evidence$stains )
			flags = flags|GhostInteractiveConst$INTERACT_ALLOW_STAINS;
			
		// GHOST BEHAVIOR :: POWOLTERGEIST
		if( GHOST_TYPE == GhostConst$type$powoltergeist )
			speed += llPow(llFrand(2),2);

		GhostInteractive$interact( targ, flags, speed );
		
	}
	
	// Trigger sound, add EMF etc
	onGhostTouch(targ, power);


	
end

#include "ObstacleScript/end.lsl"



