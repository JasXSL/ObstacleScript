#define USE_STATE_ENTRY
#define USE_ON_REZ
#define USE_LISTEN
#define USE_HUDS
#define USE_TIMER
#define SCRIPT_IS_PLAYER_MANAGER
#define COM_ADDITIONAL (list)((str)llGetOwnerKey(HOST))
#include "ObstacleScript/index.lsl"

int BFL;
list WAITING_SCRIPTS;
#define BFL_GOT_DESC 0x1
#define BFL_GOT_SCRIPTS 0x2

// Received from rezzer
vector SPAWN_POS;
str DESC;
str SPAWN_GROUP;
int PIN;
key HOST;


fetchScripts(){
    
    list ALL = PortalConst$TRACKED_SCRIPTS;
    integer i;
    for(; i < count(ALL); ++i ){
        
        string script = l2s(ALL, i);
        if( llGetInventoryType(script) == INVENTORY_SCRIPT )
            WAITING_SCRIPTS += script;   
  
    }
    
    if( !count(WAITING_SCRIPTS) ){
        
		BFL = BFL|BFL_GOT_SCRIPTS;
		unsetTimer("SC");
        loadComplete();
        return;
        
    }
    
    PIN = llFloor(llFrand(0xFFFFFFF));
    llSetRemoteScriptAccessPin(PIN);
    Screpo$get( PIN, ScrepoConst$SP_LOADED, WAITING_SCRIPTS, false );
	setInterval("SC", 10);
    
}
fetchSelf( bool noDeferred ){
    
    integer PIN = llFloor(llFrand(0xFFFFFFF));
    llSetRemoteScriptAccessPin(PIN);
    Screpo$get( PIN, ScrepoConst$SP_LOADED, llGetScriptName(), noDeferred );
    
}
// Raised when desc is gotten and scripts have loaded
loadComplete(){

	if( BFL&BFL_GOT_SCRIPTS )
		unsetTimer("SC");	// Stop retrying scripts

	//qd(BFL);
	if( ~BFL&(BFL_GOT_DESC|BFL_GOT_SCRIPTS) )
		return;

	// Get players
	Com$updatePortal();
	//qd("Updating portal");

	if( SPAWN_POS != ZERO_VECTOR )
		llSetRegionPos(SPAWN_POS);
	string descOut = DESC;
	if( !PortalHelper$isLive() && descOut != "" )
		descOut = "$"+descOut;
	
	idbSetByIndex(idbTable$PORTAL, idbTable$PORTAL$GROUP, SPAWN_GROUP);
	
	if( descOut != "" )
		llSetObjectDesc(descOut);
	
	raiseEvent(PortalEvt$loadComplete, DESC);
	
	// Tell the rezzer that it can continue. It's put here so we don't overload the Screpo.
	// Needs to go after desc set
	Rezzer$initialized( mySpawner() );
    
}

#include "ObstacleScript/begin.lsl"

handleListenTunnel()
handleDebug()

handleTimer( "SC" )
	
	Screpo$get( PIN, ScrepoConst$SP_LOADED, WAITING_SCRIPTS, false );
	
end

onRez( total )
    
	idbSetByIndex(idbTable$PORTAL, idbTable$PORTAL$STARTPARAM, total);	
    // Start by fetching self
    if( total )
        fetchSelf(false);

end

onStateEntry()

    setupListenTunnel();
    setupDebug(0);

    if( llGetStartParameter() == ScrepoConst$SP_LOADED ){
        
		// Fetch desc
		integer spid = PortalHelper$getSpawnId();
		// Legacy portals set prim text on rez. This can't be changed without recompiling every single asset.
		if( !spid ){
			integer sp = (int)j(l2s(llGetPrimitiveParams((list)PRIM_TEXT), 0), 0);
			spid = PortalHelper$getSpawnIdFromRezParam(sp);
			idbSetByIndex(idbTable$PORTAL, idbTable$PORTAL$STARTPARAM, sp);
		}
		if( !spid ){
			BFL = BFL|BFL_GOT_DESC;
        }else{
			Rezzer$rezzed( mySpawner(), spid );
		}
        fetchScripts();
		
		// No spawn id = no desc needed
		
    }
	else{
		Com$updatePortal();
    }
end


handleOwnerMethod( PortalMethod$reset )

    llOwnerSay("Resetting");
    
	integer n = PortalHelper$getRezParam()&~PortalConst$SP_LIVE;
    idbSetByIndex(idbTable$PORTAL, idbTable$PORTAL$STARTPARAM, n);
    globalAction$resetAll();
    llResetScript();

end

handleOwnerMethod( PortalMethod$remoteLoad )
	
	key targ = argKey(0);
	str script = argStr(1);
	int pin = argInt(2);
	int startParam = argInt(3);
	
	//qd(llGetSubString((str)llGetKey(), 0, 3) + llKey2Name(targ) + ("["+llGetSubString((str)targ, 0, 3)+"]") + script + pin + startParam );
	if( llGetInventoryType(script) == INVENTORY_SCRIPT ){
		
		llRemoteLoadScriptPin(targ, script, pin, TRUE, startParam);
		Screpo$deferredLoad( targ, script );
		
	}
	else
		qd("Requested script "+script+" not found in "+llGetObjectName() );
	
end

handleOwnerMethod( PortalMethod$fetch )
	llOwnerSay("Updating code");
    fetchSelf(true);
end

handleOwnerMethod( PortalMethod$cbPlayers )

	//qd("Got players "+ METHOD_ARGS);
	integer i;
	for(; i < count(METHOD_ARGS); ++i )
		idbSetByIndex(idbTable$PLAYERS, i, argStr(i));
	idbSetIndex(idbTable$PLAYERS, count(METHOD_ARGS));	
	raiseEvent(PortalEvt$playersChanged, []);
	
end
handleOwnerMethod( PortalMethod$cbHUDs )

	integer i;
	for(; i < count(METHOD_ARGS); ++i )
		idbSetByIndex(idbTable$HUDS, i, argStr(i));
	idbSetIndex(idbTable$HUDS, count(METHOD_ARGS));
	
	raiseEvent(PortalEvt$hudsChanged, []);

end
handleOwnerMethod( PortalMethod$cbHost )
	HOST = argKey(0);
end


handleOwnerMethod( PortalMethod$setLive )
    
	
    integer n = PortalHelper$getRezParam()|PortalConst$SP_LIVE;
    idbSetByIndex(idbTable$PORTAL, idbTable$PORTAL$STARTPARAM, n);
    
end

handleOwnerMethod( PortalMethod$kill )
    
    integer type = argInt(0);
    if( 
		(type == PortalConst$KILL_ALL && SPAWN_GROUP != PortalConst$spawnGroup$static) || 
		type == PortalConst$KILL_ALL_STATIC 
	)llDie();
        
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

	if( !llGetAttached() && SPAWN_GROUP != PortalConst$spawnGroup$static )
		Spawner$add(SENDER_KEY);

end

handleOwnerMethod( PortalMethod$init )

	if( BFL&BFL_GOT_DESC )
		return;
	
	BFL = BFL|BFL_GOT_DESC;
	
	
	SPAWN_POS = argVec(0);
	DESC = argStr(1);
	SPAWN_GROUP = argStr(2);

	loadComplete();

end



#include "ObstacleScript/end.lsl"



