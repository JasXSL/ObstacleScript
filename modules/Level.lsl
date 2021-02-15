#define USE_ON_REZ
#define USE_STATE_ENTRY
#define USE_TOUCH_START
#define USE_LISTEN
#include "ObstacleScript/index.lsl"

// Todo: remoteloading

integer BFL;
#define BFL_GAME_ACTIVE 0x1

list INVITES;   // key player, int time
list WAITING_SCRIPTS;

updatePlayers(){
    
    globalAction$setPlayers();  
    forPlayer( i, player )
        Com$players( player, PLAYERS );
    end
    
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

	llOwnerSay("Updating level...");
	WAITING_SCRIPTS = LevelConst$REMOTE_SCRIPTS;
	integer pin = (int)llFrand(0xFFFFFFF);
	llSetRemoteScriptAccessPin(pin);
	Screpo$get( pin, 1, WAITING_SCRIPTS );
	
}


#include "ObstacleScript/begin.lsl"

onRez( start )
	
	if( !start )
		updateCode();

end

onStateEntry()
    
    _P = [(str)llGetOwner()];  
    updatePlayers();
    setupListenTunnel();
    setupDebug(0); 
	Com$inviteSuccess(llGetOwner());
	
	if( llGetStartParameter() == 1 ){
		
		llSetRemoteScriptAccessPin(0);
		raiseEvent(LevelEvt$init, []);
		llOwnerSay("Level initialized.");
		
	}
	
	
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
            
            
            integer pos = llListFindList(INVITES, (list)llGetOwnerKey(SENDER_KEY));
            if( ~pos ){
                
                float time = l2f(INVITES, pos+1);
                if( time+60 < llGetTime() )
                    llRegionSayTo(llGetOwnerKey(SENDER_KEY), 0, "Invite timed out, ask for a new one!");
                else{
				
					key owner = llGetOwnerKey(SENDER_KEY);
					if( llListFindList(PLAYERS, [(str)owner]) == -1 )
						PLAYERS += (str)owner;
                    Com$inviteSuccess(SENDER_KEY);
                    updatePlayers();
                    
                }
                    
            }else
                llRegionSayTo(llGetOwnerKey(SENDER_KEY), 0, "Invite missing");
            
        }
		else if( method == LevelMethod$autoJoin ){
		
			key owner = llGetOwnerKey(SENDER_KEY);
			if( ~llListFindList(PLAYERS, [(str)owner]) )
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
        
    
    integer pos = llListFindList(PLAYERS, (list)targ);
    if( ~pos ){
	
		/* Todo: menu to leave game
			PLAYERS = llDeleteSubList(PLAYERS, pos, pos);
			updatePlayers();
			llSay(0, "secondlife:///app/agent/"+targ+"/about has left the game.");
		*/
		
    }
    else
        llDialog(targ, "Ask secondlife:///app/agent/"+(str)llGetOwner()+"/about for an invite!", [], 123);    
    
    

end



handleMethod( LevelMethod$getPlayers )
	
	string senderScript = argStr(1);
	int cbMethod = argInt(0);
	runMethod(SENDER_KEY, senderScript, cbMethod, PLAYERS);

end

// Method
handleInternalMethod( LevelMethod$resetPlayers )
    
    PLAYERS = [(str)llGetOwner()];
    updatePlayers();
    
end

handleMethod( LevelMethod$raiseEvent )
	
	string type = argStr(0);
	if( llGetSubString(type, 0, 1) != "av" && !isMethodByOwnerInline() )
		return;
	
	raiseEvent(LevelEvt$custom, SENDER_KEY + METHOD_ARGS);

end

handleInternalMethod( LevelMethod$invite )
    
    string player = llToLower(argStr(0));
    integer l = AGENT_LIST_PARCEL;
    float DIST = 30;
    if( player != "*" ){
        
        l = AGENT_LIST_REGION;
        DIST = 9001;
        
    }
    list all = llGetAgentList(l, []);
    vector gp = llGetPos();
    
    if( player == "" )
        return;
    
    
    integer invites;
    integer i;
    for(; i < count(all); ++i ){
        
        string pl = l2s(all, i);
        // Not already joined
        if( llListFindList(PLAYERS, (list)pl) == -1 ){
            
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
                (player == "*" || name == player || dn == player) && 
                llVecDist(prPos(pl), gp) < DIST 
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

handleOwnerMethod( LevelMethod$updateAllHudAssets )

	forPlayer( index, player )
		
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
	updateCode();
end

handleInternalMethod( LevelMethod$scriptInit )

	integer pos = llListFindList(WAITING_SCRIPTS, (list)argStr(0));
	if( pos == -1 )
		return;
		
	WAITING_SCRIPTS = llDeleteSubList(WAITING_SCRIPTS, pos, pos);
	if( WAITING_SCRIPTS == [] ){
		
		integer pin = (int)llFrand(0xFFFFFFF);
		llSetRemoteScriptAccessPin(pin);
		Screpo$get( pin, 1, llGetScriptName() );
			
	}

end


#include "ObstacleScript/end.lsl"

