#define USE_STATE_ENTRY
#define USE_PLAYERS
#define USE_INTERACT
#define USE_TIMER
#define USE_LISTEN
#include "ObstacleScript/index.lsl"

float minRot = 0;
float maxRot = 2.35;   // ~90+45 deg
float snap = 0.2;			// Radius where it snaps shut
float maxRange = 5;
/*
float minRot = -2.35;
float maxRot = 0;
*/
string ID;
rotation startRot;

key interactor;
integer locked;

float tmpZ;

integer doorState = 0;		// closed, 1 = partially open, 2 = fully open
setDoorState( integer ds ){
	
	if( ds == doorState )
		return;
		
	// State was 0 and no longer is = Opened
	if( doorState == 0 )
		raiseEvent(DoorEvt$open, []);
	// New state is 0 = closed
	else if( ds == 0 )
		raiseEvent(DoorEvt$close, []);
		
	doorState = ds;

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

setRot( float z ){

	float tz = llFabs(z);
	float mar = llFabs(maxRot);
	float mir = llFabs(minRot);
	if( mar < mir ){
		
		float t = mar;
		mar = mir;
		mir = t;
		
	}
	
	if( tz >= mar )
		setDoorState(2);
	else if( tz <= mir )
		setDoorState(0);
	else
		setDoorState(1);
		
	llRotLookAt(llEuler2Rot(<0,0,z>)*startRot, 1, 1);

}

// Offset from player X to set the rotation target
float playerOffset;

stopInteract(){

	if( interactor )
		raiseEvent(DoorEvt$interactStop, []);
	interactor = "";
    unsetInterval("A");
	
}

#include "ObstacleScript/begin.lsl"

// Pos is where on the door we touched it
onPortalInteractStarted( hud, pos )

	if( pos == ZERO_VECTOR )
		return;

    rotation r = prRot(hud);
    interactor = hud;
    setInterval("A", 0.05);
    
	playerOffset = llVecDist(pos, prPos(hud));
    
    if( playerOffset > 2 )
        playerOffset = 2;
    else if( playerOffset < 1 )
        playerOffset = 1;
		
	raiseEvent(DoorEvt$interactStart, interactor);
    
end

onPortalInteractEnded( hud )
    
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

	setRot(z);

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
		join((list)Desc$TASK_DOOR_STAT + 0, "$")
	;
	
	// Update desc
	llSetObjectDesc(join(tasks, "$$"));
    
end
onStateEntry()
    
    startRot = llGetRot();
	Portal$scriptOnline();
	
	llListen(DoorConst$CHAN, "", "", "");
    
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
	
		setRot(l2f(data, 0));
		stopInteract();
		
	}
	else if( task == DoorTask$setRotPerc ){
	
		setRot(l2f(data, 0)*(maxRot+minRot)-minRot);
		stopInteract();
		
	}
	else if( task == DoorTask$lock ){
			
		locked = l2i(data, 0);
		if( locked )
			stopInteract();
		
	}

	
end




#include "ObstacleScript/end.lsl"
