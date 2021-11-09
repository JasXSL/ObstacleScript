#define USE_STATE_ENTRY
#define USE_ON_REZ
#define USE_LISTEN
#define USE_PLAYERS
#define USE_HUDS
#define SCRIPT_IS_PLAYER_MANAGER
#include "ObstacleScript/index.lsl"

int BFL;
list WAITING_SCRIPTS;
#define BFL_GOT_DESC 0x1
#define BFL_GOT_SCRIPTS 0x2

// Received from rezzer
vector SPAWN_POS;
str DESC;
str SPAWN_GROUP;

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
// Raised when desc is gotten and scripts have loaded
loadComplete(){
    
	
	if( ~BFL&(BFL_GOT_DESC|BFL_GOT_SCRIPTS) )
		return;
	
	// Note: If the spawnID is 0 here, you may be overriding llSetText in your asset script
	// Get players
	Level$forceRefreshPortal();

	llSetRegionPos(SPAWN_POS);
	string descOut = DESC;
	if( !PortalHelper$isLive() && descOut != "" )
		descOut = "$"+descOut;
	
	list text = PortalHelper$getConf();
	if( count(text) < 2 )
		text += SPAWN_GROUP;
	else
		text = llListReplaceList(text, (list)SPAWN_GROUP, 1, 1);
		
	llSetText(mkarr(text), ZERO_VECTOR, 0);	
	
	if( descOut != "" )
		llSetObjectDesc(descOut);
	
	raiseEvent(PortalEvt$loadComplete, DESC);
	
    
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
        
		 // Fetch desc
		Rezzer$rezzed( mySpawner(), PortalHelper$getSpawnId() );
        fetchScripts();
        
    }
	else
		Level$forceRefreshPortal();
    
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

handleOwnerMethod( PortalMethod$cbPlayers )

	PLAYERS = METHOD_ARGS;
	globalAction$setPlayers();

end
handleOwnerMethod( PortalMethod$cbHUDs )

	HUDS = METHOD_ARGS;
	globalAction$setHUDs();

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
        if( WAITING_SCRIPTS == [] ){
		
			BFL = BFL | BFL_GOT_SCRIPTS;
			llSetRemoteScriptAccessPin(0);
            loadComplete();
			
		}
        
    }

end

handleMethod( PortalMethod$raiseEvent )
	
	string type = argStr(0);
	if( llGetSubString(type, 0, 1) != "av" && !isMethodByOwnerInline() )
		return;
	
	raiseEvent(PortalEvt$custom, SENDER_KEY + METHOD_ARGS);

end


handleOwnerMethod( PortalMethod$save )

	if( !llGetAttached() )
		Spawner$add(SENDER_KEY);

end

handleOwnerMethod( PortalMethod$init )


	if( BFL&BFL_GOT_DESC )
		return;
	
	// Tell the rezzer that it can continue
	Rezzer$initialized( mySpawner() );
	BFL = BFL|BFL_GOT_DESC;
	
	
	SPAWN_POS = argVec(0);
	DESC = argStr(1);
	SPAWN_GROUP = argStr(2);

	loadComplete();

end



#include "ObstacleScript/end.lsl"



