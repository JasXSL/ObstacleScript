#define USE_STATE_ENTRY
#define USE_SENSOR
#define USE_NO_SENSOR
#define USE_HUDS
#define USE_TIMER
#include "ObstacleScript/helpers/Ghost/GhostHelper.lsb"
#include "ObstacleScript/index.lsl"

int GHOST_TYPE;
key lastSound;
float LAST_SOUND_TIME;
float LAST_POWER;
int BFL;
#define BFL_HUNTING 0x1

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
#define INTERACT_BREASTS_MOTORBOAT 7
interactPlayer( key hud, int power ){
    	
    integer sex = Rlv$getDesc$sex( hud );
    list allowed = [INTERACT_BUTT, INTERACT_GROIN];
    if( sex & GENITALS_BREASTS )
        allowed += (list)INTERACT_BREASTS_PINCH + INTERACT_BREASTS_GRAB + INTERACT_BREASTS_MOTORBOAT;
		
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
	else if( type == INTERACT_BREASTS_MOTORBOAT ){
        
        anim = "phasmo_motorboat";
        dur = 1.4;
		sound = "c84a8f79-e6cf-76bb-3e27-a4be63c8f2c0";
        
    }
    
	//llOwnerSay("Interacting " + llKey2Name(hud) + " anim " + anim);
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
    
        Rlv$setFlags( hud, RlvFlags$IMMOBILE, false );
		setTimeout("GI", dur);
		touchedPlayers += hud;
        
    }
	
	
    
    
}


triggerSound(){
	list sounds = [
		"edb881de-3d1c-775a-7e35-46a00f6b7a30",
		"e59ab35b-9d96-1c49-af60-aae586272e67",
		"b7f92130-398b-ddab-5525-060cfca2f9da",
		"66a0c5a8-3718-2126-d3f6-e4dfbdcda2df"
	];
	
	// GHOST BEHAVIOR :: ORGHAST - Special moan
	if( GHOST_TYPE == GhostConst$type$orghast && llFrand(1.0) < 0.3 )
		sounds = (list)"743212e5-252e-3bf8-43fe-690b1fd3dd56";
	
	lastSound = randElem(sounds);
	triggerParabolic(llGetPos(), TRUE);
	LAST_SOUND_TIME = llGetTime();
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

	forPlayer( t, idx, targ )
		ToolSet$trigger( targ, ToolsetConst$types$ghost$parabolic, pos + sound );
	end
	
}

int getGhostPower(){
	
	float max = 2;
	// GHOST BEHAVIOR :: EHEE - Higher chance of strong EMF
	if( GHOST_TYPE == GhostConst$type$ehee )
		max = 4;	// Higher chance of a strong EMF
	return llFrand(max) > 1;
	
}

// Set the global lastSound before calling this
onGhostTouch( key targ, int power ){
	
	Level$raiseEvent( LevelCustomType$GHOSTINT, LevelCustomEvt$GHOSTINT$interacted, targ + power );
	
	if( lastSound ){
		triggerParabolic(prPos(targ), TRUE);
		LAST_SOUND_TIME = llGetTime();
	}
	// Lazily sent to any target
	if( GhostGet$evidence() & GhostConst$evidence$stains && !hasWeakAffix(GhostGet$affixes(), ToolSetConst$affix$noEvidenceUntilSalted) ){
		//qd("Setting stains on " + llKey2Name(targ));
		Door$setStainsTarg( targ, "*", TRUE );
	}

}


// Uses a ghost power, returns TRUE on success. Viable is a list of nearby objects (never players)
int usePower(){

	// GHOST BEHAVIOR - Obukakke - Leave stains on everything nearby without EMF
	if( GHOST_TYPE == GhostConst$type$obukakke && GhostInteractionsGet$nrItems() ){
		
		GhostInteractionsGet$foreachItem(total, index, targ)
			Door$setStainsTarg( targ, "*", TRUE );
			GhostInteractive$interact( targ, GhostInteractiveConst$INTERACT_ALLOW_STAINS|GhostInteractiveConst$NO_EVENT, 0 );
		end
		Level$raiseEvent(LevelCustomType$GHOSTINT, LevelCustomEvt$GHOSTINT$power, []);

		return TRUE;
	}
	if( GHOST_TYPE == GhostConst$type$orghast ){
		
		triggerSound();
		return TRUE;
		
	}
	
	if( GHOST_TYPE == GhostConst$type$jim && GhostGet$inLitRoom( llGetObjectDesc() ) ){
		
		Level$raiseEvent(LevelCustomType$GHOSTINT, LevelCustomEvt$GHOSTINT$power, []);
		return TRUE;
		
	}

	// Failed, reset last time we used power
	return FALSE;
	
}


#include "ObstacleScript/begin.lsl"

onStateEntry()

    llSensorRepeat("", "", ACTIVE|PASSIVE, 6, PI, 1);
	
	Portal$scriptOnline();
	//qd(llGetUsedMemory());
    
end

// Let players move again after touching them
handleTimer( "GI" )
	
	integer i;
	for(; i < count(touchedPlayers); ++i )
		Rlv$unsetFlags( l2k(touchedPlayers, i), RlvFlags$IMMOBILE, FALSE );
	touchedPlayers = [];
	
end

// Force a hunt to start if possible
handleTimer( "HUNT" )
	Level$raiseEvent(LevelCustomType$GHOSTINT, LevelCustomEvt$GHOSTINT$forceHunt, []);
end

onSensor( total )
    
	//qd(total);
	vector gp = llGetPos();
	// Reset index
	
	str table = idbTable$INTERACT_OBJS;
	int idx;
    integer i;
    for(; i < total; ++i ){
        
		key dk = llDetectedKey(i);
		vector dp = llDetectedPos(i);
		integer intr = isInteractive(llDetectedKey(i));
		if( ~intr && llFabs(gp.z-dp.z) < 1.8 ){
		
			idbSetByIndex(table, idx, dk);
			++idx;
			
		}
    }
	idbSetIndex(table, idx);
	
    
end

onNoSensor()
    
	idbResetIndex(idbTable$INTERACT_OBJS);

end

onGhostType()
	
	GHOST_TYPE = GhostGet$type();
	
end

onGhostHunt( hunting )
	BFL = BFL&~BFL_HUNTING;
	if( hunting )
		BFL = BFL|BFL_HUNTING;
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

// This can also be used to debug
handleOwnerMethod( GhostInteractionsMethod$forcePower )
	int affixes = GhostGet$affixes();
	qd("Using power of ghost type" + GHOST_TYPE + " affixes " + affixes + "Strong" + getStrongAffix(affixes) + " weak " + getWeakAffix(affixes));
	usePower();
end


handleOwnerMethod( GhostInteractionsMethod$interact )
	/*
	maxItems is no longer used because it causes problems with the microphone
	int maxItems = argInt(0);
	if( maxItems < 1 )
		maxItems = 1;
	*/
	list viable;
	vector gp = llGetPos();
	int power = getGhostPower();
	int debug = argInt(0);
	int affixes = GhostGet$affixes();
	
	lastSound = "";
	
	float powChance = 0.25;
	// Power gets priority
	// 20% chance of using its power. Can only use its power every 30 sec by default
	float powCD = 40;
	// Orghast just plays a sound
	if( GHOST_TYPE == GhostConst$type$orghast ){
		powCD = 15;
		powChance = 0.35;	// Orghast should have a significantly larger chance of doing a ghost event
	}
	// Jim uses it a little more often
	if( GHOST_TYPE == GhostConst$type$jim )
		powCD = 25;
	if( GHOST_TYPE == GhostConst$type$obukakke )
		powCD = 20;
	
	if( llFrand(1.0) < powChance && llGetTime()-LAST_POWER > powCD ){
		
		if( usePower() ){
			
			LAST_POWER = llGetTime();
			return;
			
		}
	
	}
	
	// Next check if we can interact with player
	int roomLit = GhostGet$inLitRoom( llGetObjectDesc() );
	int isBare = GHOST_TYPE == GhostConst$type$bare;
	int isAsswang = GHOST_TYPE == GhostConst$type$asswang;
	int unlitBare = isBare && !roomLit;
	
	
	
	float playerChance = 0.2;	// 20% chance of touching a player
	// GHOST BEHAVIOR :: POWOLTERGEIST
	if( GHOST_TYPE == GhostConst$type$powoltergeist )
		playerChance = 0.05;	// Powoltergeist is very low
	// GHOST BEHAVIOR :: IMP
	else if( GHOST_TYPE == GhostConst$type$imp )
		playerChance = 0.4;		// Imp is twice as high
	// GHOST BEHAVIOR :: BARE
	else if( unlitBare )
		playerChance = 0.4;		// Bare is also high when lights are off
	// GHOST BEHAVIOR :: ASSWANG - Higher chance of touching a player. But can only touch players who aren't looking at it.
	else if( isAsswang )
		playerChance = 0.4;		// Asswang also has double touch chance, but it's on the condition that the player is facing away
	// GHOST BEHAVIOR :: SUCCUBUS - Touch a bit more
	else if( GHOST_TYPE == GhostConst$type$succubus )
		playerChance = 0.4;		// Succubus is also the highest, but will only touch one player.
	// GHOST BEHAVIOR :: YURI/YAIKAI - Slightly more touchy
	else if( GHOST_TYPE == GhostConst$type$yuri || GHOST_TYPE == GhostConst$type$yaoikai || GHOST_TYPE == GhostConst$type$stringoi )
		playerChance = 0.3;		// Yuri/yaoikai are lightly more touchy
	
	// Don't touch players when hunting
	if( BFL&BFL_HUNTING )
		playerChance = 0;
		
	key targ;	// Target of the interact

	// Needs to be motion sensed before it can touch anything
	if( (!hasStrongAffix(affixes, ToolSetConst$affix$reqMotionSensor) && !hasStrongAffix(affixes, ToolSetConst$affix$vibrator)) || BFL&BFL_HUNTING ){
		
		if( llFrand(1.0) < playerChance ){
		
			list huds = getHuds();
			
			if( debug )
				llOwnerSay("Rolled player");
		
			forPlayer( t, index, player )
				
				myAngX(player, ang)
				bool isFacingAway = llFabs(ang) > PI_BY_TWO;
				float range = 3;
				// GHOST BEHAVIOR :: Stringoi Bare - Increased interact range.
				if( GHOST_TYPE == GhostConst$type$stringoi || unlitBare )
					range = 4;
				if( isAsswang && isFacingAway )
					range = 4.5;
				
				
				if( llVecDist(prPos(player), gp) < range && ~llGetAgentInfo(player) & AGENT_SITTING ){
					
					key hud = l2k(huds, index);
					int genitals = Rlv$getDesc$sex( hud );
					if( 
						// GHOST BEHAVIOR :: yaoikai - Male preference
						(GHOST_TYPE != GhostConst$type$yaoikai || genitals&GENITALS_PENIS) &&
						// GHOST BEHAVIOR :: yuri - Female preference
						(GHOST_TYPE != GhostConst$type$yuri || ~genitals&GENITALS_PENIS) &&
						// GHOST BEHAVIOR :: asswang - Only touch players not looking at it
						(!isAsswang || isFacingAway) &&
						// GHOST BEHAVIOR :: succubus - Only touch one player
						(GHOST_TYPE != GhostConst$type$succubus || player == GhostGet$sucTarg(llGetObjectDesc()))
					)viable += player;
					
				}
				
			end
			
			targ = randElem(viable);	// Handled at the end through onGhostTouch
				
			// Touch player
			integer pos = llListFindList(getPlayers(), (list)((str)targ));
			if( debug )
				llOwnerSay("Touching player " + llGetDisplayName(targ) + (str)pos);
				
			if( ~pos ){
			
				key hud = l2k(huds, pos);
				//qd(HUDS);
				int clothes = Rlv$getDesc$clothes( hud )&1023;	// 1023 = 10 bit
				float cc = 0.15;
				if( isBare && !roomLit )
					cc *= 4;
				// GHOST BEHAVIOR :: Stringoi - Strip
				if( GHOST_TYPE == GhostConst$type$stringoi )
					cc *= 3;
				
				if( llFrand(1.0) < cc && clothes && power ){
					
					// 682 = fully dressed. +1 because 0 is ignore
					stripPlayer(hud, clothes >= 682);
					lastSound = "620fe5e8-9223-10fc-3a5c-0f5e0edc3a35";
					
					// GHOST BEHAVIOR :: Stringoi - Leave orbs behind for 5 min when stripping a player
					if( GHOST_TYPE == GhostConst$type$stringoi ){
						forPlayer( t, i, k )
						
							Gui$setOrbs( k, llGetPos(), 600 );
							
						end
					}
					
					if( unlitBare && llFrand(1) < 0.75 ){
						setTimeout("HUNT", 1+llFrand(6));
					}
					
				}
				else{
					interactPlayer(hud, power);
				}
				
			}
			// GHOST BEHAVIOR :: asswang - On fail, revert to .3 player chance
			else if( GHOST_TYPE == GhostConst$type$asswang )
				playerChance = 0.3;
			else
				playerChance *= .5;	// Make it a little higher chance to touch an object
			
		}
		
		
		// Roll for player failed, roll for object instead
		else if( llFrand(1.0) > playerChance ){
			
			list dbg;
			
			vector gp = llGetPos();
			GhostInteractionsGet$foreachItem(total, i, k)
			
				vector offs = prPos(k);
				float dist = 3;
				float d = llVecDist(<gp.x, gp.y, 0>, <offs.x, offs.y, 0>);

				// GHOST BEHAVIOR :: Stringoi - 30% longer interact radius
				if( GHOST_TYPE == GhostConst$type$stringoi )
					dist *= 1.3;
					
				if( d < dist )
					viable += k;
				
				if( debug )
					dbg += (list)llKey2Name(k) + d;
				
			end
			
			targ = randElem(viable);
			if( debug ){
				qd("Targ" + llKey2Name(targ) + "weak affix" + getWeakAffix(affixes) +"strong" + getStrongAffix(affixes));
				qd(("Unfiltered ("+(str)(count(dbg)/3)+")") + llDumpList2String(dbg, ","));
			}
			list door = getDescType(targ, Desc$TASK_DOOR_STAT);
			list doorId = split(l2s(door, 2), ":");
			
			if( debug )
				llOwnerSay("Touching ITEM "+llKey2Name(targ));
			// Door interactions
			if( 
				count(door) && 							// Is a door
				l2s(doorId, 1) != "EXT" && 				// Can't touch exits
				(GhostGet$difficulty() > 1 || ~BFL&BFL_HUNTING) 	// Can't touch doors during a hunt on intermediate and below
			){
			
				integer st = l2i(door, 1);
				
				
				float perc = 0;
				// When hunting, if the door is fully closed, open it 25%
				// Otherwise swing it right open
				if( BFL&BFL_HUNTING ){
					if( !st )
						perc = 0.25;
					else
						perc = 1.0;
				}
				// Fully opened or fully closed
				else if( !st || st == 2 ){
					perc = 0.5;
				}
				else if( llFrand(1) < 0.5 )
					perc = 1.0;
				Door$setRotPercTarg( targ, "*", perc );
				//qd("Door interact" + llKey2Name(targ));
				lastSound = "8c8a6c69-f859-d559-0498-14cce9510635";
				
			}
			// Regular interactions
			else{
				
				integer flags; float speed = 1.0;
				
				if( 
					GhostGet$evidence() & GhostConst$evidence$stains && 
					!hasWeakAffix(affixes, ToolSetConst$affix$noEvidenceUntilSalted)
				)flags = flags|GhostInteractiveConst$INTERACT_ALLOW_STAINS;
					
				// GHOST BEHAVIOR :: POWOLTERGEIST - 20% chance to yeet an item
				if( GHOST_TYPE == GhostConst$type$powoltergeist && llFrand(1.0) < 0.2 )
					speed *= 2;

				GhostInteractive$interact( targ, flags, speed );
				
			}
			
		}
		
	
	}
	// Now that we're done, see if we found a target, or should play a sound
	// Trigger sound, add EMF etc
	if( targ )
		onGhostTouch(targ, power);

	// We can generate a sound if there's no target
	else{
	
		if( debug )
			llOwnerSay("no viable");
		if( llGetTime()-LAST_SOUND_TIME > 10 )
			triggerSound();
		
	}

	
end

#include "ObstacleScript/end.lsl"



