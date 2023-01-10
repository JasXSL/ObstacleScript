/*
	
	The event handler for GhostHelper is so big that it's better to have it as an include
	
*/

gameHelperEventHandler() // Parent


// These can be run on channel 6
onListen( ch, msg )
	
    if( msg == "SPAWNGHOST" ){
        
        dbg("Spawning a ghost");
        raiseEvent(0, "SPAWN_GHOST");
        
    }
    else if( msg == "HUNT TEST" ){
        dbg("Trying to start a hunt");
        raiseEvent(0, "START_HUNT");
    }
        
    else if( msg == "HUNT ON" ){
        dbg("Force starting a hunt");
		raiseEvent(0, "TOGGLE_HUNT" + TRUE);
    }
    else if( msg == "HUNT OFF" ){
        dbg("Stopping hunt");
		raiseEvent(0, "TOGGLE_HUNT" + FALSE);
    }
    else if( msg == "AROUSEME" ){
        dbg("Adding 10 arousal to " + SENDER_KEY);
        addArousal(SENDER_KEY, 10);
    }
    else if( msg == "DEBUG" ){
        
		key ghost = GhostGet$ghost();
        dbg("Evidence" + EVIDENCE_TYPES + "GHOST" + GHOST_TYPE);
        raiseEvent(0, "DEBUG");
        
    }
end

onLevelCustomGhostArouse( ghost, players, points )

    int i;
    for(; i < count(players); ++i ){
        //qd("Arousing " + llKey2Name(l2k(players, i))+" points "+points);
        addArousal(l2k(players, i), points);
    }
	
end

onLevelCustomGsboardSpawned( board )
    addArousal("",0); // update status board
end

onLevelCustomToolsetPills( player )
    
    float amount = l2f(([-50,-35,-25,-20]), GhostGet$difficulty());
    addArousal(player, amount);
    
end

// This is the event raised when interacting with the keypad
handleEvent( "#AUX", 0 )

    if( argStr(0) != "ENDGAME" )
		return;
    
	if( BFL&BFL_INCORRECT_HOLD )
		return;
	
	// Correct. End the game
	if( GHOST_TYPE == SEL ){
		endGame();
		return;
	}
	
	// Incorrect.
	forPlayer( t, index, player )
		Rlv$playSound( player, "679d11af-eb84-eb25-32e8-b146de9a80eb", 1.0 );
		addArousal(player, 40);
	end
	raiseEvent(0, "GUESS_WRONG" + 1);	// Have the monitor status text show that the players guessed wrong
	Ghost$incorrect();
	BFL = BFL|BFL_INCORRECT_HOLD|BFL_INCORRECT;

end

handleEvent( "#GhostBehavior", 0 )

	str type = argStr(0);
	// Hunt ended
	if( type == "HUNT" && !argInt(1) ){
		
		BFL = BFL&~BFL_INCORRECT_HOLD;	// Allow players to interact with the keypad again
		raiseEvent(0, "GUESS_WRONG" + 0); // Remove the "wait until next hunt" warning on the monitor
		
	}
	else if( type == "AROUSE" ){
		
		addArousal(argKey(0), argFloat(1));

	}

end

onLevelCustomBondagePlayerDied( chair, player, dead )
    
	int idx = findPdata(player);
    setPlayerDead(idx, dead);
    addArousal("",0); // update status board

    // Player died not on easy mode
    if( GhostGet$difficulty() ){
        raiseEvent(0, "RESET_TOOLS" + player); // Tell tools to drop all this players items
        setTimeout("CW", 6);    // Check team wipe
    }
    
end

// Checks if all players are dead
handleTimer( "CW" )
    
	forPlayer( t, index, player )
        
        if( !isPlayerDead(findPdata(player)) )
            return;
        
    end
	
    // Team wipe
	SEL = -1;
	endGame();

end

onGhostBoardSelect( ghost )
    SEL = ghost;
end

handleEvent( "#Nodes", 0 )

    str type = argStr(0);
    METHOD_ARGS = llDeleteSubList(METHOD_ARGS, 0, 0);
    if( type == "DECAY" ){
        
		list players = getPlayers();
        integer i;
        for(; i < count(METHOD_ARGS) && i < count(players); ++i ){
            
            float amt = argFloat(i);
            if( amt > 0 )
                addArousal(l2k(players, i), amt);
            
        }
        
    }
	else if( type == "AROUSE" ){
		
		//qd("Arousing" + llKey2Name(argKey(1)) + argFloat(2));
		addArousal(argKey(0), argFloat(1));
			
	}
    
end

handleTimer( "startGhost" )

    
    
    
end

onRezzerCb( cb )
    if( cb == "TOOLS" )
        onToolsSpawned();
end

handleTimer( "BRK" )
    Lamp$pop( "BREAKER" );
end

onLevelCustomDoorOpened( label, st )

    if( BFL&BFL_FRONT_DOOR )
        return;
        
    if( label == "DO:EXT" && st != DoorConst$STATE$closed ){
        
		raiseEvent(0, "SPAWN_GHOST");
        BFL = BFL|BFL_FRONT_DOOR;
		raiseEvent(0, "FRONT_DOOR");
        LEVEL_START = llGetUnixTime();
        if( hasWeakAffix(GhostGet$affixes(), ToolSetConst$affix$powerOutage) )
            setTimeout("BRK", 360);  
    }
	
end

// Sent from GhostBoard
onGhostBoardSpawn()
    GhostBoard$setAffixes( AFFIXES );
end

handleEvent( "#Tools", 0 )
    
    str type = argStr(0);
    if( type == "SALTED" || type == "REM_MOTION_AFFIX" ){
        
        integer rem = 0xF;
        if( type == "REM_MOTION_AFFIX" )
            rem = rem = 0xF0;
        AFFIXES = AFFIXES&~rem;
        sendAffixes();
        
    }
    
end

onGhostPower( ghost, args )
    
    // GHOST BEHAVIOR - Obukakke/jim. Adds arousal to players near it when it uses its power
    // Jim can only use it if the power is on tho
    if( GHOST_TYPE == GhostConst$type$obukakke || GHOST_TYPE == GhostConst$type$jim ){
        
        vector gpos = prPos(ghost);
        forPlayer( t, idx, player )
            
            vector pp = prPos(player);
            list ray = llCastRay(gpos, pp+<0,0,.5>, RC_DEFAULT);
            if( l2i(ray, -1) == 0 && llVecDist(gpos, pp) < 5 ){
                
                float amt = 10;
                if( GHOST_TYPE == GhostConst$type$jim )
                    amt = 3;
                addArousal(player, amt);
				
            }
            
        
        end
        
    }
    
end


onLevelCustomGhostSpawned( ghost )

	idbSetByIndex(idbTable$GHOST_SETTINGS, idbTable$GHOST_SETTINGS$GHOST, ghost);
	int difficulty = GhostGet$difficulty();
    Ghost$setType( GHOST_TYPE, EVIDENCE_TYPES, difficulty, AFFIXES );
    GhostTool$setGhost(ghost, AFFIXES, EVIDENCE_TYPES, difficulty);
    
end


onLevelCustomVibrator()
    AFFIXES = AFFIXES&~0xF0;
    sendAffixes();
end


