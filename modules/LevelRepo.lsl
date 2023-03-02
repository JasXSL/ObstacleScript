/*
	This script installs attachments from the level
*/
#define USE_STATE_ENTRY
#define USE_EVENTS
#define USE_TIMER
#define USE_CHANGED
#include "ObstacleScript/index.lsl"

#define MAX_REQS 10
int REQS = MAX_REQS; 

int BFL;
#define BFL_REQ_CD 0x1

// Tracks attachments that should be kept on
#define ATTACHMENTS_STRIDE 3
list ATTACHMENTS;	// (str)name, (key)id, (int)flags

#define rezAttachment(name) PortalHelper$rez( name, (llGetPos()-<0,0,3>), ZERO_VECTOR, ZERO_ROTATION, TRUE )

// Selective removes only invalid named or permissioned items
purge( integer selective ){
    
    list remove;
    integer i;
    for(; i < llGetInventoryNumber(INVENTORY_ALL); ++i ){

        string n = llGetInventoryName(INVENTORY_ALL, i);
        if( n != llGetScriptName() ){
            
            integer perms = PERM_COPY|PERM_MODIFY|PERM_TRANSFER;
            integer permMask = llGetInventoryPermMask(n, MASK_NEXT);
            bool correctName = llGetSubString(n, 0, 3) == "HUD:";
            bool correctPerm = (permMask&(perms)) == perms;
            
            if( !selective || !correctName || !correctPerm ){
                
                if( !correctName )
                    llOwnerSay("Error: Attempt to install incorrectly named asset into the HUD: "+n);
                if( !correctPerm )
                    llOwnerSay("Error: Attempt to install non fullperm asset into the HUD: "+n);
                
                remove += n;
                
            }
			
        }
                
    }
    
    for( i = 0; i < count(remove); ++i )
        llRemoveInventory(l2s(remove, i));
        
    
}


requestAssets(){
    
    purge(FALSE);
    AnimHandler$purge();
        
}

#include "ObstacleScript/begin.lsl"

onStateEntry()
    setInterval("reqs", 20);
	setInterval("tick", 1);
end

handleTimer( "tick" )
	
	integer i; integer total = count(ATTACHMENTS);
	integer sitting = llGetAgentInfo(llGetOwner()) & AGENT_SITTING;
	for(; i < total; i += ATTACHMENTS_STRIDE ){
	
		if( l2i(ATTACHMENTS, i+2) & LevelRepo$attach$flags$detachOnUnsit && !sitting ){
			
			LevelRepo$detach( LINK_THIS, l2s(ATTACHMENTS, i) );
			
		}
	
	}
	
end

onChanged( change )
    
    if( change & (CHANGED_INVENTORY|CHANGED_ALLOWED_DROP) ){
        
        purge(TRUE);
        
        integer i;
        list anims;
        for( ; i < llGetInventoryNumber(INVENTORY_ANIMATION); ++i ){
            
            string name = llGetInventoryName(INVENTORY_ANIMATION, i);
            if( llGetSubString(name, 0, 3) == "HUD:" )
                anims += name;
            
        }
        
        integer animHandler;
        links_each(nr, name,
            if( name == "AnimHandler" )
                animHandler = nr;
        )
        
        for( i = 0; i < count(anims); ++i ){
            
            string anim = l2s(anims, i);
            llGiveInventory(llGetLinkKey(animHandler), anim);
            llRemoveInventory(anim);
            
        }

    }
end


onComHostChanged()
    
    requestAssets();
    
end


// Have to wait for animhandler to finish purging before we can request new
onAnimHandlerPurge()

    llAllowInventoryDrop(TRUE);
    setTimeout("close", 10);
    Level$getHudAssets(ComGet$host());
    
end





handleOwnerMethod( LevelRepoMethod$canAttach )
	
	if( !REQS || BFL&BFL_REQ_CD )
		return;
		
	BFL = BFL|BFL_REQ_CD;
	setTimeout("reqcd", 1);
	--REQS;
	
	Attachment$reqPerm(SENDER_KEY);
	
end

handleTimer( "reqs" )
	REQS = MAX_REQS;
end

handleTimer( "reqcd" )
	BFL = BFL&~BFL_REQ_CD;
end

handleTimer( "close" )
    llAllowInventoryDrop(FALSE);
end

handleTimer( "attCheck" )

	integer i;
	for(; i < count(ATTACHMENTS); i += ATTACHMENTS_STRIDE ){
	
		key id = l2k(ATTACHMENTS, i+1);
		if( llKey2Name(id) == "" ){
			
			str name = l2s(ATTACHMENTS, i);
			Attachment$detachOmni(name);
			rezAttachment(name);
			
		}
		
	}
	
end

handleMethod( LevelRepoMethod$requestNewAssets ) 
    
    if( llGetOwnerKey(SENDER_KEY) != llGetOwnerKey(ComGet$host()) )
        return;
        
    purge(FALSE);
    requestAssets();

end

handleMethod( LevelRepoMethod$attSpawned )
	
	integer pos = llListFindList(ATTACHMENTS, (list)llKey2Name(SENDER_KEY));
	if( pos == -1 )
		Attachment$detachAll( SENDER_KEY );
	else
		ATTACHMENTS = llListReplaceList(ATTACHMENTS, (list)SENDER_KEY, pos+1, pos+1);

end

handleMethod( LevelRepoMethod$attach )

	integer i;
	for(; i < count(METHOD_ARGS); ++i ){
		
		string name = argStr(i);
		integer flags;
		if( llJsonValueType(name, []) == JSON_OBJECT ){
			
			flags = (int)j(name, LevelRepo$attach$flags);
			name = j(name, LevelRepo$attach$name); // Must go last
			
		}
		
		if( llListFindList(ATTACHMENTS, (list)name) == -1 ){
	
			if( llGetInventoryType(name) != INVENTORY_OBJECT )
				llOwnerSay("Error! Trying to attach missing object: "+name);
			else{
							
				ATTACHMENTS += (list)name + NULL_KEY + flags;
				rezAttachment(name);
				
			}
			
		}
		
	}
	
	// Reset the timer to give it 5 sec to initialize
	setInterval("attCheck", 5);
	

end


handleMethod( LevelRepoMethod$detach )

	if( ~llListFindList(METHOD_ARGS, (list)"*") ){
	
		Attachment$detach("*");
		ATTACHMENTS = [];
		return;
		
	}

	integer i;
	for(; i < count(METHOD_ARGS); ++i ){
		
		str arg = l2s(METHOD_ARGS, i);
		integer att; int br;
		for( ; att < count(ATTACHMENTS) && !br; att += ATTACHMENTS_STRIDE ){
			
			if( arg == l2s(ATTACHMENTS, att) ){
			
				Attachment$detach( arg );
				ATTACHMENTS = llDeleteSubList(ATTACHMENTS, i, i+ATTACHMENTS_STRIDE-1);
				br = true;
				
			}
		
		}
		
		
	}

end



#include "ObstacleScript/end.lsl"



