#define USE_TIMER
#define USE_LISTEN
#define USE_PLAYERS
#define USE_HUDS
#define USE_STATE_ENTRY
#define SCRIPT_IS_PLAYER_MANAGER

float ACC_HOST;     // Timer
key PENDING_HOST;
key HOST;

// Not added to the player list, but is allowed to call methods on us
#define COM_ADDITIONAL (list)((str)llGetOwnerKey(HOST))

#include "ObstacleScript/begin.lsl"
    
    handleDebug()
    handleListenTunnel()

    onStateEntry()
        
        setupListenTunnel();
        setupDebug(0);
        llListen(123321, "", llGetOwner(), "");
        
        _H = (list)llGetKey();
        _P = (list)llGetOwner();
		
		Level$autoJoin();
		
		llListen(3, "", llGetOwner(), "");
        
    end
    
    onListen( ch, msg )
	
		// Listening for hotkeys
		if( ch == 3 ){
			
			Level$raiseEventTarg( HOST, LevelCustomType$HOTKEY, LevelCustomEvt$HOTKEY$press, msg );
			
			return;
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
					_P = (list)((str)llGetOwner()) + (str)llGetOwnerKey(HOST);
					raiseEvent(ComEvt$hostChanged, HOST);
						
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
    
    handleOwnerMethod( ComMethod$updatePortal )
		
		runMethod(prRoot(SENDER_KEY), "Portal", PortalMethod$cbPlayers, PLAYERS);
		runMethod(prRoot(SENDER_KEY), "Portal", PortalMethod$cbHUDs, HUDS);
		runMethod(prRoot(SENDER_KEY), "Portal", PortalMethod$cbHost, HOST);
		
	
	end
    
    handleMethod( ComMethod$players )
        
		// Must be HOST or owner. Owner is to update the host's HUD with players regardless of if they're in the game. As portals must fetch from the host's HUD.
        if( SENDER_KEY == HOST || llGetOwnerKey(SENDER_KEY) == llGetOwner() ){
            
            PLAYERS = METHOD_ARGS;
            globalAction$setPlayers();
			runOmniMethod("Portal", PortalMethod$cbPlayers, PLAYERS);
			
        }
        
    end
	handleMethod( ComMethod$huds )
        
		// Must be HOST or owner. Owner is to update the host's HUD with players regardless of if they're in the game. As portals must fetch from the host's HUD.
        if( SENDER_KEY == HOST || llGetOwnerKey(SENDER_KEY) == llGetOwner() ){
            
            HUDS = METHOD_ARGS;
            globalAction$setHUDs();
			runOmniMethod("Portal", PortalMethod$cbHUDs, HUDS);
	
        }
        
    end
	handleMethod( ComMethod$uninvite )
		
		if( SENDER_KEY == HOST || llGetOwnerKey(SENDER_KEY) == llGetOwner() ){
			
			PLAYERS = [llGetOwner()];
			HUDS = [llGetKey()];
			globalAction$setPlayers();
			globalAction$setHUDs();
			runOmniMethod("Portal", PortalMethod$cbPlayers, PLAYERS);
			runOmniMethod("Portal", PortalMethod$cbHUDs, HUDS);
			
		}
	
	end

#include "ObstacleScript/end.lsl"


