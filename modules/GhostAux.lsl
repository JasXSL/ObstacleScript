#define USE_TIMER
#define USE_STATE_ENTRY
#define USE_CHANGED
#define USE_RUN_TIME_PERMISSIONS
#define USE_LISTEN
#define USE_PLAYERS
#include "ObstacleScript/headers/Obstacles/Ghost/Ghost.lsh"
#include "ObstacleScript/index.lsl"

int GHOST_TYPE;
int EVIDENCE_TYPES;

list SEEN_PLAYERS;

int LIT;	// Ghost is in a lit room
int AGG;	// More prone to being agressive. Inverse ADDITIVE (higher value lowers hunt threshold)
int ACT;	// more prone to being active. ADDITIVE
float LAST_ANGER_ADD;
int BFL;
#define BFL_VISIBLE 0x1

key caughtHud;

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
		LIT + agg + act
	;
	llSetObjectDesc(mkarr(out));
	
}

toggleMesh( float alpha ){
	
	
	int pre = BFL&BFL_VISIBLE;
	BFL = BFL&~BFL_VISIBLE;
	if( alpha > 0 )
		BFL = BFL|BFL_VISIBLE;
		
	if( pre != (BFL&BFL_VISIBLE) ){
		
		SEEN_PLAYERS = [];
		forPlayer(idx, targ)
			Rlv$stopLoopSound( targ );
		end
		
		if( ~BFL&BFL_VISIBLE )
			unsetTimer("HEART");
		else
			setInterval("HEART", 0.5);

	
	}
	
	forLink(nr, name)
		if( name == "MESH" )
			llSetLinkAlpha(nr, alpha, ALL_SIDES);
	end
	

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










#include "ObstacleScript/begin.lsl"


onStateEntry()
	
	llStopSound();
	updateDesc();
	Portal$scriptOnline();
	llSitTarget(<.6,0,-.6>, llEuler2Rot(<0,0,PI>));
	
	toggleMesh(0);
	llListen(0,"","","");
	setInterval("TC", 1);
	
end


// Checks yaoikai and handles aggro decay
handleTimer( "TC" )
	
	int pre = AGG;
	
	if( AGG > 0 )
		--AGG;
	else if( AGG < 0 )
		++AGG;

	// GHOST BEHAVIOR :: yaoikai - Aggro
	if( GHOST_TYPE == GhostConst$type$yaoikai && llGetTime()-LAST_ANGER_ADD > 4 ){
		
		vector gp = llGetPos();
		// Check if a player is talking
		forPlayer(idx, targ )
			
			vector pp = prPos(targ);
			integer ai = llGetAgentInfo(targ);
			if( llVecDist(gp, pp) < 3 && (ai & AGENT_TYPING || isVoiceTalking(targ)) ){
				
				LAST_ANGER_ADD = llGetTime();
				AGG += 10;
				idx = 9001;	// Break loop
			
			}
			
		end		

	}
		
	if( pre != AGG )
		updateDesc();

end



onListen( ch, msg )
	
	// Only listen to players
	if( llListFindList(PLAYERS, [(str)SENDER_KEY]) == -1 || llGetAgentSize(SENDER_KEY) == ZERO_VECTOR )
		return;
		
	raiseEvent(GhostAuxEvt$listen, ch + msg + SENDER_KEY);
	
	// GHOST BEHAVIOR :: yaoikai - Listen to players
	if( llGetTime()-LAST_ANGER_ADD < 4 || GHOST_TYPE != GhostConst$type$yaoikai )
		return;
	
	vector gp = llGetPos(); vector pp = prPos(SENDER_KEY);
	float dist = llVecDist(gp, pp);
	if( dist > 3 )
		return;
		
	list ray = llCastRay(gp, pp, RC_DEFAULT);
	if( l2i(ray, -1) )
		return;
		
	AGG += 20;
	LAST_ANGER_ADD = llGetTime();
	

end


onChanged( change )

    if( change & CHANGED_LINK ){
        
        key ast = llAvatarOnSitTarget();
        if( ast ){
			
			if( ast == llGetOwnerKey(caughtHud) ){
				
				llRequestPermissions(ast, PERMISSION_TRIGGER_ANIMATION);
				setTimeout("CH0", 2);
				
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
end

onGhostVisible( visible )
	toggleMesh(visible);
	// Todo: set flicker
end

onGhostHunt( hunting )
	
	llStopSound();
	AGG = 0;
	if( hunting )
		llLoopSound("5a67fa19-3dbb-74c6-3297-8cee2b66e897", .6);

end

handleTimer( "HEART" )
	
	list found;
	vector gp = llGetPos();
	forPlayer( idx, targ )
		
		vector pp = prPos(targ);
		list ray = llCastRay(gp, pp, RC_DEFAULT);
		if( l2i(ray, -1) == 0 || llVecDist(pp, gp) < 2 ){
			
			found += targ;
			if( llListFindList(SEEN_PLAYERS, (list)targ) == -1 ){
			
				Rlv$loopSoundOn(targ, "51ef6a1d-437e-1923-50dd-178dfa6f59fc", 1);
				
			}
			
		}
	
	end
	
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

onGhostType( type, evidence )
	
	GHOST_TYPE = type;
	EVIDENCE_TYPES = evidence;
	
end


handleOwnerMethod( GhostAuxMethod$setLight )
	LIT = argInt(0);
	updateDesc();
	//qd("Setting light" + LIT);
end


#include "ObstacleScript/end.lsl"
