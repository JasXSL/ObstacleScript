#define USE_ON_REZ
#define USE_STATE_ENTRY
#define USE_TOUCH_START
#define USE_LISTEN
#define USE_TIMER
#define USE_HUDS
#define USE_CHANGED
#define SCRIPT_IS_PLAYER_MANAGER
#include "ObstacleScript/index.lsl"


integer BFL;
#define BFL_GAME_ACTIVE 0x1

list INVITES;   // key player, int time
list WAITING_SCRIPTS;

int MAX_PLAYERS = 64;

updateOwnerPlayers(){
	Com$players( llGetOwner(), getPlayers() );
	Com$huds( llGetOwner(), getHuds() );
}

updatePlayers(){
    
	
	list players = getPlayers();
	list huds = getHuds();
    forPlayer( t, i, player )
        Com$players( player, players );
		Com$huds( player, huds );
    end
	
	if( llListFindList(players, [(str)llGetOwner()]) == -1 )
		updateOwnerPlayers();

	raiseEvent(LevelEvt$playersChanged, []);
	raiseEvent(LevelEvt$hudsChanged, []);
	// The HUDs update portals, since portals will only fetch users from the owner
	
}

invite( key player ){
    
    integer pos = llListFindList(INVITES, (list)player);
    if( ~pos )
        INVITES = llListReplaceList(INVITES, (list)llGetTime(), pos+1, pos+1);
    else
        INVITES += (list)player + llGetTime();    
    
    Com$invite(player);
    
    integer i;
    for(; i < count(INVITES) && count(INVITES); i = i+2 ){
        
        if( l2f(INVITES, i+1)+60 < llGetTime() ){
            
            INVITES = llDeleteSubList(INVITES, i, i+1);
            i = i-2;
            
        }
        
    }
    
}

updateCode(){
	
	WAITING_SCRIPTS = LevelConst$REMOTE_SCRIPTS;
	int i;
	for( ; i < llGetInventoryNumber(INVENTORY_SCRIPT); ++i ){
		
		str name = llGetInventoryName(INVENTORY_SCRIPT, i);
		if( llGetSubString(name, 0, 0) != "#" && llListFindList(WAITING_SCRIPTS, (list)name) == -1 )
			WAITING_SCRIPTS += name;
	
	}
	
	integer pin = (int)llFrand(0xFFFFFFF);
	llSetRemoteScriptAccessPin(pin);
	Screpo$get( pin, (llGetStartParameter()+1), WAITING_SCRIPTS, true );
	
	setInterval("UPDATE", 2);
	
}


#include "ObstacleScript/begin.lsl"

onRez( start )

	llOwnerSay("Updating level ["+(string)start+"], please wear your HUD...");
	idbSetByIndex(idbTable$LEVEL, idbTable$LEVEL$LIVE, (str)start);
	updateCode();
	

end

onStateEntry() 
	
    updatePlayers();
    setupListenTunnel();
    setupDebug(0); 
	Com$inviteSuccess(llGetOwner());
	
	// this was remote loaded
	if( llGetStartParameter() ){
		
		llSetRemoteScriptAccessPin(0);
		raiseEvent(LevelEvt$init, []);
		llOwnerSay("Level initialized.");
		
		// Prune any players who have changed HUD or aren't present
		list players = getPlayers();
		list huds = getHuds();

		idbResetIndex(idbTable$PLAYERS);
		idbResetIndex(idbTable$HUDS);
		
		int i;
		for(; i < count(players); ++i ){
		
			key p = l2k(players, i); key h = l2k(huds, i);
			if( llGetAgentSize(p) != ZERO_VECTOR && llKey2Name(h) != "" ){
				idbInsert(idbTable$PLAYERS, p);
				idbInsert(idbTable$HUDS, h);
			}
		
		}
		updatePlayers();
		
		if( llGetStartParameter() > 1 ){

			vector startPos = (vector)idbGetByIndex(idbTable$LEVEL, idbTable$LEVEL$STARTPOS);
			rotation rot = (rotation)idbGetByIndex(idbTable$LEVEL, idbTable$LEVEL$STARTROT);
			if( startPos ){
				startPos += llGetRootPosition();
				rot *= llGetRootRotation();
				Rlv$teleportPlayer( llGetOwner(), startPos, rot );
			}
			
		}
		
		
	}
	
	
end

// I'm not quite sure why this is needed. I wish past me could have left a note.
onChanged( ch )
	
	llSleep(1);
	raiseEvent(LevelEvt$playersChanged, []);
	raiseEvent(LevelEvt$hudsChanged, []);
	
end

handleListenTunnel()
handleDebug()

onListen( ch, msg )
    if( ch == PUB_CHAN ){
        
        list parse = llJson2List(msg);
		if( l2s(parse, 0) != llGetScriptName() )
			return;
			
			
		int method = (l2i(parse, 1)&0xFF);
				
        if( method == LevelMethod$acceptInvite ){
            
			key owner = llGetOwnerKey(SENDER_KEY);
			integer pos = llListFindList(getPlayers(), [(str)owner]);
			
			if( BFL & BFL_GAME_ACTIVE && pos == -1 )
				return;
            
			
			list players = getPlayers();
			
			if( count(players) >= MAX_PLAYERS && pos == -1 ){
				llRegionSayTo(llGetOwnerKey(SENDER_KEY), 0, "Game is full");
				return;
			}
			
            integer invPos = llListFindList(INVITES, (list)llGetOwnerKey(SENDER_KEY));
            if( ~invPos ){
                
				
                float time = l2f(INVITES, invPos+1);
                if( time+60 < llGetTime() && llListFindList(players, [(str)owner]) == -1 )
                    llRegionSayTo(llGetOwnerKey(SENDER_KEY), 0, "Invite timed out, ask for a new one!");
                else{
				
					
					
					if( pos == -1 ){
					
						idbInsert(idbTable$PLAYERS, owner);
						idbInsert(idbTable$HUDS, SENDER_KEY);
						
					}
					// Player already in the game, but we need to update their HUD
					else{
						
						idbSetByIndex(idbTable$HUDS, pos, SENDER_KEY);
						
					}
					
					raiseEvent(LevelEvt$playerJoined, owner + SENDER_KEY);
					
                    Com$inviteSuccess(SENDER_KEY);
                    updatePlayers();
                    
                }
                    
            }else
                llRegionSayTo(llGetOwnerKey(SENDER_KEY), 0, "Invite missing");
            
        }
		// Player is already in the game, but have detached their HUD
		else if( method == LevelMethod$autoJoin ){
			
			key owner = llGetOwnerKey(SENDER_KEY);
			// Make sure owner has an up to date list of players
			if( owner == llGetOwner() )
				updateOwnerPlayers();
			
			
			int pos = llListFindList(getPlayers(), [(str)owner]);
			if( BFL & BFL_GAME_ACTIVE && pos == -1 )
				return;
		
			if( ~pos )
				invite(owner);

		}
        
    }
end





onTouchStart( total )

    string targ = llDetectedKey(0);
    if( targ == llGetOwner() ){
        raiseEvent(LevelEvt$mainMenu, "");
        return;
    }
    
    if( BFL&BFL_GAME_ACTIVE )
        return;
        
    
    if( isPlayer(targ) ){
	
		/* Todo: menu to leave game
			
		*/
		
    }
    else
        llDialog(targ, "Ask secondlife:///app/agent/"+(str)llGetOwner()+"/about for an invite!", [], 123);    
    
    

end


// Method
handleInternalMethod( LevelMethod$resetPlayers )
    
	forPlayer( t, index, player )
		Com$uninvite( player );
	end

	idbResetIndex(idbTable$PLAYERS);
	idbResetIndex(idbTable$HUDS);
    updatePlayers();
    
end

handleOwnerMethod( LevelMethod$setStartPos )
	
	vector pos = (vector)argStr(0);
	rotation rot = (rotation)argStr(1);
	int global = argInt(2);
	if( global ){
		pos -= llGetRootPosition();
		rot /= llGetRootRotation();
	}

	idbSetByIndex(idbTable$LEVEL, idbTable$LEVEL$STARTPOS, (str)pos);
	idbSetByIndex(idbTable$LEVEL, idbTable$LEVEL$STARTROT, (str)rot);
	llOwnerSay("New start pos set: "+(str)pos+" "+(str)rot);
	
end

handleOwnerMethod( LevelMethod$cleanup )
	if( LevelGet$live() )
		llDie();
end

handleMethod( LevelMethod$raiseEvent )
	
	string type = argStr(0);
	if( llGetSubString(type, 0, 1) != "av" && !isMethodByOwnerInline() ){
		return;
	}
	raiseEvent(LevelEvt$custom, SENDER_KEY + METHOD_ARGS);

end

handleInternalMethod( LevelMethod$invite )
    
    string player = llToLower(argStr(0));
	MAX_PLAYERS = argInt(1);
	if( MAX_PLAYERS < 1 )
		MAX_PLAYERS = 64;
		
	list players = getPlayers();
	int nrPlayers = count(players);
	
    integer l = AGENT_LIST_PARCEL;
    float DIST = 30;
    if( player != "*" ){
        
        l = AGENT_LIST_REGION;
        DIST = 9001;
        
    }
    list all = llGetAgentList(l, []);
	list dist;
	integer i;
	for(; i < count(all); ++i ){
		float d = llVecDist(llGetPos(), prPos(l2k(all, i)));
		if( d < DIST )
			dist += (list)d + l2k(all, i);
	}
	
	dist = llListSort(dist, 2, TRUE);
	all = llDeleteSubList(dist, 0, 0);
	all = llList2ListStrided(all, 0,-1, 2);
	dist = [];
	
    vector gp = llGetPos();
    
    if( player == "" )
        return;
    
	int nrInvites = MAX_PLAYERS-nrPlayers;
	if( nrInvites < 1 ){
		qd("Error, trying to invite more than max players allow");
		return;
	}
    
    integer invites;
    for( i = 0; i < count(all) && invites < nrInvites; ++i ){
        
        string pl = l2s(all, i);
        // Not already joined
        if( llListFindList(players, (list)pl) == -1 ){
            
            integer len = llStringLength(player);
            string name = llGetSubString(
                llToLower(llKey2Name(pl)),
                0,
                len-1
            );
            string dn = llGetSubString(
                llToLower(llGetDisplayName(pl)),
                0,
                len-1
            );
            

            if( 
                (player == "*" || name == player || dn == player)
            ){
                
                llOwnerSay(":: INVITING "+llGetDisplayName(pl));
                invite(pl);
                ++invites;
                
            }
            
        }
        
    }
    
    if( !invites )
        llOwnerSay("No player passed filter");

    
end

handleInternalMethod( LevelMethod$removePlayer )
	
	if( BFL&BFL_GAME_ACTIVE )
		return;
	
	list players = getPlayers();
	integer pos = llListFindList(players, (list)argStr(0));
	if( pos == -1 )
		return;
	list huds = getHuds();
	
	players = llDeleteSubList(players, pos, pos);
	huds = llDeleteSubList(huds, pos, pos);
	
	// Reindex players
	integer i;
	for(; i < count(players); ++i )
		idbSetByIndex(idbTable$PLAYERS, i, l2s(players, i));
	idbSetIndex(idbTable$PLAYERS, count(players));
	
	// Reindex huds
	for( i = 0; i < count(huds); ++i )
		idbSetByIndex(idbTable$HUDS, i, l2s(huds, i));
	idbSetIndex(idbTable$HUDS, count(huds));
	
	Com$uninvite( argStr(0) );
	updatePlayers();

end

handleInternalMethod( LevelMethod$toggleGame )
	
	BFL = BFL&~BFL_GAME_ACTIVE;
	if( argInt(0) )
		BFL = BFL|BFL_GAME_ACTIVE;

end

handleOwnerMethod( LevelMethod$updateAllHudAssets )

	forPlayer( t, index, player )
		
		LevelRepo$requestNewAssets( player );
	
	end

end

handleMethod( LevelMethod$getHudAssets )

	integer i;
	for( ; i < llGetInventoryNumber(INVENTORY_ALL); ++i ){
		
		string name = llGetInventoryName(INVENTORY_ALL, i);
		if( llGetSubString(name, 0, 3) == "HUD:" ){
			
			integer type = llGetInventoryType(name);
			if( type == INVENTORY_OBJECT || type == INVENTORY_ANIMATION )
				llGiveInventory(SENDER_KEY, name);
		
		}
	
	}
	
end

handleOwnerMethod( LevelMethod$update )
	llOwnerSay("Updating level...");
	updateCode();
end

handleInternalMethod( LevelMethod$scriptInit )
	
	integer pos = llListFindList(WAITING_SCRIPTS, (list)argStr(0));
	if( pos == -1 )
		return;
		
	unsetTimer("UPDATE");
	WAITING_SCRIPTS = llDeleteSubList(WAITING_SCRIPTS, pos, pos);
	if( WAITING_SCRIPTS == [] ){
		
		integer pin = (int)llFrand(0xFFFFFFF);
		llSetRemoteScriptAccessPin(pin);
		Screpo$get( pin, llGetStartParameter()+1, llGetScriptName(), true );
			
	}
	
end

handleTimer( "UPDATE" )
	updateCode();
end


#include "ObstacleScript/end.lsl"

