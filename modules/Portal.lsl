#define USE_STATE_ENTRY
#define USE_ON_REZ
#define USE_LISTEN

#include "ObstacleScript/index.lsl"

int BFL;
list WAITING_SCRIPTS;
#define BFL_GOT_DESC 0x1

fetchScripts(){
    
    list ALL = PortalConst$TRACKED_SCRIPTS;
    integer i;
    for(; i < count(ALL); ++i ){
        
        string script = l2s(ALL, i);
        if( llGetInventoryType(script) == INVENTORY_SCRIPT )
            WAITING_SCRIPTS += script;   
  
    }
    
    if( !count(WAITING_SCRIPTS) ){
        
        loadComplete();
        return;
        
    }
    
    integer PIN = llFloor(llFrand(0xFFFFFFF));
    llSetRemoteScriptAccessPin(PIN);
    Screpo$get( PIN, ScrepoConst$SP_LOADED, WAITING_SCRIPTS );
    
}
fetchSelf(){
    
    integer PIN = llFloor(llFrand(0xFFFFFFF));
    llSetRemoteScriptAccessPin(PIN);
    Screpo$get( PIN, ScrepoConst$SP_LOADED, llGetScriptName() );
    
}
loadComplete(){
    
    // Fetch desc
	Rezzer$rezzed( mySpawner(), PortalHelper$getSpawnId() );
    llSetRemoteScriptAccessPin(0);
    
}

#include "ObstacleScript/begin.lsl"

handleListenTunnel()
handleDebug()

onRez( total )
    
    llSetText(mkarr(
        total
    ), ZERO_VECTOR, 0);
	
    // Start by fetching self
    if( total )
        fetchSelf();

end

onStateEntry()

    setupListenTunnel();
    setupDebug(0);
        
    if( llGetStartParameter() == ScrepoConst$SP_LOADED ){
        
        fetchScripts();
        
    }
    
end


handleOwnerMethod( PortalMethod$reset )

    llOwnerSay("Resetting");
    list text = PortalHelper$getConf();
    integer n = l2i(text, PortalConst$CF_REZ_PARAM)&~PortalConst$SP_LIVE;
    text = llListReplaceList(
        text, 
        (list)n, 
        PortalConst$CF_REZ_PARAM, 
        PortalConst$CF_REZ_PARAM
    );
    llSetText(mkarr(text), ZERO_VECTOR, 0);
    globalAction$resetAll();
    llResetScript();

end

handleOwnerMethod( PortalMethod$fetch )
	llOwnerSay("Updating code");
    fetchSelf();
end

handleOwnerMethod( PortalMethod$setLive )
    
    list text = PortalHelper$getConf();
    integer n = l2i(text, PortalConst$CF_REZ_PARAM)|PortalConst$SP_LIVE;
    text = llListReplaceList(
        text, 
        (list)n, 
        PortalConst$CF_REZ_PARAM, 
        PortalConst$CF_REZ_PARAM
    );
    llSetText(mkarr(text), ZERO_VECTOR, 0);
    
end

handleOwnerMethod( PortalMethod$kill )
    
    integer type = argInt(0);
    if( type == PortalConst$KILL_ALL )
        llDie();
        
    METHOD_ARGS = llDeleteSubList(METHOD_ARGS, 0, 0);
    if( 
        type == PortalConst$KILL_NAME && 
        ~llListFindList(METHOD_ARGS, (list)llGetObjectName()) 
    )llDie();
    
    else if( 
        type == PortalConst$KILL_ID && 
        ~llListFindList(METHOD_ARGS, (list)PortalHelper$getSpawnId()) 
    )llDie();
    
    
end

handleInternalMethod( PortalMethod$scriptOnline )
    
    string script = argStr(0);
    integer pos = llListFindList(WAITING_SCRIPTS, (list)script);
    if( ~pos ){
        
        WAITING_SCRIPTS = llDeleteSubList(WAITING_SCRIPTS, pos, pos);
        if( WAITING_SCRIPTS == [] )
            loadComplete();
        
    }


end


handleOwnerMethod( PortalMethod$save )

    Spawner$add(SENDER_KEY);

end

handleOwnerMethod( PortalMethod$init )

	if( BFL&BFL_GOT_DESC )
		return;
		
	BFL = BFL|BFL_GOT_DESC;
	
	llSetRegionPos(argVec(0));
	
	string desc = argStr(1);
	string descOut = desc;
	if( !PortalHelper$isLive() )
		descOut = "$"+descOut;
	
	string group = argStr(2);
	list text = PortalHelper$getConf();
	if( count(text) < 2 )
		text += group;
	else
		text = llListReplaceList(text, (list)group, 1, 1);
		
	llSetText(mkarr(text), ZERO_VECTOR, 0);	
	
	if( descOut != "" )
		llSetObjectDesc(descOut);
	raiseEvent(PortalEvt$loadComplete, desc);
    

end



#include "ObstacleScript/end.lsl"



