#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

str DESC;
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

toggleStains( int on ){

	forLink( link, name )
		
		if( name == "STAINS" )
			llSetLinkAlpha(link, on > 0, ALL_SIDES);
		
	end

}

integer still;

#include "ObstacleScript/begin.lsl"

onStateEntry()
    
	Portal$scriptOnline();
	
	toggleStains(FALSE);
	llCollisionSound("",0);
    
end

handleTimer( "phys" )
    
    float vel = llVecMag(llGetVel());
    if( vel < .05 ){
        
        if( still > 4 ){
            
            unsetTimer("phys");
            llSetStatus(STATUS_PHYSICS, FALSE);
            
        }
        
		++still;
        
    }
    else
        still = 0;    

end

handleOwnerMethod( GhostInteractiveMethod$breaker )
	raiseEvent(GhostInteractiveEvent$breaker, argInt(0));
end

handleOwnerMethod( GhostInteractiveMethod$ping )
	string filter = argStr(0);
	if( filter != "*" && filter != llGetObjectName() )
		return;
	Level$raiseEvent( 
        LevelCustomType$GINTERACTIVE, 
        LevelCustomEvt$GINTERACTIVE$ping,  
        []
    );
end

handleOwnerMethod( GhostInteractiveMethod$interact )

    list dt = getDescType(llGetKey(), Desc$TASK_GHOST_INTERACTIVE);
    int flags = l2i(dt, 1);		// Tells the script what it can handle automatically
	vector dir = l2vs(dt, 2);	// Direction of push if push is enabled
	key sound = l2k(dt, 3);
	
	int intFlags = argInt(0);	// Flags for the method call
	float pushStrength = argFloat(1);
	string nameFilter = argStr(2);
	
	if( nameFilter != "" && nameFilter != llGetObjectName() )
		return;
	
	if( sound ){
	
		float volume = l2f(dt, 4);
		float radius = l2f(dt, 5);
		if( radius <= 0 )
			radius = 10;
		if( volume <= 0 )
			volume = 0.5;
		llSetSoundRadius(radius);
		llPlaySound(sound, volume);
	
	}
	
    // Auto - ~intFlags & GhostInteractiveConst$NO_EVENT makes sure the object doesn't move from an obukakke power
    if( flags & DescConst$GI$auto_push && pushStrength > 0 && ~intFlags & GhostInteractiveConst$NO_EVENT ){
        
        if( dir == ZERO_VECTOR )
            dir = <0,0,1>;
        
		dir *= 2;
        float mag = llVecMag(dir);
        vector offs = llVecNorm(<llFrand(1.0)-.5, llFrand(1.0)-.5, llFrand(1.0)-.5>)*mag;
        llSetStatus(STATUS_PHYSICS, TRUE);
        llSleep(.1);
        llApplyImpulse(offs*llGetMass()*3*pushStrength, TRUE);
        setInterval("phys", 1);
        still = FALSE;
		
		triggerSoundRadius("2cd691be-46dc-ba05-9a08-ed4a8f48a976", .1, 5);
        
    }

	// Handle stains
	if( flags & DescConst$GI$auto_stains && intFlags & GhostInteractiveConst$INTERACT_ALLOW_STAINS ){
		
		toggleStains(TRUE);
		setTimeout("STAINS", 120);
		
	}
    
	if( ~intFlags & GhostInteractiveConst$NO_EVENT )
		raiseEvent(GhostInteractiveEvent$trigger, METHOD_ARGS);
    
    

end



handleTimer("STAINS")
	toggleStains(FALSE);
end

#include "ObstacleScript/end.lsl"



