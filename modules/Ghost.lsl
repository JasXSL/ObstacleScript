#define USE_TIMER
#define USE_STATE_ENTRY
#define USE_PLAYERS
#include "ObstacleScript/headers/Obstacles/Ghost/Ghost.lsh"
#include "ObstacleScript/resources/SubHelpers/GhostHelper.lsl"
#include "ObstacleScript/index.lsl"

list cNodes;	// Cache of room markers, fetched from Nodes script
				// (int)roomIndex, (vec)globalPos, (rot)rotation, (vec)size
#define cacheNodes() cNodes = []; Nodes$getRooms( GhostMethod$cbNodes )

// Behavior debug
#define bdbg(message) llOwnerSay(message)

int AFFIXES;

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
int DIF; 	// Difficulty

// State manager
integer STATE; 
#define STATE_IDLE 0        // Ghost is ready to find somewhere to go
#define STATE_ROAM 1        // Ghost is roaming towards a position
#define STATE_PATHING 2     // Ghost is pathing towards a room
#define STATE_CHASING 3     // Ghost is chasing a player
#define STATE_EVENT 4       // Ghost is doing an event, and shouldn't be interfered with
#define STATE_HUNT_PRE 5	// Waiting to start the hunt


// Settings
#define BFL_PAUSE 0x1		// Pause the ghost, used for debugging.
#define BFL_HUNTING 0x2		// Currently hunting for players
#define BFL_ROAMING 0x4		// Ghost is currently exploring the house
#define BFL_VISIBLE 0x8		// Player visible

#define BFL_HUNT_HAS_LOS 0x10	// We currently have line of sight to our target
#define BFL_HUNT_HAS_POS 0x20	// LOS lost, but we have their last visible coordinates
#define BFL_ROAM_REACHED 0x40	// When roam starts this is unset. When roam ends by reaching the target, this is set.
#define BFL_RESET_LFU_ON_FOOTSTEPS 0x80	// Reset last footsteps update when footsteps are heard (applied when rand roaming during a hunt)

#define BFL_GUESS_WRONG 0x100		// Players picked the wrong ghost

integer BFL;


vector roamTarget;          // Position we're roaming towards
key chaseTarget;            // Player we're chasting
float nextRoam;       		// llGetTime() of when we finished the last roam
float lastReturn = -26;		// -26 means it'll have 4 sec to cache the nodes when spawned, then immediately roam

float lastFootSound;		// Used when hunting to generate footsteps
float lastRoomChange;		// Used with hasStrongAffix(ToolSetConst$affix$ghostRoomChange)
float lastSmudge;			// 
#define SMUDGE_TIMEOUT 6
#define isSmudged() (lastSmudge > 0 && llGetTime()-lastSmudge < SMUDGE_TIMEOUT)

vector spawnPos;
#define toggleMesh( visible ) raiseEvent(GhostEvt$visible, visible)

setState( int st ){
	
	if( STATE == st )
		return;
		
	if( st == STATE_IDLE )
		nextRoam = llGetTime()+1+llFrand(5);

	if( STATE == STATE_CHASING )
		chaseFailed = 0;
		
	if( STATE == STATE_PATHING ){
	
		BFL = BFL&~BFL_ROAM_REACHED;
		roamTimeout = llGetTime()+60;
		
	}
	
	if( STATE != STATE_PATHING )
		BFL = BFL&~BFL_RESET_LFU_ON_FOOTSTEPS;
		
	STATE = st;
	//llSetText((str)STATE, ONE_VECTOR, 1);
	
}


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

warpTo( vector pos ){

	setState(STATE_IDLE);
	toggleWalking(FALSE);
	llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
	llSleep(.25);
	llSetRegionPos(pos);
	
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
	if( BFL & BFL_HUNTING )
		speed = 1.2;
	if( BFL & BFL_HUNTING && BFL & BFL_HUNT_HAS_LOS ){
		
		speed = 1.2+(llGetTime()-timeLOS)/4;
		
		// GHOST BEHAVIOR :: Asswang - Slow down while chasing a player if observed
		if( GHOST_TYPE == GhostConst$type$asswang ){
			
			vector gp = llGetPos();
			speed = 2.5;
			forPlayer( i, p )
				
				vector pp = prPos(p);
				list ray = llCastRay(gp, pp, RC_DEFAULT);
				myAngX(p, ang)
				if( llFabs(ang) < PI_BY_TWO && l2i(ray, -1) < 1 ){
					speed = 0.75;
					i = count(PLAYERS);
				}
				
			end
			
		}
		
		if( speed > 2.5 )
			speed = 2.5;
	
	}
	
	if( hasStrongAffix(ToolSetConst$affix$ghostSpeed) )
		speed *= 1.2;

	// Find where to step
	vector fwd = llVecNorm(<pp.x, pp.y, 0>-<gp.x, gp.y, 0>)*speed;
	
	// Can step up on heights hip level or 1m below
	ray = ignoreDoor(llCastRay(gp, gp+fwd-<0,0,2+hover>, RC_DEFAULT + RC_DATA_FLAGS + RC_GET_NORMAL + RC_MAX_HITS + 3 ), TRUE);
	vector v = l2v(ray, 2);
	list fwdRay = ignoreDoor(llCastRay(gp, gp+fwd*.5, RC_DEFAULT + RC_MAX_HITS + 3 ), true);

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

	for(; i < count(ray)/n && count(ray) > 1; ++i ){
	
		list door = getDoorData(l2k(ray, i*n));
		if( door != [] ){
		
			ray = llDeleteSubList(ray, i*n, i*n+n-1);
			--i;
			
		}
	
	}
	
	ray = llListReplaceList(ray, (list)(count(ray)/n), -1, -1);	
	return ray;
	
	
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
list playerFootsteps;		// Same index as PLAYERS. Contains vector positions of where players 
float huntLastFootstepReq;
float chaseFailed;			// Time when ghost got stuck with LOS
float lastFootstepsUpdate;	// Limits how often we can run the footstep check
float timeLOS;				// Time when we got line of sight
int easyMode = TRUE;
key caughtSeat;				// UUID of seat to put player on
key caughtHud;				// HUD of caught player
float roamTimeout;

vector getPlayerVisibilityPos( key player ){
	
	vector as = llGetAgentSize(player);
	integer ainfo = llGetAgentInfo(player);
	float z = as.z/2-.1;
	if( ainfo & AGENT_CROUCHING )
		z = 0;
	return prPos(player)+<0,0,z>;

}

// Player walked or talked
addFootsteps( key player ){
	// Ignore dead
	if( llGetAgentInfo(player) & AGENT_SITTING )
		return;
	
	vector pos = prPos(player);
	integer index = llListFindList(PLAYERS, (list)((str)player));
	// GHOST BEHAVIOR :: Succubus - Only hear victim footsteps
	if( GHOST_TYPE == GhostConst$type$succubus && player != GhostGet$sucTarg(llGetObjectDesc()) )
		return;
		
	playerFootsteps = llListReplaceList(playerFootsteps, (list)pos, index, index);	// Added footsteps
	if( BFL&BFL_RESET_LFU_ON_FOOTSTEPS ){
		BFL = BFL&~BFL_RESET_LFU_ON_FOOTSTEPS;
		lastFootstepsUpdate = 0;
	}

	// Now figure out if we should force go to the footsteps (walking/talking in the same room as the ghost)

	// Only valid when hunting, not waiting for hunt to start, and we're not smudged
	if( ~BFL&BFL_HUNTING || STATE == STATE_HUNT_PRE || isSmudged() )
		return;
	
	// If there's a hunt target and it's not this player, ignore. Because we should have LoS to that one.
	if( huntTarget != "" && huntTarget != player )
		return;

	// Don't directly walk to target if they're in a different room
	if( pointInRoom(pos) != pointInRoom(llGetPos()) )
		return;
	
	//qd("Updating POS by footsteps");
	// Home in through walls and cover
	huntLastSeenPos = pos;
	huntTarget = player;
	BFL = BFL|BFL_HUNT_HAS_POS;
	
	setState(STATE_CHASING);
		
}

// Fetches a random room you're not currently in to walk to
// ignore is the cNodes index of a room to ignore
randomRoam( int ignore ){

	list viable;	// List of indexes to the first element of each cNode stride with a viable position
	int slice;
	for(; slice < count(cNodes); slice += NodesConst$rmStride ){
		
		if( slice != ignore )
			viable += slice;
		
	}
	slice = l2i(viable, floor(llFrand(count(viable))));
	Nodes$getPath( GhostMethod$followNodes, llGetPos(), l2v(cNodes, slice+1) );
	
}



// IT BEGINS //


#include "ObstacleScript/begin.lsl"

handleTimer( "A" )

	if( BFL & BFL_PAUSE ){
		
		toggleWalking(FALSE);
		llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
		return;
		
	}
	
	vector g = llGetPos();
	int curRoom = pointInRoom(g);
	
	bool smudged = isSmudged();
	
	if( BFL&BFL_HUNTING ){

		// listen for player footsteps
		// GHOST BEHAVIOR :: yaoikai - Deaf
		if( llGetTime()-lastFootstepsUpdate > 1.0 && GHOST_TYPE != GhostConst$type$yaoikai ){
		
			lastFootstepsUpdate = llGetTime();
			forPlayer( index, player )
				
				integer ainfo = llGetAgentInfo(player);
				vector pp = prPos(player);
				
				// Check if walking
				if( 
					// Walk detect, only when not sneaking
					(
						ainfo & AGENT_WALKING &&
						!(ainfo&(AGENT_CROUCHING|AGENT_SITTING)) 
					) ||
					// Type detect, always
					ainfo & AGENT_TYPING
				)addFootsteps(player);
			
			end
		
		}
		
		
		int lospos = BFL&(BFL_HUNT_HAS_LOS|BFL_HUNT_HAS_POS);
		
		// Start chasing after the setup phase
		// Find players with raycast
		if( STATE != STATE_HUNT_PRE && !smudged ){
					
			// First see if we can still see our tracked target
			if( llKey2Name(huntTarget) != "" && ~llGetAgentInfo(huntTarget) & AGENT_SITTING ){
			
				vector tp = getPlayerVisibilityPos(huntTarget);
				list ray = llCastRay(g, tp, RC_DEFAULT);
				// we have LOS to the player
				if( 
					l2i(ray, -1) == 0 && 						// Have LoS
					~pointInRoom(tp)	 						// Inside house
				){
					
					if( ~BFL&BFL_HUNT_HAS_LOS ){
						
						timeLOS = llGetTime();
						BFL = BFL|BFL_HUNT_HAS_LOS;
						BFL = BFL|BFL_HUNT_HAS_POS;
						huntLastSeenPos = tp;
						
						//qd("Now have LOS and last seen pos" + huntLastSeenPos);
						setState(STATE_CHASING);
						bdbg("LOS to "+llKey2Name(huntTarget)+" ("+(str)huntLastSeenPos+")");
					
					}
					
				}
				// We no longer have LOS. BFL_HUNT_HAS_POS will still be set tho
				else if( BFL & BFL_HUNT_HAS_LOS ){
				
					BFL = BFL &~BFL_HUNT_HAS_LOS;
					bdbg("Lost LOS, tracking last seen position");
					//qd("No longer have LOS, but we have POS");
					
				}
			
			}
			
			
			// Next we'll do a LOS check. Because LOS can allow you to change target.
			// We're not directly chasing a player. Try a LOS check. This one can override above.
			if( ~BFL&BFL_HUNT_HAS_LOS ){
			
				forPlayer( index, player )
					
					vector pp = getPlayerVisibilityPos(player);
					list ray = llCastRay(g, pp, RC_DEFAULT);
					if( l2i(ray, -1) == 0 && ~llGetAgentInfo(player) & AGENT_SITTING ){
						
						huntTarget = player;
						BFL = BFL|BFL_HUNT_HAS_LOS;
						bdbg("Starting hunt on "+llKey2Name(player));
						//qd("Now hunting " + player);
						index = 9001;
						
					}
				
				end
				
			}

			// If we have a hunt target, but no LOS and aren't pathing towards their last position. Try to find the target's last heard position.
			if( huntTarget != "" && !lospos && STATE != STATE_PATHING ){
			
				integer loc = llListFindList(PLAYERS, (list)((string)huntTarget));
				vector pos = l2v(playerFootsteps, loc);
				if( pos ){
					
					huntLastFootstepReq = llGetTime()+10;	// Give him 10 sec
					
					// We're already in the room, search it for a while
					if( pointInRoom(pos) == curRoom ){
						
						//qd("Searching room");
						bdbg("Reached last seen target's room. Searching for a bit.");
						huntTarget = "";
						
					}
					// We're not in the room, attempt a path fetch
					else{
					
						//qd("We have TARGET footsteps");
						bdbg("Pathing to last seen position "+(str)pos);
						Nodes$getPath( GhostMethod$followNodes, g, pos );
						
					}
					
				}
			
			}
			
			
					
			// At this point we've searched a room for long enough, and should try somewhere else.
			if( llGetTime() > huntLastFootstepReq+4 && STATE != STATE_PATHING && huntTarget == "" && !lospos ){
				
				huntLastFootstepReq = llGetTime()+llFrand(16);	// Randomize the time to search a room.
				float closest; vector pathTo;
				integer i;
				for(; i < count(playerFootsteps); ++i ){
					
					vector v = l2v(playerFootsteps, i);
					float dist = llVecDist(g, v);
					// Look for the shortest place not in this room
					if( v != ZERO_VECTOR && (dist < closest || pathTo == ZERO_VECTOR) && curRoom != pointInRoom(v) ){
						
						pathTo = v;
						closest = dist;
						playerFootsteps = llListReplaceList(playerFootsteps, (list)0, i, i);
					
					}
				
				}
				// We've found a new location where we've heard a player.
				if( pathTo ){
				
					bdbg("Pathing to footsteps at "+(str)pathTo);
					Nodes$getPath( GhostMethod$followNodes, g, pathTo );
					return;
					
				}
				
				bdbg("Pathing to random room");
				// Otherwise, we can just go search elsewhere.
				BFL = BFL|BFL_RESET_LFU_ON_FOOTSTEPS;
				randomRoam(curRoom);
				
			}
		
		}
	
	}

	if( STATE == STATE_IDLE ){
	
		// Min time to stay in a room after going there (both roaming far and going home).
		float roamcd = 30;

		int startRoom = pointInRoom( spawnPos );

		int timedOut = llGetTime()-lastReturn > roamcd;
		// Handle roaming
		if( 
			~BFL&BFL_HUNTING && 
			(
				timedOut || 			// Timeout
				(~BFL&BFL_ROAMING && startRoom != curRoom)	// We accidentally left the ghost room while not roaming
			)
		){
				
			// Go back
			if( startRoom != curRoom ){
			
				// If we need to go back because we accidentally left the ghost room too early, just walk back and nothing else
				if( !timedOut ){
					Nodes$getPath( GhostMethod$followNodes, g, spawnPos );
					return;
				}
			
				BFL = BFL&~BFL_ROAMING;
				// Set this as our new home location (ghost room change affix)
				if( hasStrongAffix(ToolSetConst$affix$ghostRoomChange) && llGetTime()-lastRoomChange > 420 && llFrand(1) < .5 && BFL&BFL_ROAM_REACHED ){
				
					spawnPos = g;
					return;
					
				}
				// GHOST BEHAVIOR :: Gooryo - Teleport back home
				else if( GHOST_TYPE == GhostConst$type$gooryo )
					warpTo(spawnPos);
				else{
					// If not gooryo, request a path home
					Nodes$getPath( GhostMethod$followNodes, g, spawnPos );
				}
				
				lastReturn = llGetTime();	// Stay in the ghost room for longer than when it roams
				lastReturn += 30+llFrand(30);			// Fixed extra time to stay in the ghost room. This is added to roamcd. At least 60-90 sec stay in the ghost room
				lastReturn += 60-20*DIF;	// Increase stay time by up to another min on lower difficulties.
				// GHOST BEHAVIOR :: Orghast - Roam 30% more often
				if( GHOST_TYPE == GhostConst$type$orghast )
					lastReturn = llFloor(lastReturn*0.7);
				
				// GHOST BEHAVIOR :: EHEE - Don't leave the room as much
				if( GHOST_TYPE == GhostConst$type$ehee )
					lastReturn = llFloor(lastReturn*1.5);
					
			}
			// Find a random room
			else{
			
				vector st;	// Succubus target pos
				// GHOST BEHAVIOR :: Succubus - Always wander to your target
				if( GHOST_TYPE == GhostConst$type$succubus )
					st = prPos(GhostGet$sucTarg( llGetObjectDesc() ));
				
				BFL = BFL|BFL_ROAMING;
				lastReturn = llGetTime()+llFrand(30);	// Return in 30-60 sec
				// GHOST BEHAVIOR :: Gooryo - Find a plumbed room to teleport to
				if( GHOST_TYPE == GhostConst$type$gooryo )
					Nodes$getPlumbedRoom( "PL", GhostMethod$cbPlumbing );
				else if( st != ZERO_VECTOR && ~pointInRoom(st) ){
					Nodes$getPath( GhostMethod$followNodes, g, st );
				}	
				// Pick a completely random room
				else
					randomRoam(startRoom);
				
			}
		
		}

		// Walk randomly after reaching a room
		// Find a new place to walk to
		if( llGetTime() > nextRoam || BFL&BFL_HUNTING ){
		
			vector dir = llRot2Fwd(llEuler2Rot(<0,0,llFrand(TWO_PI)>));

			float dist = 1+llFrand(3);	// Can walk 1-4 meters at a time
			vector gp = g-<0,0,.5>;
			
			list ray = llCastRay(gp, gp+dir*dist, RC_DEFAULT);
			if( l2i(ray, -1) == 1 ){
				
				dist = llVecDist(gp, l2v(ray, 1))-1;
				// Too short of a distance
				if( dist < 0 )
					return;
								
			}
			
			roamTarget = g+dir*dist;
			if( 
				pointInRoom(roamTarget) == -1 		// Never leave the house
			)return;
			
			setState(STATE_ROAM);
			
		}
		
	}
	
	// Not actually roaming, just walking randomly in the current room
	else if( STATE == STATE_ROAM ){
	
		// Reached destination
		if( llVecDist(<g.x, g.y, 0>, <roamTarget.x, roamTarget.y, 0>) < .3 ){
		
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
			BFL = BFL|BFL_ROAM_REACHED;
			int startRoom = pointInRoom( spawnPos );
			// Gone home
			if( startRoom == curRoom ){
			
				roamTarget = spawnPos;
				setState(STATE_ROAM);
				
			}
			// Gone into another room
			else{
				setState(STATE_IDLE);
			}		
			return;
			
		}
		
		list data = llGetObjectDetails(l2k(gotoPortals, 0), 
			(list)OBJECT_POS + OBJECT_ROT
		);
		
		vector pp = l2v(data, 0);
		rotation pr = l2r(data, 1);
		
		pp += alignPos;
		
		// In order for stairs to work we need to relax the Z height of seeking
		float zAllow = hover*1.75;
		if( portalState == PS_SEEKING )
			zAllow = 10;
			
		// Reached the node, find the next
		if( (llVecDist(<g.x, g.y, 0>, <pp.x, pp.y, 0>) < .25 && llFabs(g.z-pp.z) < zAllow) || llGetTime() > roamTimeout ){
			
			roamTimeout = llGetTime()+60;	// If it hasn't been able to reach the node in a minute, give up and call an unstuck 
			if( portalState == PS_SEEKING ){
				
				portalState = PS_ALIGNING;
				alignPos = -alignPos;
				
				// Go deeper into the room if possible
				if( count(gotoPortals) < 2 ){
					
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
								
				float dist = llVecDist(pp, g);
				llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
				llSleep(dist/2);
				llSetRegionPos(l2v(ray, 1)+<0,0,hover>);
				
			}
		
		}
	
	}
	
	else if( STATE == STATE_CHASING && !smudged ){
	
		// Chasing a player target
		vector pp = prPos(huntTarget);
		if( ~BFL&BFL_HUNT_HAS_LOS )
			pp = huntLastSeenPos;
			
		list ray = llCastRay(g, pp, RC_DEFAULT);
		
		// Player catch distance is greater than range to reach their last seen position
		float catchDist = 0.5;
		if( BFL & BFL_HUNT_HAS_LOS )
			catchDist = 0.75;
			
		// Caught a player
		if( llVecDist(<g.x, g.y, 0>, <pp.x, pp.y, 0>) < catchDist /*&& l2i(ray, -1) == 0*/ ){
		
			
			if( BFL&BFL_HUNT_HAS_LOS ){
				
				// Tell level
				Level$raiseEvent( LevelCustomType$GHOST, LevelCustomEvt$GHOST$caught, huntTarget );
				toggleWalking(FALSE);
				setState(STATE_EVENT);
				return;
				
			}
			
			BFL = BFL&~BFL_HUNT_HAS_POS;
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
			
				bdbg("Attempting warp in 1.5");
				chaseFailed = llGetTime();
				return;
				
			}
			
			// Warp timer hit, start warping
			else if( llGetTime()-chaseFailed > 1.5 ){
			
				bdbg("Warping");
				llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
				list ray = llCastRay(pp, pp-<0,0,4>, RC_DEFAULT);
				vector ppFloor = pp;
				if( l2i(ray, -1) == 1 )
					ppFloor = l2v(ray, 1)+<0,0,hover>;

				
				integer i;
				for( ; i < 100 && !walkTowards(pp); ++i ){
					
					float dist = llVecDist(g, ppFloor);
					if( dist > .25 )
						dist = .25;
					
					llSetRegionPos(g+(ppFloor-g)*dist);
					llSleep(.2);
					if( dist <= .25 ){
					
						chaseFailed = 0;
						return;		// We have warped to the position
						
					}
					
				}
				
				bdbg("Warp failed");
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

handleMethod( GhostMethod$incorrect )
	BFL = BFL|BFL_GUESS_WRONG;
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
	toggleMesh(false);
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
	cacheNodes();
	
end

onStateEntry()
        
	spawnPos = llGetPos();
    setInterval("A", 0.25);
	Portal$scriptOnline();
	
end

onGhostAuxListen( ch, msg, sender )
	
	if( ~BFL&BFL_HUNTING || ch != 0 )
		return;

	addFootsteps(SENDER_KEY);

end


/* METHODS */
handleOwnerMethod( GhostMethod$toggleHunt )
	
	if( argInt(0) ){
	
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
		toggleMesh(true);
		raiseEvent(GhostEvt$hunt, TRUE);
		llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
		float time = 3;
		if( BFL&BFL_GUESS_WRONG )
			time = 1;
		setTimeout("HUNT", time);	// Start walking
		
	}	
	else{
		
		BFL = BFL&~BFL_HUNTING;
		raiseEvent(GhostEvt$hunt, FALSE);
		
		// Don't warp back if we caught someone
		if( STATE != STATE_EVENT ){
			
			toggleMesh(false);
			setState(STATE_IDLE);
			warpTo(spawnPos);
			llStopSound();
			lastReturn = llGetTime()+20;	// Act like a lesser smudge
			
		}
			
		
	}

end

onGhostEventsBegin( players, type, subtype )

	setState( STATE_EVENT );
	toggleWalking(false);
	llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
	llSleep(.1);
	vector pos = prPos(l2k(players, 0));
	vector g = llGetPos();
	llRotLookAt(
		llRotBetween(<1,0,0>, llVecNorm(<pos.x, pos.y, g.z>-g)), 
		1, 1
	);
	
end
onGhostEventsEnd( players, type, subtype )
	llStopLookAt();
	setState( STATE_IDLE );
end

// Start hunting
handleTimer( "HUNT" )
	setState(STATE_IDLE);
end



handleOwnerMethod( GhostMethod$setType )

	GHOST_TYPE = argInt(0);
	int evidenceType = argInt(1);
	DIF = argInt(2);
	AFFIXES = argInt(3);
	raiseEvent(GhostEvt$type, GHOST_TYPE + evidenceType + AFFIXES + DIF);
	
end

handleOwnerMethod( GhostMethod$smudge )
	
	key smudger = argKey(0);
	vector spos = prPos(smudger);
	bool force = argInt(1);

	if( ~BFL&BFL_HUNTING ){
		
		// If not hunting, smudge only succeeds when used in the ghost room or near the ghost
		if( 
			( pointInRoom(spos) == pointInRoom(spawnPos) ) ||
			llVecDist(llGetPos(), spos) < 6 ||
			force
		){
			
			lastReturn = llGetTime()+180;	// Don't use a long distance roam for 3 minutes
			Level$raiseEvent( LevelCustomType$GHOST, LevelCustomEvt$GHOST$vaped, [] );
			BFL = BFL&~BFL_ROAMING;
			
		}
		
	}
	else{
		lastSmudge = llGetTime();
	}
	
	setState(STATE_IDLE);
	
end

handleOwnerMethod( GhostMethod$cbPlumbing )
	
	if( BFL&BFL_HUNTING )
		return;
			
	str cb = argStr(0);
	vector pos = argVec(1);
	
	list ray = llCastRay(pos, pos-<0,0,3>, RC_DEFAULT);
	if( l2i(ray, -1) == 1 ){
		
		warpTo(l2v(ray, 1)+<0,0,hover>);
		lastReturn = llGetTime();
		
	}
	
end

handleOwnerMethod( GhostMethod$followNodes )
    
    gotoPortals = METHOD_ARGS;
    calculateAlignPos();
	setState(STATE_PATHING);
    
end

handleOwnerMethod( GhostMethod$stop )
    
	int verbose = argInt(1);
	
	BFL = BFL&~BFL_PAUSE;
	if( argInt(0) )
		BFL = BFL|BFL_PAUSE;
		
	if( verbose ){
	
		llOwnerSay("Stop status: " + (str)((BFL&BFL_PAUSE)>0));
		llOwnerSay("Players: " + mkarr(PLAYERS));
		
	}
	
end


handleOwnerMethod( GhostMethod$cbNodes )
	
	Nodes$handleGetRooms(cNodes);
	//qd("Nodes: "+METHOD_ARGS);
			
end


#include "ObstacleScript/end.lsl"


