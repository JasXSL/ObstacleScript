#define USE_STATE_ENTRY
#define USE_INTERACT
#define USE_TIMER
#define USE_LISTEN
#include "ObstacleScript/index.lsl"

float minRot = 
#ifdef MIN_ROT
	MIN_ROT
#else
	0
#endif
;

float maxRot = 
#ifdef MAX_ROT
	MAX_ROT
#else
	2.35
#endif
;   // ~90+45 deg
float snap = 0.2;			// Radius where it snaps shut
float maxRange = 5;
/*
float minRot = -2.35;
float maxRot = 0;
*/
string ID;
rotation startRot;

int P_STAIN;

key interactor;
integer locked;

integer doorState;		// closed, 1 = partially open, 2 = fully open
setDoorState( integer ds, int silent ){
	
	if( ds == doorState )
		return;
		
	// State was 0 and no longer is = Opened
	if( doorState == DoorConst$STATE$closed && !silent )
		raiseEvent(DoorEvt$open, []);
	// New state is 0 = closed
	else if( ds == DoorConst$STATE$closed && !silent )
		raiseEvent(DoorEvt$close, []);
		
	doorState = ds;
	
	if( !silent )
		Level$raiseEvent(LevelCustomType$DOOR, LevelCustomEvt$DOOR$state, ID + ds);

	list desc = split(llGetObjectDesc(), "$$");
	integer i;
	for( ; i < count(desc); ++i ){
	
		list spl = split(l2s(desc, i), "$");
		if( l2s(spl, 0) == Desc$TASK_DOOR_STAT ){
		
			if( count(spl) < 2 )
				spl += ds;
			else
				spl = llListReplaceList(spl, (list)ds, 1, 1);
				
			desc = llListReplaceList(desc, (list)join(spl, "$"), i, i);
			llSetObjectDesc(join(desc, "$$"));
			return;
			
		}
	
	}
	
	


}

setRotPerc( float perc, int silent ){
	
	if( llFabs(maxRot) < llFabs(minRot) )
			perc = 1.0-perc;
	
	float r = perc*(maxRot-minRot) + minRot;
	setRot(r, silent);
	stopInteract();

}

setRot( float z, int silent ){

	float tz = llFabs(z);
	float mar = llFabs(maxRot);
	float mir = llFabs(minRot);
	if( mar < mir ){
		
		float t = mar;
		mar = mir;
		mir = t;
		
	}
	
	if( tz >= mar )
		setDoorState(DoorConst$STATE$opened, silent);
	else if( tz <= mir )
		setDoorState(DoorConst$STATE$closed, silent);
	else
		setDoorState(DoorConst$STATE$mid, silent);
		
	llRotLookAt(llEuler2Rot(<0,0,z>)*startRot, 1, 1);

}

// Offset from player X to set the rotation target
float playerOffset;

stopInteract(){

	if( interactor ){
		raiseEvent(DoorEvt$interactStop, []);
		AnimHandler$stop(interactor, "door");
	}
	interactor = "";
    unsetInterval("A");
	
}

#include "ObstacleScript/begin.lsl"

// Pos is where on the door we touched it
onPortalInteractStarted( hud, pos, linkKey )

	if( pos == ZERO_VECTOR )
		return;

	if( locked ){
	
		AnimHandler$start(interactor, "use_world");
		raiseEvent(DoorEvt$interactLocked, interactor);
		return;
		
	}
	
	if( interactor )
		AnimHandler$stop(interactor, "door");
	

    rotation r = prRot(hud);
    interactor = hud;
    setInterval("A", 0.05);
    
	playerOffset = llVecDist(pos, prPos(hud));
    
    if( playerOffset > 2 )
        playerOffset = 2;
    else if( playerOffset < 1 )
        playerOffset = 1;
		
	AnimHandler$start(interactor, "door");
	raiseEvent(DoorEvt$interactStart, interactor);
    
end

onPortalInteractEnded( hud, linkKey )
    
    if( hud != interactor )
        return;
    stopInteract();

end

handleTimer( "A" )

	list data = llGetObjectDetails(interactor, (list)OBJECT_POS + OBJECT_ROT);
	if( llVecDist(llGetPos(), l2v(data, 0)) > maxRange ){
		
		stopInteract();
		return;
		
	}
		
    vector pos = l2v(data, 0);
    rotation r = l2r(data, 1);
	
    vector iTarg = <playerOffset,0,0>*r + pos;
    vector gp = llGetPos();
    
    // We want to rotate so X is pointing towards iTarg
    iTarg.z = gp.z = 0;
    
    vector vr = llRot2Euler(llRotBetween(<1,0,0>, llVecNorm(iTarg-gp)/startRot));
	float z = vr.z;
	
    if( z > maxRot )
        z = maxRot;
		
    if( z < minRot || llFabs(z-minRot) < snap )
        z = minRot;

	setRot(z, false);

end





onPortalLoadComplete( desc )

    list data = llJson2List(desc);  
	
	ID = l2s(data, DoorDesc$id);
	
	integer len = count(data);
	if( len > DoorDesc$minRot )
		minRot = l2f(data, DoorDesc$minRot);
	if( len > DoorDesc$maxRot )
		maxRot = l2f(data, DoorDesc$maxRot);
	if( len > DoorDesc$snapShut )
		snap = l2f(data, DoorDesc$snapShut);
	if( len > DoorDesc$maxRange )
		maxRange = l2f(data, DoorDesc$maxRange);
	
    startRot = llGetRot();
	
	list tasks = (list)
		join((list)Desc$TASK_DESC + "Drag", "$") +
		join((list)Desc$TASK_INTERACT + 1, "$") +
		join((list)Desc$TASK_DOOR_STAT + 0 + ID, "$")
	;
	
	// Update desc
	llSetObjectDesc(join(tasks, "$$"));
    
end
onStateEntry()
    
    startRot = llGetRot();
	Portal$scriptOnline();
	
	llListen(DoorConst$CHAN, "", "", "");
	
	forLink( nr, name )
		
		if( name == "STAIN" )
			P_STAIN = nr;
	
	end
	llSetLinkAlpha(P_STAIN, 0, ALL_SIDES);
    
end

handleTimer( "SL" )
	
	float rot = 0;
	if( doorState == 0 )
		rot = .25+llFrand(.25);
	setRotPerc(rot, FALSE);
	setTimeout("SL", 0.1+llFrand(.5));
	
end
handleTimer( "SLE" )
	unsetTimer("SL");
	stopInteract();
end



onListen( chan, msg )
	
	if( llGetOwnerKey(SENDER_KEY) != llGetOwner() )
		return;
		
	list data = llJson2List(msg);
	
	if( l2s(data, 0) != "*" && l2s(data, 0) != ID )
		return;
	
	integer task = l2i(data, 1);
	data = llDeleteSubList(data, 0, 1);
	
	if( task == DoorTask$setRot ){
	
		setRot(l2f(data, 0), false);
		stopInteract();
		
	}
	else if( task == DoorTask$setRotPerc ){
	
		float perc = l2f(data, 0);
		setRotPerc(perc, FALSE);
		
	}
	else if( task == DoorTask$lock ){
		
		int pre = locked;
		locked = l2i(data, 0);
		if( locked )
			stopInteract();
			
		if( pre != locked )
			raiseEvent(DoorEvt$locked, locked);
		
	}
	else if( task == DoorTask$setStains ){
		
		llSetLinkAlpha(P_STAIN, l2i(data, 0), ALL_SIDES);
		
	}
	else if( task == DoorTask$setRandomPerc && ID != "DO:EXT" ){
		setRotPerc(llFrand(1), TRUE);
	}
	
	else if( task == DoorTask$slam ){
		
		vector pos = prPos(SENDER_KEY);
		vector g = llGetPos();
		float z = llFabs(pos.z-g.z);
		
		if( z > 2 )
			return;
		
		if( llVecDist(pos, g) > 8 )
			return;
			
		float timeout = l2f(data, 0);
		if( timeout < 1 )
			timeout = 1;
		setTimeout("SL", .1);
		setTimeout("SLE", timeout);
		raiseEvent(DoorEvt$interactStart, "");
		
	}

	
end




#include "ObstacleScript/end.lsl"
