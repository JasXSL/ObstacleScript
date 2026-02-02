#define USE_TIMER
#define USE_LISTEN
#define USE_HUDS
#define USE_STATE_ENTRY
#define SCRIPT_IS_PLAYER_MANAGER
// Not added to the player list, but is allowed to call methods on us
#define COM_ADDITIONAL (list)((str)llGetOwnerKey(HOST))

#include "ObstacleScript/index.lsl"

float ACC_HOST;     // Timer
key PENDING_HOST;
key HOST;

list API_REG;

resetPlayersAndHuds(){
	// Add ourselves to players and HUDs
	idbSetByIndex(idbTable$PLAYERS, 0, llGetOwner());
	idbSetIndex(idbTable$PLAYERS, 1);
	idbSetByIndex(idbTable$HUDS, 0, llGetKey());
	idbSetIndex(idbTable$HUDS, 1);
}

// If targ is empty, it sends to all
sendApiMessage( key targ, integer evt, list data ){
	list targs = API_REG;
	if( targ )
		targs = [targ];
	int i;
	for( ; i < count(targs); ++i )
		ComApi$runTask(l2k(targs, i), evt, data);

}


#include "ObstacleScript/begin.lsl"
    
    handleDebug()
    handleListenTunnel()

    onStateEntry()
	
		API_REG = [];
        
		// Reset host
		idbSetByIndex(idbTable$COM, idbTable$COM$HOST, HOST);
		
		resetPlayersAndHuds();
		
        setupListenTunnel();
        setupDebug(0);
        llListen(123321, "", llGetOwner(), "");
        
		Level$autoJoin();
		
		llListen(3, "", llGetOwner(), "");
		
		llListen(ComConst$API_CHAN, "", "", "");
		llListen(ComConst$API_CHAN_HOST, "", "", "");
		ComApi$runTaskAll(ComApiTask$fromHud$scriptInit, []);
		setInterval("PRUNE", 10);
        
    end
	
	handleTimer("PRUNE")
	
		integer i = count(API_REG);
		while( i-- ){
			if( llKey2Name(l2k(API_REG, i)) == "" )
				API_REG = llDeleteSubList(API_REG, i, i);
		}
	
	end
	
	handleMethod( ComMethod$internalEvent )
		sendApiMessage("", ComApiTask$fromHud$internalEvent, METHOD_ARGS);
	end
	   
    onListen( ch, msg )
	
		// Listening for hotkeys
		if( ch == 3 ){
			
			Level$raiseEventTarg( HOST, LevelCustomType$HOTKEY, LevelCustomEvt$HOTKEY$press, msg );
			
			return;
		}
		
		if( ch == ComConst$API_CHAN || ch == ComConst$API_CHAN_HOST ){
		
			key owner = llGetOwnerKey(SENDER_KEY);
			if( owner != llGetOwner() && (owner != HOST || ch != ComConst$API_CHAN_HOST))
				return;
		
			list args = llJson2List(msg);
			if( l2s(args, 0) != "XC!" )
				return;
			int task = l2i(args, 1);
			
			// Limit host channel
			if( ch == ComConst$API_CHAN_HOST && task != ComApiTask$toHud$gameEvent )
				return;
			
			args = llDeleteSubList(args, 0, 1);
			
			// Script connected
			if( task == ComApiTask$toHud$connect ){
			
				integer pos = llListFindList(API_REG, (list)SENDER_KEY);
				if( pos == -1 )
					API_REG += SENDER_KEY;
				sendApiMessage(SENDER_KEY, ComApiTask$fromHud$connected, []);
				
			}
			else if( task == ComApiTask$toHud$disconnect ){
				
				integer pos = llListFindList(API_REG, (list)SENDER_KEY);
				if( ~pos )
					API_REG = llDeleteSubList(API_REG, pos, pos);
				
			}
			else if( task == ComApiTask$toHud$getHuds ){
				sendApiMessage(SENDER_KEY, ComApiTask$fromHud$huds, [mkarr(getHuds())]);
			}
			else if( task == ComApiTask$toHud$getHost ){
				sendApiMessage(SENDER_KEY, ComApiTask$fromHud$host, [HOST]);
			}
			else if( task == ComApiTask$toHud$gameEvent ){
				sendApiMessage("", ComApiTask$fromHud$gameEvent, SENDER_KEY + args);
			}
			
		
		}
    
        if( ch == PUB_CHAN ){
            
            list parse = llJson2List(msg);
            if( l2s(parse, 0) == llGetScriptName() ){
                
                integer method = l2i(parse, 1)&0xFF;
                string sender = "secondlife:///app/agent/"+(str)llGetOwnerKey(SENDER_KEY)+"/about";
                
                if( method == ComMethod$invite ){
                    
                    ACC_HOST = 0;
                    PENDING_HOST = SENDER_KEY;
                    llDialog(
                        llGetOwner(), 
                        "Do you want to join "+sender+" 's game?", 
                        ["Yep!","Nope"], 
                        123321
                    );
                    
                }
                else if( 
                    method == ComMethod$inviteSuccess && 
					//HOST != SENDER_KEY && Useful to raise regardless of if it's the same, while debugging
					(
						(
							ACC_HOST > 0 && 
							SENDER_KEY == PENDING_HOST &&
							llGetTime()-ACC_HOST < 10
						) ||
						llGetOwnerKey(SENDER_KEY) == llGetOwner()
					)
                ){
                    
					bool inv = SENDER_KEY == PENDING_HOST;
					PENDING_HOST = "";
					ACC_HOST = 0;
					HOST = SENDER_KEY;
					
					// Rebuild the player table
					idbSetByIndex(idbTable$PLAYERS, 0, llGetOwner());
					idbSetByIndex(idbTable$PLAYERS, 1, llGetOwnerKey(HOST));
					idbSetIndex(idbTable$PLAYERS, 2);
					
					idbSetByIndex(idbTable$COM, idbTable$COM$HOST, HOST);
					sendApiMessage("", ComApiTask$fromHud$host, [HOST]);
					
					raiseEvent(ComEvt$hostChanged, []);
						
					if( inv )
						llDialog(
							llGetOwner(), 
							"You have joined "+sender+" 's game!", 
							[], 
							123
						);
                    
                    
                }            
                
            }
            
        }
        
        else if( ch == 123321 ){
            
            if( PENDING_HOST != "" ){
                
                if( msg == "Nope" )
                    PENDING_HOST = "";
                else if( msg == "Yep!" ){
                    
                    ACC_HOST = llGetTime();
                    Level$acceptInvite(PENDING_HOST);
                    
                }
            }
            
        }
        
    end
	
	handleOwnerMethod( ComMethod$debug )
		qd("Players" + getPlayers());
		qd("Huds "+getHuds());
	end
    
    handleOwnerMethod( ComMethod$updatePortal )
		
		runMethod(prRoot(SENDER_KEY), "Portal", PortalMethod$cbPlayers, getPlayers());
		runMethod(prRoot(SENDER_KEY), "Portal", PortalMethod$cbHUDs, getHuds());
		runMethod(prRoot(SENDER_KEY), "Portal", PortalMethod$cbHost, HOST);
	
	end
    
    handleMethod( ComMethod$players )
        
		// Must be HOST or owner. Owner is to update the host's HUD with players regardless of if they're in the game. As portals must fetch from the host's HUD.
        if( SENDER_KEY == HOST || llGetOwnerKey(SENDER_KEY) == llGetOwner() ){
            
			integer i;
			for(; i < count(METHOD_ARGS); ++i )
				idbSetByIndex(idbTable$PLAYERS, i, argStr(i));
			idbSetIndex(idbTable$PLAYERS, count(METHOD_ARGS));
			runOmniMethod("Portal", PortalMethod$cbPlayers, METHOD_ARGS);
			
        }
        
    end
	handleMethod( ComMethod$huds )
        
		// Must be HOST or owner. Owner is to update the host's HUD with players regardless of if they're in the game. As portals must fetch from the host's HUD.
        if( SENDER_KEY == HOST || llGetOwnerKey(SENDER_KEY) == llGetOwner() ){
            
			integer i;
			for(; i < count(METHOD_ARGS); ++i ){
				idbSetByIndex(idbTable$HUDS, i, argStr(i));
			}
			idbSetIndex(idbTable$HUDS, count(METHOD_ARGS));
			sendApiMessage("", ComApiTask$fromHud$huds, [mkarr(METHOD_ARGS)]);
			runOmniMethod("Portal", PortalMethod$cbHUDs, METHOD_ARGS);
	
        }
        
    end
	handleMethod( ComMethod$uninvite )
		
		if( SENDER_KEY == HOST || llGetOwnerKey(SENDER_KEY) == llGetOwner() ){
			
			resetPlayersAndHuds();
			
			runOmniMethod("Portal", PortalMethod$cbPlayers, getPlayers());
			runOmniMethod("Portal", PortalMethod$cbHUDs, getHuds());
			
		}
	
	end

#include "ObstacleScript/end.lsl"


