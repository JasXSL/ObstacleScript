#define USE_TIMER
#define USE_STATE_ENTRY
#define USE_CHANGED
#define USE_RUN_TIME_PERMISSIONS
#define USE_LISTEN
#define USE_PLAYERS
#include "ObstacleScript/headers/Obstacles/Ghost/Ghost.lsh"
#include "ObstacleScript/resources/SubHelpers/GhostHelper.lsl"
#include "ObstacleScript/index.lsl"

int GHOST_TYPE = -1;
int EVIDENCE_TYPES;
int VIS;
list SEEN_PLAYERS;
int AFFIXES;

int LIT;	// Ghost is in a lit room
int AGG;	// More prone to being agressive. Inverse ADDITIVE (higher value lowers hunt threshold)
int ACT;	// more prone to being active. ADDITIVE
float LAST_ANGER_ADD;
float LAST_ACT_ADD;
float LAST_SALTED;		// llGetTime of when we were last salted
#define SALT_DUR 10
#define isSalted() (llGetTime()-LAST_SALTED < SALT_DUR && LAST_SALTED > 0)

int BFL;
#define BFL_VISIBLE 0x1
#define BFL_HUNT_CATCH 0x2 	// Next seated player should be handled like a hunt catch.
#define BFL_HUNTING 0x4
float LAST_HEART;

key caughtHud;
key SUCTARG;	// Succubus target

footstep(){
	list sounds = [
		"fc3df235-c789-08b2-b09a-b45bce26684b", "631af33a-fde3-177c-8303-5e9af620a382",
		"4ccb842d-4b5d-a7d3-56c6-b6a958ad7881", "c720ce7c-396e-c550-d8c0-1c3e6350debb",
		"27282b3d-5731-3c9b-5940-09645d33f656", "37c2a5a6-07ed-725b-7425-d19a368bcdff"            
	];
	integer sound = floor(llFrand(count(sounds)/2));
	key normal = l2k(sounds, sound*2);
	key cut = l2k(sounds, sound*2+1);
	vector gp = llGetPos();
	llTriggerSoundLimited(normal, 1, <255,255,gp.z+2>, <0,0,gp.z-2>);
	llTriggerSoundLimited(cut, .75, <255,255,gp.z-2>, <0,0,0>);
	llTriggerSoundLimited(cut, .5, <255,255,gp.z+100>, <0,0,gp.z+2>);
}

// Sets DESC to a JSON array
// [0] lit = Ghost room lit
// [1] aggression = More prone to hunting
// [2] active = More prone to interacting with things
updateDesc(){


	int agg = AGG;
	int act = ACT;
	
	// GHOST BEHAVIOR :: BARE
	if( GHOST_TYPE == GhostConst$type$bare ){
	
		if( LIT ){
			
			agg -= 10;
			act -= 25;
		}
		else{
			agg += 10;
			act += 25;
		}
	}
	
	if( agg > 100 )
		agg = 100;

	list out = (list)
		LIT + agg + act + SUCTARG
	;
	llSetObjectDesc(mkarr(out));
	
}

list P_MESH;
toggleMesh( float alpha ){
	
	if( hasStrongAffix(ToolSetConst$affix$ghostInvisible) )
		alpha = 0;
	
	BFL = BFL&~BFL_VISIBLE;
	if( alpha > 0 )
		BFL = BFL|BFL_VISIBLE;
		

	int i;
	for(; i < count(P_MESH); ++i )
		llSetLinkAlpha(l2i(P_MESH, i), alpha, ALL_SIDES);
	

}


bool isVoiceTalking( key player ){
	
	list anims = (list)
		0xa71890f1 +
		0x593e9a3d +
		0x55fe6788 +
		0xc1802201 +
		0x69d5a8ed +
		0x37694185 +
		0xcb1139b6 +
		0x28a3f544 +
		0xcc340155 +
		0xbbf194d1
	;
	list pl = llGetAnimationList(player);
	int i;
	for(; i < count(pl); ++i ){
		
		integer n = (int)("0x"+llGetSubString(l2s(pl, i), 0, 7));
		if( ~llListFindList(anims, (list)n) )
			return true;
	
	}
	return FALSE;

}


pickNewSucTarg(){
	
	list pl = llListRandomize(PLAYERS, 1);
	integer i;
	for(; i < count(pl); ++i ){
		
		key t = l2k(pl, i);
		if( ~llGetAgentInfo(t) & AGENT_SITTING ){
			
			SUCTARG = t;
			updateDesc();
			return;
			
		}
	}
	
}


// Takes precedence over activity
bool hasAngryWord( str input ){

	list words = (list)
		"bitch" + "hunt" + "cuck" + "attack" + "shit" + "damn" + "heck" + "hell" + "idiot" + "moron" + "bloody" + "smelly" + "dickhead" + "motherfucker" + "fight"
	;
	
	integer i;
	for(; i < count(words); ++i ){
		
		if( ~llSubStringIndex(input, l2s(words, i)) )
			return true;
		
	}
	return false;

}

bool hasActivityPhrase( str input ){

	list phr = (list)
		"give us a sign" + 
		"are you here" +
		"where are you" +
		"do something" + 
		"show yourself" +
		"do you want" + 
		"angry" + 
		"lewd" +
		"sexy" +
		"us to leave" +
		"are you friendly" +
		"horny" +
		"cunt" +
		"pussy" + 
		"cock" +
		"dick" +
		"wang" +
		"vagina" +
		"penis" +
		"suck" +
		"fuck" +
		"ass" +
		"behind" +
		"bang" +
		"hello" +
		"balls" +
		"butt" +
		"touch"
	;
	int i;
	for(; i < count(phr); ++i ){
		
		if( ~llSubStringIndex(input, l2s(phr, i)) )
			return true;
		
	}
	
	return false;

}

toggleHeartbeat( bool on ){
	
	SEEN_PLAYERS = [];
	forPlayer(idx, targ)
		Rlv$stopLoopSound( targ );
	end
	
	if( !on )
		unsetTimer("HEART");
	else
		setInterval("HEART", 0.5);

}

#include "ObstacleScript/begin.lsl"


onStateEntry()
	
	llStopSound();
	updateDesc();
	Portal$scriptOnline();
	llSitTarget(<.6,0,-.6>, llEuler2Rot(<0,0,PI>));
	
	
	llListen(0,"","","");
	setInterval("TC", 1);
	
	forLink(nr, name)
		if( name == "MESH" )
			P_MESH += nr;
	end
	toggleMesh(FALSE);
	
end	


// 1 sec ticker
// Checks yaoikai and handles aggro decay
// Handles salt cloud
handleTimer( "TC" )
	
	int pre = AGG;
	int apre = ACT;
	
	if( AGG > 0 )
		--AGG;
	else if( AGG < 0 )
		++AGG;

	if( ACT > 0 )
		--ACT;
	else if( ACT < 0 )
		++ACT;
	

	// GHOST BEHAVIOR :: yaoikai - Aggro
	// If typing or talking, it can add anger up to 40
	if( GHOST_TYPE == GhostConst$type$yaoikai && AGG < 40 ){
		
		vector gp = llGetPos();
		// Check if a player is talking
		forPlayer(idx, targ )
			
			vector pp = prPos(targ);
			integer ai = llGetAgentInfo(targ);
			if( llVecDist(gp, pp) < 3 && (ai & AGENT_TYPING || isVoiceTalking(targ)) )
				AGG += 2;
			
		end		

	}
			
	if( pre != AGG || apre != ACT )
		updateDesc();
		
	// GHOST BEHAVIOR :: Succubus - Find a new target if old one is sitting
	if( GHOST_TYPE == GhostConst$type$succubus && (llGetAgentInfo(SUCTARG)&AGENT_SITTING || llKey2Name(SUCTARG) == "") )
		pickNewSucTarg();
	
	float vel = llVecMag(llGetVel());
	if( isSalted() && vel > 0.5 )
		footstep();
		
end



onListen( ch, msg )
	
	// Only listen to players
	if( llListFindList(PLAYERS, [(str)SENDER_KEY]) == -1 || llGetAgentSize(SENDER_KEY) == ZERO_VECTOR )
		return;

	// Send to Ghost for hunt talk detection
	raiseEvent(GhostAuxEvt$listen, ch + msg + SENDER_KEY);
	
	// Limit to 4m for reactions
	vector gp = llGetPos();
	vector pp = prPos(SENDER_KEY);
	float dist = llVecDist(gp, pp);
	if( dist > 4 )
		return;

			
	// GHOST BEHAVIOR :: yaoikai - Anger whenever hearing a voice
	str m = llToLower(msg);
	int angry = llGetTime()-LAST_ANGER_ADD > 5 && (GHOST_TYPE == GhostConst$type$yaoikai || hasAngryWord(m));
	if( angry ){
	
		if( AGG < 60 )
			AGG += 10;
		LAST_ANGER_ADD = llGetTime();
	
	}
	
	else if( llGetTime()-LAST_ACT_ADD > 25 && hasActivityPhrase(m) ){
		
		ACT += 20;	// Can add 20 activity every 25 sec when asking for a sign
		LAST_ACT_ADD = llGetTime();
		
	}

end


onChanged( change )

    if( change & CHANGED_LINK ){
        
        key ast = llAvatarOnSitTarget();
        if( ast ){
			
			if( ast == llGetOwnerKey(caughtHud) ){
				
				llRequestPermissions(ast, PERMISSION_TRIGGER_ANIMATION);
				
				// The caught player was a hunted player. Otherwise, it's a ghost event.
				if( BFL & BFL_HUNT_CATCH )
					setTimeout("CH0", 2);
				else
					setTimeout("UNSIT", 4);
				
			}
			else
				llUnSit(ast);
		}
		else{
			llStopObjectAnimation("hugeman_grab_active");
			llStopObjectAnimation("hugeman_grab_idle");
		}
    }
    
end

onGhostHuntStep()
	footstep();
end

onGhostVisible( visible )

	unsetTimer("FL");
	toggleMesh(visible);
	if( visible )
		setInterval("FL", 0.1);
	toggleHeartbeat(visible);
	
end

onGhostEventsBegin( players, type, subtype )

	if( 
		(type == GhostEventsConst$IT_POSSESS && (subtype == GhostEventsConst$ITP_SPANK || subtype == GhostEventsConst$ITP_DRAG)) ||
		(type == GhostEventsConst$IT_LIGHTS && subtype == GhostEventsConst$ITL_POP)
	){
		setInterval("HEART", 0.5);	// Only heartbeat for spank
	}
	else{
		BFL = BFL&~BFL_VISIBLE;
		toggleMesh(true);
		toggleHeartbeat(true);
	}
	
	if( type == GhostEventsConst$IT_LIGHTS )
		setInterval("FL", 0.1);
		
end
onGhostEventsEnd( players, type, subtype )
	
	toggleHeartbeat(false);
	unsetTimer("FL");
	BFL = BFL|BFL_VISIBLE;
	toggleMesh(FALSE);
	
	
end


handleTimer( "FL" )
	
	VIS = !VIS;
	float time = .3+llFrand(.6);
	if( VIS )
		time = 0.05+llFrand(.15);
		
	toggleMesh(VIS);
	setTimeout("FL", time);
	
end

onGhostHunt( hunting )
	
	BFL = BFL&~BFL_HUNTING;
	llStopSound();
	AGG = 0;
	if( hunting ){
		BFL = BFL|BFL_HUNTING;
		llLoopSound("5a67fa19-3dbb-74c6-3297-8cee2b66e897", .6);
	}
	updateDesc();
	
end

handleTimer( "UNSIT" )
	
	key ast = llAvatarOnSitTarget();
	if( ast ){
		
		Rlv$unSit(ast, true);
		llUnSit(ast);
		
	}
	
end

handleOwnerMethod( GhostAuxMethod$seatGhostEvent )
	
	BFL = BFL&~BFL_HUNT_CATCH;
	caughtHud = argKey(0);
	Rlv$sit( caughtHud, llGetKey(), TRUE );
	
end

handleTimer( "HEART" )
	
	bool tickHeart = llGetTime()-LAST_HEART > 2;
	
	list found;
	vector gp = llGetPos();
	forPlayer( idx, targ )
		
		vector pp = prPos(targ);
		list ray = llCastRay(gp, pp, RC_DEFAULT);
		if( l2i(ray, -1) == 0 || llVecDist(pp, gp) < 2 ){
			
			found += targ;
			if( llListFindList(SEEN_PLAYERS, (list)targ) == -1 ){
			
				Rlv$loopSoundOn(targ, "b3f04998-bac5-047b-7939-448cbdda39a1", 1);
				
			}
			
		}
	
	end
	
	// Tick heart
	if( llGetTime()-LAST_HEART > 2 && found != [] ){
		
		LAST_HEART = llGetTime();
		Level$raiseEvent(LevelCustomType$GHOST, LevelCustomEvt$GHOST$arouse, mkarr(found) + 4);
		
	}
	
	integer i;
	for(; i < count(SEEN_PLAYERS); ++i ){
	
		key targ = l2k(SEEN_PLAYERS, i);
		if( llListFindList(found, (list)targ) == -1 ){
		
			Rlv$stopLoopSound(targ);
			
		}
			
	}
	
	SEEN_PLAYERS = found;
	
	
end


handleTimer( "CH0" )
	
	raiseEvent(GhostAuxEvt$caughtSat, []);
	
end

onGhostCaught( player, chair )

	caughtHud = player;
	BFL = BFL|BFL_HUNT_CATCH;
	Rlv$sit( caughtHud, llGetKey(), TRUE );
	
}

onRunTimePermissions( perm )
    
    if( perm & PERMISSION_TRIGGER_ANIMATION ){
        
        llStartObjectAnimation("hugeman_grab_active");
        llStartAnimation("hugeman_av_grapple");
        llSleep(.5);
        llStartObjectAnimation("hugeman_grab_idle");
        llStartAnimation("hugeman_av_grapple_idle");
        
    }

end

onGhostType( type, evidence, affixes, dif )

	GHOST_TYPE = type;
	EVIDENCE_TYPES = evidence;
	AFFIXES = affixes;
	// GHOST BEHAVIOR :: SUCCUBUS - Pick a target
	if( SUCTARG == "" && GHOST_TYPE == GhostConst$type$succubus )
		pickNewSucTarg();
	
end

handleOwnerMethod( GhostAuxMethod$salt )
	LAST_SALTED = llGetTime();
end

handleOwnerMethod( GhostAuxMethod$setLight )
	LIT = argInt(0);
	updateDesc();
	//qd("Setting light" + LIT);
end


#include "ObstacleScript/end.lsl"
