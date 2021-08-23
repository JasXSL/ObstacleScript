#define USE_STATE_ENTRY
#define USE_PLAYERS
#define USE_INTERACT
#define USE_TIMER
#define USE_LISTEN

//float minRot = 0;
//float maxRot = PI_BY_TWO;   // 90 deg

float minRot = -PI_BY_TWO;
float maxRot = 0;

string ID;
rotation startRot;

key interactor;
integer locked;

// Offset from player to set the rotation target
vector playerOffset;

#include "ObstacleScript/begin.lsl"

onPortalInteractStarted( hud, pos )

	if( pos == ZERO_VECTOR )
		return;

    rotation r = prRot(hud);
    interactor = hud;
    setInterval("A", 0.05);
    
    playerOffset = (pos-prPos(hud))/r;
    playerOffset.z = 0;
    
    float dist = llVecDist(ZERO_VECTOR, playerOffset);
    if( dist > 2 )
        dist = 2;
    else if( dist < 1 )
        dist = 1;
    playerOffset = llVecNorm(playerOffset)*dist;

    
end

onPortalInteractEnded( hud )
    
    if( hud != interactor )
        return;
    interactor = "";
    unsetInterval("A");

end

handleTimer( "A" )

	if( locked )
		return;
	

    list data = llGetObjectDetails(interactor, (list)OBJECT_POS + OBJECT_ROT);
    vector pos = l2v(data, 0);
    rotation r = l2r(data, 1);
	
    vector iTarg = playerOffset*r + pos;
    vector gp = llGetPos();
    
    // We want to rotate so X is pointing towards iTarg
    iTarg.z = gp.z = 0;
    
    vector vr = llRot2Euler(llRotBetween(<1,0,0>, llVecNorm(iTarg-gp)/startRot));
	
    if( vr.z > maxRot )
        vr.z = maxRot;
    if( vr.z < minRot )
        vr.z = minRot;
    
    llRotLookAt(llEuler2Rot(vr)*startRot, 1, 1);

end





onPortalLoadComplete( desc )

    list data = llJson2List(desc);  
	
	ID = l2s(data, DoorDesc$id);
	minRot = l2i(data, DoorDesc$minRot);
	maxRot = l2f(data, DoorDesc$maxRot);

    startRot = llGetRot();
    
end
onStateEntry()
    
    startRot = llGetRot();
	
	llSetText("", ZERO_VECTOR, 0);
	
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
	
		llRotLookAt(llEuler2Rot(<0,0,l2f(data, 0)>)*startRot, 1, 1);
		
	}
	else if( task == DoorTask$lock ){
			
		locked = l2i(data, 0);
		
	}

	
end




#include "ObstacleScript/end.lsl"
