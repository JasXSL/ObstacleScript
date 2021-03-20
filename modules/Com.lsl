#define USE_TIMER
#define USE_LISTEN
#define USE_PLAYERS
#define USE_STATE_ENTRY

float ACC_HOST;     // Timer
key PENDING_HOST;
key HOST;

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
        
    end
    
    onListen( ch, msg )
    
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
    
    
    
    handleMethod( ComMethod$players )
        
        if( SENDER_KEY == HOST ){
            
            PLAYERS = METHOD_ARGS;
            globalAction$setPlayers();
            
        }
        
    end

#include "ObstacleScript/end.lsl"


