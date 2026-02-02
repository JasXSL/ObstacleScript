#define USE_STATE_ENTRY
#define USE_RUN_TIME_PERMISSIONS
#define USE_ATTACH
#define USE_TIMER

#include "ObstacleScript/index.lsl"

bool DETACH;
reqAttach(){
    LevelRepo$canAttach();
}
detach(){

	DETACH = TRUE;
	if( !llGetAttached() )
		llDie();
	else if( llGetPermissions()&PERMISSION_ATTACH )
		llDetachFromAvatar();
	else
		llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
		
}


#include "ObstacleScript/begin.lsl"



onStateEntry()
    
    Portal$scriptOnline();
    LevelRepo$attSpawned();
    if( !llGetAttached() && llGetStartParameter() ){
        
        reqAttach();
        setInterval("chk", 3);
		setInterval("och", 1);
        
    } 
    
end

onAttach( id )
	
	raiseEvent(AttachmentEvt$onAttach, id);

end

onRunTimePermissions( perm )
    
    if( perm & PERMISSION_ATTACH ){
        
		if( DETACH )
			detach();
		else{
			llAttachToAvatarTemp(0);
			unsetTimer("chk");
        }
    }

end

handleOwnerMethod( AttachmentMethod$reqPerm )

    llOwnerSay("@acceptpermission=add");
    llSleep(.2);
    llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);

end

handleOwnerMethod( AttachmentMethod$detach )
	
	if( !llGetStartParameter() )
		return;

	str targ = argStr(0);
	if( targ != llGetObjectName() && targ != "*" )
		return;
	
	detach();
		

end


handleTimer( "chk" )
    
    reqAttach();
    
end

// Checks that the object that rezzed us is still present
handleTimer( "och" )

	if( llKey2Name(mySpawner()) == "" )
		detach();
		
end

#include "ObstacleScript/end.lsl"



