#define USE_ATTACH
#define USE_STATE_ENTRY
#define USE_TIMER
#define USE_RUN_TIME_PERMISSIONS

#include "ObstacleScript/index.lsl"


toggleAnim( string anim, integer on, float dur, int flags ){
    
    if( llGetInventoryType(anim) != INVENTORY_ANIMATION && anim != "sit" ){
        
        #ifndef AnimHandlerConf$suppressErrors
        qd("Error: Anim not found: "+anim);
        #endif
        return;
        
    }
    
    #ifdef AnimHandlerCfg$beforeAnim
    if( !beforeAnim( anim ) )
        return;
    #endif
	
    int stopFlags = 
        AnimHandler$animFlag$stopOnMove|
        AnimHandler$animFlag$stopOnUnsit
    ;
    
    if( on && flags&stopFlags )
        setInterval("m$"+anim+"$"+(str)flags, 0.25);
    else
        unsetTimersThatStartWith("m$"+anim);
        
    if( on && dur > 0 ){
        setTimeout("e$"+anim, dur);
    }
    else
        unsetTimersThatStartWith("e$"+anim);
        

    if( on )
        llStartAnimation(anim);
    else
        llStopAnimation(anim);
	Com$internalEvent( HudApiEvt$anim, on + anim);
	
}


 



#include "ObstacleScript/begin.lsl"


onTimer( id )

    list spl = split(id, "$");
    string pre = l2s(spl, 0);
    // move
    if( pre == "m" ){
        
        integer f = l2i(spl, 2);
        integer ai = llGetAgentInfo(llGetOwner());
        if( 
            (f & AnimHandler$animFlag$stopOnUnsit && ~ai & AGENT_SITTING) ||
            (f & AnimHandler$animFlag$stopOnMove && ai & AGENT_WALKING) 
        ){
            
            toggleAnim( l2s(spl, 1), FALSE, 0, 0 );
        
        }
        
    }
    // End
    else if( pre == "e" ){
    
        string anim = l2s(spl, 1);
        toggleAnim( anim, FALSE, 0, 0 );
        
    }

end


handleMethod( AnimHandlerMethod$anim )

    if( ~llGetPermissions()&PERMISSION_TRIGGER_ANIMATION ){
                
        #ifndef AnimHandlerConf$suppressErrors
        qd("Error: Anim permissions lacking, reattach  your HUD.");
        #endif
        return;
        
    }
    
    list anims = (list)argStr(0);
    if( llJsonValueType((string)anims, []) == JSON_ARRAY )
        anims = llJson2List((string)anims);
        
    if( llJsonValueType(l2s(anims, 0), []) == JSON_ARRAY )
        anims = llJson2List(randElem(anims));
    
    integer start = argInt(1);
    float dur = argFloat(2);
    integer flags = argInt(3);
    
    if( flags&AnimHandler$animFlag$randomize )
        anims = (list)randElem(anims);
    
    integer i;
    for( ; i<llGetListLength(anims); ++i ){
    
        string anim = llList2String(anims, i);
        integer s = start;
        string a = anim;
        float d = dur;
        int f = flags;
        
        if( llJsonValueType(anim, []) == JSON_OBJECT ){
        
            if( isset(j(anim, "s")) )
                s = (int)j(anim, "s");
            if( isset(j(anim, "f")) )
                f = (int)j(anim, "f");
            if( isset(j(anim, "a")) )
                a = j(anim, "a");
            if( isset(j(anim, "d")) )
                d = (float)j(anim, "d");
            
        }

        toggleAnim(a, s, d, f);
        
    }

end


handleInternalMethod( AnimHandlerMethod$purgeCustomAnimations )
	
	list purge;
	integer i;
	for( ; i < llGetInventoryNumber(INVENTORY_ANIMATION); ++i ){
		
		string name = llGetInventoryName(INVENTORY_ANIMATION, i);
		if( llGetSubString(name, 0, 3) == "HUD:" )
			purge += name;
	
	}
	
	for( i = 0; i < count(purge); ++i )
		llRemoveInventory(l2s(purge, i));
		
	raiseEvent(AnimHandlerEvt$purgeDone, []);
	

end

// Plays a default breast animation so they don't get stuck
onRunTimePermissions( perms )

	if( perms & PERMISSION_TRIGGER_ANIMATION && llGetInventoryType("breasts_default") == INVENTORY_ANIMATION )
		llStartAnimation("breasts_default");

end


onStateEntry()

    memLim(1.5);
    if( llGetAttached() )
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);

end

onAttach( id )
    llResetScript();
end



#include "ObstacleScript/end.lsl"

