#define USE_TIMER
#define USE_STATE_ENTRY
#define USE_CHANGED
#define USE_RUN_TIME_PERMISSIONS
#define USE_LISTEN
#define USE_PLAYERS
#define USE_TOUCH_START
#include "ObstacleScript/headers/Obstacles/Ghost.lsh"
#include "ObstacleScript/index.lsl"

/* CONFIG */
// Hover height when walking
float hover = 1.33;
// Speed when walking
float speed = 1.5;

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
integer ghostType = GhostConst$type$succubus;

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
float nextRoam;       // llGetTime() of when we finished the last roam

setState( int st ){
	
	if( STATE == st )
		return;
		
	if( STATE == STATE_ROAM && st == STATE_IDLE )
		nextRoam = llGetTime()+1+llFrand(5);

	STATE = st;
	
}


// Settings
integer BFL;
#define BFL_PAUSE 0x1		// Pause the ghost, used for debugging.
#define BFL_HUNTING 0x2		// Currently hunting for players
#define BFL_SMUDGE 0x4		// Can only idle. Deaf and blind.



warpToGhostRoom(){
	// Todo: Warp back to ghost room
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
	
	// Door detection
	list ray = llCastRay(gp, pp, RC_DEFAULT);
	if( l2i(ray, -1) ){
		
		key door = l2k(ray, 0);
		list desc = split(prDesc(prRoot(door)), "$$");
		integer i;
		for(; i < count(desc); ++i ){
			
			list spl = split(l2s(desc, i), "$");
			if( l2s(spl, 0) == Desc$TASK_DOOR_STAT && l2i(spl, 1) < 2 )
				Door$setRotPercTarg( prRoot(door), "*", 1 );

		}
		
	}

	// Find where to step
	vector fwd = llVecNorm(<pp.x, pp.y, 0>-<gp.x, gp.y, 0>)*.5;
	// Can step up on heights hip level or 1m below
	ray = llCastRay(gp+fwd, gp+fwd-<0,0,1+hover>, RC_DEFAULT);
	list stepRay = llCastRay(gp, gp+fwd, RC_DEFAULT);
	if( l2i(ray, -1) < 1 || l2i(stepRay, -1) )
		return FALSE;
		
	vector goto = l2v(ray, 1) + <0,0, hover>;
	rotation lookAt = llRotBetween(<1,0,0>, llVecNorm(<goto.x, goto.y, 0>-<gp.x, gp.y, 0>));
	
	float dist = llVecDist(gp, goto);
	llSetKeyframedMotion([goto-gp, lookAt/llGetRot(), dist/speed], []);
	toggleWalking(true);
	
	return TRUE;

}


#include "ObstacleScript/begin.lsl"
handleTimer( "A" )

	if( BFL & BFL_PAUSE ){
		
		toggleWalking(FALSE);
		llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
		return;
		
	}
	
	// Todo: handle hunt tracking
	if( BFL&BFL_HUNTING ){}

	if( STATE == STATE_IDLE ){

		// Find a new target
		if( llGetTime() > nextRoam || BFL&BFL_HUNTING ){
			
			vector dir = llRot2Fwd(llEuler2Rot(<0,0,llFrand(TWO_PI)>));
			float dist = 2+llFrand(5);
			vector gp = llGetPos()-<0,0,.5>;
			list ray = llCastRay(gp, gp+dir*dist, RC_DEFAULT);
			if( l2i(ray, -1) == 1 ){
				
				dist = llVecDist(gp, l2v(ray, 1))-1;
				// Too short of a distance
				if( dist < 0 )
					return;
								
			}
			
			roamTarget = llGetPos()+dir*dist;
			setState(STATE_ROAM);
		
		}
		
	}
	
	else if( STATE == STATE_ROAM ){
	
		// Reached destination
		vector gp = llGetPos();
		if( llVecDist(<gp.x, gp.y, 0>, <roamTarget.x, roamTarget.y, 0>) < .5 ){
		
			toggleWalking(false);
			setState(STATE_IDLE);
			return;
			
		}
	
		// Try walking
		integer att = walkTowards(roamTarget);
		
		// Failed walking, return to idle
		if( !att ){
		
			toggleWalking(false);
			setState(STATE_IDLE);
			return;
			
		}
	
	}
	
	else if( STATE == STATE_PATHING ){
		
		if( !count(gotoPortals) ){
	
			toggleWalking(false);
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
	
	
	}
	else if( STATE == STATE_EVENT ){
	
	}
	
	else if( STATE == STATE_HUNT_PRE ){
	
		// Todo
		
	}

    

end

onStateEntry()
        
    stopAllObjectAnimations()
    llStartObjectAnimation("hugeman_idle");
    //llStartObjectAnimation("hugeman_walk");
    llSitTarget(<.6,0,-.6>, llEuler2Rot(<0,0,PI>));
    setInterval("A", 0.25);
    
end

onChanged( change )

    if( change & CHANGED_LINK ){
        
        key ast = llAvatarOnSitTarget();
        if( ast )
            llRequestPermissions(ast, PERMISSION_TRIGGER_ANIMATION);
        else
            llResetScript();
        
    }
    
end
    
onRunTimePermissions( perm )
    
    if( perm & PERMISSION_TRIGGER_ANIMATION ){
        
        llStartObjectAnimation("hugeman_grab_active");
        llStartAnimation("hugeman_av_grapple");
        llSleep(.5);
        llStartObjectAnimation("hugeman_grab_idle");
        llStartAnimation("hugeman_av_grapple_idle");
        
    }
        
end


/* METHODS */
handleOwnerMethod( GhostMethod$toggleHunt )
	
	
	if( argInt(0) ){
	
		BFL = BFL|BFL_HUNTING;
		setState(STATE_HUNT_PRE);
		
	}	
	else{
		
		BFL = BFL&~BFL_HUNTING;
		setState(STATE_IDLE);
		warpToGhostRoom();
		
	}

end

handleOwnerMethod( GhostMethod$setType )
	ghostType = argInt(0);
end

handleOwnerMethod( GhostMethod$smudge )
	
	warpToGhostRoom();
	
end

handleOwnerMethod( GhostMethod$interact )
	
	// Todo: Find something to interact with
	
end

handleOwnerMethod( GhostMethod$followNodes )
    
    gotoPortals = METHOD_ARGS;
    calculateAlignPos();
	setState(STATE_PATHING);
    
end

handleOwnerMethod( GhostMethod$stop )
    
	BFL = BFL&~BFL_PAUSE;
	if( argInt(0) )
		BFL = BFL|BFL_PAUSE;
    qd("Stop status: " + ((BFL&BFL_PAUSE)>0));
	qd("Players:" + PLAYERS);
	
end



#include "ObstacleScript/end.lsl"


