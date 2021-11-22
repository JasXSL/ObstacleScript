#define USE_TIMER
#define USE_STATE_ENTRY
#define USE_LISTEN
#define USE_PLAYERS
#include "ObstacleScript/headers/Obstacles/Ghost/Ghost.lsh"
#include "ObstacleScript/index.lsl"

list cNodes;	// Cache of pathing nodes, fetched from Nodes script
#define cacheNodes() cNodes = []; Nodes$getRooms( GhostMethod$cbNodes )


/* CONFIG */
// Hover height when walking
float hover = 1.33;

/* PATH NODES */
// List of portals to go to
list gotoPortals = [];      // Portals we're pathing to
integer portalState;        // See below
#define PS_SEEKING 0        // Finding the closest position on X from the marker
#define PS_ALIGNING 1       // Moving through it to 1M on X
vector alignPos;            // Fwd or behind the node we're going to

// Anim state
integer walking;

// Behavior
integer GHOST_TYPE = GhostConst$type$succubus;

// State manager
integer STATE; 
#define STATE_IDLE 0        // Ghost is ready to find somewhere to go
#define STATE_ROAM 1        // Ghost is roaming towards a position
#define STATE_PATHING 2     // Ghost is pathing towards a room
#define STATE_CHASING 3     // Ghost is chasing a player
#define STATE_EVENT 4       // Ghost is doing an event, and shouldn't be interfered with
#define STATE_HUNT_PRE 5	// Waiting to start the hunt

vector roamTarget;          // Position we're roaming towards
key chaseTarget;            // Player we're chasting
float nextRoam;       		// llGetTime() of when we finished the last roam
float lastWarp;				// llGetTime of when we last went to the ghost room
float lastReturn = -26;		// -26 means it'll have 4 sec to cache the nodes when spawned, then immediately roam
float lastFootSound;		// Used when hunting to generate footsteps

vector spawnPos;
#define toggleMesh( alpha ) raiseEvent(GhostEvt$alpha, alpha)

setState( int st ){
	
	if( STATE == st )
		return;
		
	if( st == STATE_IDLE )
		nextRoam = llGetTime()+1+llFrand(5);

	if( STATE == STATE_CHASING )
		chaseFailed = 0;
		
	STATE = st;
	//llSetText((str)STATE, ONE_VECTOR, 1);
	
}


// Settings
#define BFL_PAUSE 0x1		// Pause the ghost, used for debugging.
#define BFL_HUNTING 0x2		// Currently hunting for players
#define BFL_SMUDGE 0x4		// Can only idle. Deaf and blind.
#define BFL_VISIBLE 0x8		// Player visible

#define BFL_HUNT_HAS_LOS 0x10	// We currently have line of sight to our target
#define BFL_HUNT_HAS_POS 0x20	// LOS lost, but we have their last visible coordinates
integer BFL;

// 
list getDoorData( key door ){
	
	list desc = split(prDesc(prRoot(door)), "$$");
	integer i;
	for(; i < count(desc); ++i ){
		
		list spl = split(l2s(desc, i), "$");
		if( l2s(spl, 0) == Desc$TASK_DOOR_STAT )
			return spl;
			
	}
	return [];
	
}

warpToGhostRoom(){

	setState(STATE_IDLE);
	lastWarp = llGetTime();
	toggleWalking(FALSE);
	llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
	llSleep(.5);
	llSetRegionPos(spawnPos);
	
}

// toggles walking animation
toggleWalking( integer on ){
    
    if( on == walking )
        return;
        
    walking = on;
    if( on )
        llStartObjectAnimation("hugeman_walk");
    else
        llStopObjectAnimation("hugeman_walk");
        
}

// Call whenever gotoPortals is changed to update the position offset while pathing
calculateAlignPos(){
    
    alignPos = llRot2Fwd(prRot(l2k(gotoPortals, 0)));
    vector pp = prPos(l2k(gotoPortals, 0));
    vector gp = llGetPos();
    if( llVecDist(pp+alignPos, gp) > llVecDist(pp-alignPos, gp) )
        alignPos = -alignPos;
        
}


// Returns FALSE if it's unable to walk towards that position
integer walkTowards( vector pos ){

	vector gp = llGetPos();
	vector pp = pos;
	list ray;
	// Door detection when hunting
	if( BFL&BFL_HUNTING && (STATE == STATE_PATHING || huntLastSeenPos != ZERO_VECTOR) ){
	
		ray = llCastRay(gp, gp+llVecNorm(pp-gp), RC_DEFAULT);
		if( l2i(ray, -1) ){
			
			key door = l2k(ray, 0);
			list desc = getDoorData(door);
			// Door not already fully open
			if( l2i(desc, 1) < 2 ){
				
				GhostInteractions$objectTouched( door );
				Door$setRotPercTarg( prRoot(door), "*", 1 );
			
			}
			
		}
		
	}
	
	float speed = 1.0;
	if( BFL & BFL_HUNTING && BFL & BFL_HUNT_HAS_LOS ){
		
		
		speed = 0.75+(llGetTime()-timeLOS)/3;
		if( speed > 2.5 )
			speed = 2.5;
	
	}

	// Find where to step
	vector fwd = llVecNorm(<pp.x, pp.y, 0>-<gp.x, gp.y, 0>)*speed;
	
	// Can step up on heights hip level or 1m below
	ray = ignoreDoor(llCastRay(gp, gp+fwd-<0,0,2+hover>, RC_DEFAULT + RC_DATA_FLAGS + RC_GET_NORMAL + RC_MAX_HITS + 2 ), TRUE);
	vector v = l2v(ray, 2);
	list fwdRay = ignoreDoor(llCastRay(gp, gp+fwd*.5, RC_DEFAULT + RC_MAX_HITS + 2 ), true);

	if( l2i(ray, -1) < 1 || l2i(fwdRay, -1) || v.z < .2 )
		return FALSE;
		
	vector goto = l2v(ray, 1) + <0,0, hover>;
	rotation lookAt = llRotBetween(<1,0,0>, llVecNorm(<goto.x, goto.y, 0>-<gp.x, gp.y, 0>));
	
	float dist = llVecDist(gp, goto);
	float time = dist/(1.5*speed);
	if( time < 0.12 )
		time = 0.12;
	llSetKeyframedMotion([goto-gp, lookAt/llGetRot(), time], []);
	toggleWalking(true);
	
	if( BFL & BFL_HUNTING && llGetTime()-lastFootSound > .7 ){
		lastFootSound = llGetTime()+llFrand(.4);
		raiseEvent(GhostEvt$huntStep, []);
	}
	
	return TRUE;

}

// Removes doors from a raycast
list ignoreDoor( list ray, int hasNormal ){

	int i; int n = 2+(hasNormal>0);
	for(; i < count(ray)/2 && count(ray) > 1; ++i ){
	
		list door = getDoorData(l2k(ray, i*n));
		if( door != [] ){
		
			ray = llDeleteSubList(ray, i*n, i*n+1);
			--i;
			
		}
	
	}
	return llListReplaceList(ray, (list)(count(ray)/n), -1, -1);
	
	
}


// Returns the index in the cNodes array a point is, or -1 if not found
integer pointInRoom( vector point ){

	integer i;
	for(; i < count(cNodes); i += NodesConst$rmStride ){
	
		vector bbPos = l2v(cNodes, i+1);
		rotation bbRot = l2r(cNodes, i+2);
		vector bbSize = l2v(cNodes, i+3);       
		bbPos /= bbRot;
		vector pos = point / bbRot;
		
		if(
			pos.x < bbPos.x+bbSize.x/2 && pos.x > bbPos.x-bbSize.x/2 &&
			pos.y < bbPos.y+bbSize.y/2 && pos.y > bbPos.y-bbSize.y/2 &&
			pos.z < bbPos.z+bbSize.z/2 && pos.z > bbPos.z-bbSize.z/2
		){
		
			return i;
			
		}
	}
	
	return -1;

}

key huntTarget;				// Target we're currently tracking
vector huntLastSeenPos;		// Position we last saw them
list playerFootsteps;
float huntLastFootstepReq;
float chaseFailed;			// Time when ghost got stuck with LOS
float lastFootstepsUpdate;	// Limits how often we can run the footstep check
float timeLOS;				// Time when we got line of sight
int easyMode = TRUE;
key caughtSeat;				// UUID of seat to put player on
key caughtHud;				// HUD of caught player

vector getPlayerVisibilityPos( key player ){
	
	vector as = llGetAgentSize(player);
	integer ainfo = llGetAgentInfo(player);
	float z = as.z/2-.1;
	if( ainfo & AGENT_CROUCHING )
		z = 0;
	return prPos(player)+<0,0,z>;

}

// Player walked or talked
addFootsteps( key player, float trackChance ){
	
	vector pos = prPos(player);
	integer index = llListFindList(PLAYERS, (list)((str)player));
	playerFootsteps = llListReplaceList(playerFootsteps, (list)pos, index, index);

	// Random modifier to track down a hiding player in the room when they talk or move
	if( llFrand(1.0) < trackChance || ~BFL&BFL_HUNTING || STATE == STATE_HUNT_PRE )
		return;

	// If there's a hunt target and it's not this player, ignore
	if( huntTarget != "" && huntTarget != player )
		return;

	// If footsteps are in a different room, we'll want to go there
	if( pointInRoom(pos) != pointInRoom(llGetPos()) )
		return;
			
	//qd("Updating POS by footsteps");
	// If player is in the same room, we want to force the ghost to go there
	huntLastSeenPos = pos;
	huntTarget = player;
	BFL = BFL|BFL_HUNT_HAS_POS;
	setState(STATE_CHASING);
		
}


// Checks if a player is making noise
int isNoisy( key player ){
	
	integer ainfo = llGetAgentInfo(player);
	if( (ainfo & AGENT_WALKING && ~ainfo & AGENT_CROUCHING) || ainfo & AGENT_TYPING )
		return TRUE;
		
	// Memory saving hex conversion
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
		if( ~llListFindList(anims, (list)n) ){
			return true;
		}
	}
	return FALSE;
		
}





// IT BEGINS //


#include "ObstacleScript/begin.lsl"

handleTimer( "A" )

	if( BFL & BFL_PAUSE ){
		
		toggleWalking(FALSE);
		llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
		return;
		
	}
	
	if( BFL&BFL_HUNTING ){

		// listen for player footsteps
		
		if( llGetTime()-lastFootstepsUpdate > 1.0 ){
		
			lastFootstepsUpdate = llGetTime();
			forPlayer( index, player )
				
				if( isNoisy(player) )
					addFootsteps(player, 0.5);
			
			end
		
		}
			
		
		// Start chasing after the setup phase
		if( STATE != STATE_HUNT_PRE ){
		
			vector g = llGetPos();
			
			// First see if we can still see our tracked target
			if( llKey2Name(huntTarget) != "" ){
			
				vector tp = getPlayerVisibilityPos(huntTarget);
				list ray = llCastRay(llGetPos(), tp, RC_DEFAULT);
				if( l2i(ray, -1) == 0 && ~pointInRoom(tp) ){
					
					if( ~BFL&BFL_HUNT_HAS_LOS ){
						
						timeLOS = llGetTime();
						BFL = BFL|BFL_HUNT_HAS_LOS;
						BFL = BFL|BFL_HUNT_HAS_POS;
						huntLastSeenPos = tp;
						
						//qd("Now have LOS and last seen pos" + huntLastSeenPos);
						setState(STATE_CHASING);
					
					}
					
				}
				else if( BFL & BFL_HUNT_HAS_LOS ){
				
					BFL = BFL &~BFL_HUNT_HAS_LOS;
					//qd("No longer have LOS, but we have POS");
					
				}
			
			}
			

			// We don't have position or line of sight. But do we have footsteps? 
			if( huntTarget != "" && !(BFL&(BFL_HUNT_HAS_POS|BFL_HUNT_HAS_POS)) && STATE != STATE_PATHING ){
			
				integer loc = llListFindList(PLAYERS, (list)((string)huntTarget));
				vector pos = l2v(playerFootsteps, loc);
				
				if( pos ){
					
					// We're in the room, search it for a while
					if( pointInRoom(pos) == pointInRoom(llGetPos()) ){
						
						//qd("Searching room");
						huntTarget = "";
						huntLastFootstepReq = llGetTime()+10;	// Give him 10 sec before going elsewhere
						
					}else{
					
						//qd("We have TARGET footsteps");
						Nodes$getPath( GhostMethod$followNodes, llGetPos(), pos );
						huntLastFootstepReq = llGetTime()+4;	// Give it 4 sec to request the path before assuming a failure
						
					}
				}
			
			}
			
			// We're not chasing after anyone. We can try a LOS check
			if( !(BFL&(BFL_HUNT_HAS_POS|BFL_HUNT_HAS_LOS)) ){
			
				vector gp = llGetPos();
				forPlayer( index, player )
					
					vector pp = getPlayerVisibilityPos(player);
					list ray = llCastRay(gp, pp, RC_DEFAULT);
					if( l2i(ray, -1) == 0 ){
						
						huntTarget = player;
						//qd("Now hunting " + player);
						index = 9001;
						
					}
				
				end
				
			}
					
			// Nothing nearby. We could try going to some footsteps
			if( llGetTime() > huntLastFootstepReq+2 && STATE != STATE_PATHING && huntTarget == "" ){
				
				huntLastFootstepReq = llGetTime();
				vector gp = llGetPos();
				integer r = pointInRoom(gp);
				
				float closest; vector pathTo;
				integer i;
				for(; i < count(playerFootsteps); ++i ){
					
					vector v = l2v(playerFootsteps, i);
					float dist = llVecDist(gp, v);
					// Look for the shortest place not in this room
					if( v != ZERO_VECTOR && (dist < closest || pathTo == ZERO_VECTOR) && r != pointInRoom(v) ){
						
						pathTo = v;
						closest = dist;
					
					}
				
				}
				
				if( pathTo )
					Nodes$getPath( GhostMethod$followNodes, llGetPos(), pathTo );
				
			}
		
		}
	
	}

	if( STATE == STATE_IDLE ){
	
		// Every 30 sec go back to ghost room or try to go to a completely random room if not at home
		if( ~BFL&BFL_HUNTING && llGetTime()-lastReturn > 30 ){
			
			
			
			int startRoom = pointInRoom( spawnPos );
			int curRoom = pointInRoom( llGetPos() );
			
			
			// GHOST BEHAVIOR - GOORYO - Request a room with plumbing
			if( GHOST_TYPE == GhostConst$type$gooryo ){
				
				if( startRoom != curRoom ){

					llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
					llSleep(.1);
					llSetRegionPos(spawnPos);
					lastReturn = llGetTime()+llFrand(20);	// gooryo warps more
					
				}
				else{
					
					Nodes$getPlumbedRoom( "PL", GhostMethod$cbPlumbing );
					lastReturn = llGetTime()-28;	// Attempt every 2 sec until it succeeds
					
				}
				return;
				
			}

			// Go back
			if( startRoom != curRoom ){
				Nodes$getPath( GhostMethod$followNodes, llGetPos(), spawnPos );
				lastReturn = llGetTime()+10+llFrand(40);	// Stay in the ghost room for longer than when it roams
			}
			// Find a random room
			else{
				
				vector rng = llGetPos()+<llFrand(20)-10,llFrand(20)-10,llFrand(15)-5>;
				lastReturn = llGetTime()-28;	// Attempt every 2 sec until it succeeds
				int gRoom = pointInRoom(rng);
				if( ~gRoom && gRoom != curRoom )
					Nodes$getPath( GhostMethod$followNodes, llGetPos(), rng );
			
			}
		
		}

		// Find a new target
		if( llGetTime() > nextRoam || BFL&BFL_HUNTING ){
			vector dir = llRot2Fwd(llEuler2Rot(<0,0,llFrand(TWO_PI)>));
			
			// Exponentially grow the area it can roam
			float maxDist = llPow(0.05*(llGetTime()-lastWarp), 1.3)+1;
			if( BFL&BFL_HUNTING )
				maxDist = 5;
				
			float dist = maxDist;
			if( dist > 5 )
				dist = 5;
			
				
			vector gp = llGetPos()-<0,0,.5>;
			
			list ray = llCastRay(gp, gp+dir*dist, RC_DEFAULT);
			if( l2i(ray, -1) == 1 ){
				
				dist = llVecDist(gp, l2v(ray, 1))-1;
				// Too short of a distance
				if( dist < 0 )
					return;
								
			}
			
			roamTarget = llGetPos()+dir*dist;
			if( llVecDist(spawnPos, roamTarget) > maxDist || pointInRoom(roamTarget) == -1 )
				return;
			setState(STATE_ROAM);
		
		}
		
	}
	
	else if( STATE == STATE_ROAM ){
	
		// Reached destination
		vector gp = llGetPos();
		if( llVecDist(<gp.x, gp.y, 0>, <roamTarget.x, roamTarget.y, 0>) < .25 ){
		
			toggleWalking(false);
			setState(STATE_IDLE);
			return;
			
		}
	
		// Try walking
		integer att = walkTowards(roamTarget);
		
		// Failed walking, return to idle
		if( !att ){
		
			llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
			toggleWalking(false);
			setState(STATE_IDLE);
			return;
			
		}
	
	}
	
	else if( STATE == STATE_PATHING ){
		
		// Prevents stuckage
		while( gotoPortals != [] && prPos(l2k(gotoPortals, 0)) == ZERO_VECTOR )
			gotoPortals = llDeleteSubList(gotoPortals, 0, 0);
		
		if( !count(gotoPortals) ){
	
			toggleWalking(false);
			
			int startRoom = pointInRoom( spawnPos );
			int curRoom = pointInRoom( llGetPos() );
			if( startRoom == curRoom ){
				roamTarget = spawnPos;
				setState(STATE_ROAM);
			}
			else 
				setState(STATE_IDLE);
						
			return;
			
		}
		
		list data = llGetObjectDetails(l2k(gotoPortals, 0), 
			(list)OBJECT_POS + OBJECT_ROT
		);
		
		vector gp = llGetPos();
		vector pp = l2v(data, 0);
		rotation pr = l2r(data, 1);
		
		pp += alignPos;
		
		// In order for stairs to work we need to relax the Z height of seeking
		float zAllow = 1.0;
		if( portalState == PS_SEEKING )
			zAllow = 10;
			
		// Reached the node, find the next
		if( llVecDist(<gp.x, gp.y, 0>, <pp.x, pp.y, 0>) < .25 && llFabs(gp.z-pp.z) < zAllow ){
			
			if( portalState == PS_SEEKING ){
				
				portalState = PS_ALIGNING;
				alignPos = -alignPos;
				
				// Go deeper into the room when hunting if possible
				if( BFL&BFL_HUNTING && count(gotoPortals) < 2 ){
					
					vector raw = l2v(data, 0);
					list ray = llCastRay(raw, raw+alignPos*3, RC_DEFAULT);
					if( l2i(ray, -1) == 0 )
						alignPos *= 3;
					
				}
				
			}
			else{
				
				portalState = PS_SEEKING;
				gotoPortals = llDeleteSubList(gotoPortals, 0, 0);
				calculateAlignPos();
				
			}
			return; // Continue on the next frame instead   
			
		}
		
		integer att = walkTowards(pp);
		
		if( !att ){
		
			toggleWalking(false);
			// Try to teleport
			list ray = llCastRay(pp, pp-<0,0,5>, RC_DEFAULT);
			if( l2i(ray, -1) == 1 ){
				
				float dist = llVecDist(pp, gp);
				llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
				llSleep(dist/2);
				llSetRegionPos(l2v(ray, 1)+<0,0,hover>);
				
			}
		
		}
	
	}
	
	else if( STATE == STATE_CHASING ){
	
		// Chasing a player target
		vector pp = prPos(huntTarget);
		if( ~BFL&BFL_HUNT_HAS_LOS )
			pp = huntLastSeenPos;
			
		vector gp = llGetPos();

		list ray = llCastRay(gp, pp, RC_DEFAULT);
		
		// Player catch distance is greater than range to reach their last seen position
		float catchDist = 0.5;
		if( BFL & BFL_HUNT_HAS_LOS )
			catchDist = 0.75;
		if( llVecDist(<gp.x, gp.y, 0>, <pp.x, pp.y, 0>) < catchDist && l2i(ray, -1) == 0 ){
		
			
			if( BFL&BFL_HUNT_HAS_LOS ){
				
				// Tell level
				Level$raiseEvent( LevelCustomType$GHOST, LevelCustomEvt$GHOST$caught, huntTarget );
				toggleWalking(FALSE);
				setState(STATE_EVENT);
				return;
				
			}
			
			BFL = BFL&~BFL_HUNT_HAS_POS;
			//qd("POS has been reached");
			setState(STATE_IDLE);	// Go idle again
			toggleWalking(FALSE);
			return;
			
		}
		
		// Try walking
		integer att = walkTowards(pp);
		
		// Failed walking, return to idle
		if( !att ){
			
			// Start the warp timer
			if( chaseFailed <= 0 ){
			
				chaseFailed = llGetTime();
				return;
				
			}
			
			// Warp timer hit, start warping
			else if( llGetTime()-chaseFailed > 1.5 ){
			
				llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
				//qd("Cheese it!");
				list ray = llCastRay(pp, pp-<0,0,4>, RC_DEFAULT);
				vector ppFloor = pp;
				if( l2i(ray, -1) == 1 )
					ppFloor = l2v(ray, 1)+<0,0,hover>;

				
				integer i;
				for( ; i < 100 && !walkTowards(pp); ++i ){
					
					float dist = llVecDist(llGetPos(), ppFloor);
					if( dist > .25 )
						dist = .25;
					
					llSetRegionPos(gp+(ppFloor-gp)*dist);
					llSleep(.2);
					if( dist <= .25 ){
					
						chaseFailed = 0;
						return;		// We have warped to the position
						
					}
					
				}
				
				// If we got to this point, nothing else can be done. Just return to idle.
				BFL = BFL&~BFL_HUNT_HAS_LOS;
				BFL = BFL&~BFL_HUNT_HAS_POS;
				setState(STATE_IDLE);
				
			}
						
			
		}
		else
			chaseFailed = 0;
		
		
		
	}
	/*
	else if( STATE == STATE_EVENT ){
	
	}
	
	else if( STATE == STATE_HUNT_PRE ){
		// Do nothing
	}
	*/
    

end

handleMethod( GhostMethod$sendToChair )
	
	caughtSeat = argKey(0);
	caughtHud = argKey(1);
	easyMode = argInt(2);
	
	// failed
	if( caughtSeat == "" ){
		setState(STATE_IDLE);
		return;
	}
	
	raiseEvent(GhostEvt$caught, caughtHud + caughtSeat);
	setTimeout("IDL", 10);	// Go idle again
	
end

// Hunt ended after capturing someone
handleTimer( "IDL" )
	setState(STATE_IDLE);
	llStopSound();
	toggleMesh(0);
end

onGhostAuxCaughtSat()
	
	setTimeout("CH1", 2);
	
	rotation rot = prRot(caughtSeat);
	vector pos = prPos(caughtSeat)+llRot2Fwd(rot);
	list ray = llCastRay(pos+<0,0,.5>, pos-<0,0,5>, RC_DEFAULT);
	if( l2i(ray, -1) == 1 ){
		
		pos = l2v(ray, 1)+<0,0,hover>;
		llSetRegionPos(pos);
		llRotLookAt(llEuler2Rot(<0,0,PI>)*rot, 1, 1);
	
	}
	
end

handleTimer( "CH1" )
	
	llUnSit(llAvatarOnSitTarget());
	llSleep(.1);
	Bondage$seat(caughtSeat, caughtHud, easyMode);
	setTimeout("IDL", 2);
	
end



onPortalLoadComplete( desc )

	spawnPos = llGetPos();
	Level$raiseEvent(LevelCustomType$GHOST, LevelCustomEvt$GHOST$spawned, []);
	cacheNodes();
	
	
end

onStateEntry()
        
	spawnPos = llGetPos();
    stopAllObjectAnimations()
    llStartObjectAnimation("hugeman_idle");
    //llStartObjectAnimation("hugeman_walk");
    setInterval("A", 0.25);
	addListen(0);
	Portal$scriptOnline();
	
	
	#ifdef FETCH_PLAYERS_ON_COMPILE
	cacheNodes();
	Level$forceRefreshPortal();
    #endif
	
	Level$raiseEvent(LevelCustomType$GHOST, LevelCustomEvt$GHOST$spawned, []);
	
end

onListen( chan, message )
	
	if( ~BFL&BFL_HUNTING )
		return;
	
	integer pos = llListFindList(PLAYERS, (list)((str)SENDER_KEY));
	if( pos == -1 )
		return;

	addFootsteps(SENDER_KEY, 0.75);


end


/* METHODS */
handleOwnerMethod( GhostMethod$toggleHunt )
	
	if( argInt(0) ){
	
		qd("Starting hunt");
		playerFootsteps = [];
		forPlayer(index, player)
			playerFootsteps += 0;
		end
		BFL = BFL&~BFL_HUNT_HAS_LOS;
		BFL = BFL&~BFL_HUNT_HAS_POS;
		huntTarget = "";
		huntLastSeenPos = ZERO_VECTOR;
		
		BFL = BFL|BFL_HUNTING;
		setState(STATE_HUNT_PRE);
		toggleWalking(FALSE);
		toggleMesh(1.0);
		raiseEvent(GhostEvt$hunt, TRUE);
		llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
		setTimeout("HUNT", 3);	// Start walking
		
	}	
	else{
		
		BFL = BFL&~BFL_HUNTING;
		raiseEvent(GhostEvt$hunt, FALSE);
		// Don't warp back if we caught someone
		if( STATE != STATE_EVENT ){
			
			toggleMesh(0);
			setState(STATE_IDLE);
			warpToGhostRoom();
			llStopSound();
			
			
		}
		
	}

end

// Start hunting
handleTimer( "HUNT" )
	setState(STATE_IDLE);
end



handleOwnerMethod( GhostMethod$setType )

	GHOST_TYPE = argInt(0);
	int evidenceType = argInt(1);
	raiseEvent(GhostEvt$type, GHOST_TYPE + evidenceType);
	
end

handleOwnerMethod( GhostMethod$smudge )
	
	lastReturn = llGetTime()+60;	// Don't use a long distance roam for 60 seconds
	warpToGhostRoom();
	
end

handleOwnerMethod( GhostMethod$cbPlumbing )
	
	if( BFL&BFL_HUNTING )
		return;
			
	str cb = argStr(0);
	vector pos = argVec(1);
	setState(STATE_IDLE);
	llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
	llSleep(.2);
	list ray = llCastRay(pos, pos-<0,0,3>, RC_DEFAULT);
	if( l2i(ray, -1) == 1 )
		llSetRegionPos(l2v(ray, 1)+<0,0,hover>);
	lastReturn = llGetTime();

end

handleOwnerMethod( GhostMethod$followNodes )
    
    gotoPortals = METHOD_ARGS;
	//qd("Got portals " + gotoPortals);
    calculateAlignPos();
	setState(STATE_PATHING);
	lastReturn = llGetTime();	// Node follow should only happen when roaming or during a hunt. Both are good times to update the timer.
    
end

handleOwnerMethod( GhostMethod$stop )
    
	int verbose = argInt(1);
	
	BFL = BFL&~BFL_PAUSE;
	if( argInt(0) )
		BFL = BFL|BFL_PAUSE;
		
	if( verbose ){
	
		qd("Stop status: " + ((BFL&BFL_PAUSE)>0));
		qd("Players:" + PLAYERS);
		
	}
	
end


handleOwnerMethod( GhostMethod$cbNodes )
	
	Nodes$handleGetRooms(cNodes);
			
end


#include "ObstacleScript/end.lsl"


