/*
	
	The event handler for GhostHelper is so big that it's better to have it as an include
	
*/

gameHelperEventHandler() // Parent

// Ghost interactions, hunt timer etc
handleTimer( "TOUCH" )
    
    // Check if it should hunt
    if( BFL & BFL_HUNTING )
        return;
        
    float plDist = getNearestGhostPlayerDistance(0);
    float plDistLos = getNearestGhostPlayerDistance(1);
    
    int huntBlocked = 
        ( // GHOST BEHAVIOR - EHEE No hunt while a player is close or observing
            GHOST_TYPE == GhostConst$type$ehee && 
            (
                (plDist < 2 && plDist >= 0) || 
                (plDistLos < 8 && plDistLos >= 0)
            )
        )
    ;
    
    float avgArousalPerc = getAverageArousal()/100;
    float evtChance = 0.05+0.05*avgArousalPerc;
    
    if( 
        llGetTime()-LAST_EVENT > 60 && // Min 60 sec between
        plDistLos > 0 && plDistLos < 5 && // Needs to be a player within 5m
        avgArousalPerc > 0.3 && // Average arousal needs to be above 30
        llFrand(1.0) < evtChance // 5% chance per tick
    ){
        
        GhostEvents$trigger( GHOST );
        LAST_EVENT = llGetTime();
        ++GHOST_EVENTS;
        return;
        
    }
    
        
    // 20 sec min time between hunts on pro, 40 on intermediate and 60 on novice
    if( llGetTime()-LAST_HUNT > 20+(2-DIFFICULTY)*20 && !huntBlocked && llGetTime()-LAST_EVENT > 15 ){
        // Start hunting at 40 arousal. But small chance.
        
        // Ghost has a min thresh to hunt
        float thresh = 0.4;
        float offs = (float)GhostGet$aggression(prDesc(GHOST))/100.0;
        thresh -= offs/4;   // The threshold is only affected by 1/4th, offs has more impact on chance
        
        float average = avgArousalPerc;
        average += offs; // Ghost aggression also increases average, adding a higher chance
           
        if( average > thresh && llFrand(1.0) < llPow(average,3)*.75 ){
            
            checkToggleHunt();
            //qd("Attempting to trigger a hunt");
            return;
            
        }
        
    }
    
    float activity = 0.5*llPow(0.85, DIFFICULTY); // 15% less interactive per difficulty above easy
    activity *= ACTIVITY;   // Add randomness
    // Get activity from ghost, such as asking for a sign
    activity += GhostGet$activity( prDesc(GHOST) )/100.0;
    
    // GHOST BEHAVIOR :: Hantuwu - Interactivity
    if( GHOST_TYPE == GhostConst$type$hantuwu )
        activity *= (avgArousalPerc/2+0.75);
    
    // GHOST BEHAVIOR :: INUGAMI - Activity based on players in room
    if( GHOST_TYPE == GhostConst$type$inugami ){
        
        if( PIGR )
            activity *= 0.15;   // -85% activity if players are in the room
        else
            activity *= 1.5;    // +50% activity if players are not in the room
        
    }
    
    if( llFrand(1.0) > activity )
        return;
        
    // GHOST BEHAVIOR :: HANTUWU
    if( GHOST_TYPE == GhostConst$type$hantuwu && llFrand(1) > avgArousalPerc )
        return;
    
    GhostInteractions$interact(FALSE);   
    //qd("Sending interact"); 
    
end

handleTimer( "HUNT_END" )
    toggleHunt(FALSE);
end

// These can be run on channel 6
onListen( ch, msg )

    if( msg == "SPAWNGHOST" ){
        
        qd("Spawning a ghost");
        raiseEvent(0, "SPAWN_GHOST");
        
    }
    else if( msg == "HUNT TEST" ){
        qd("Trying to start a hunt");
        checkToggleHunt();
    }
        
    else if( msg == "HUNT ON" ){
        qd("Force starting a hunt");
        toggleHunt(TRUE);
    }
    else if( msg == "HUNT OFF" ){
        qd("Stopping hunt");
        toggleHunt(FALSE);
    }
    else if( msg == "AROUSEME" ){
        qd("Adding 10 arousal to " + SENDER_KEY);
        addArousal(SENDER_KEY, 10);
    }
    else if( msg == "DEBUG" ){
        
        qd("Evidence" + EVIDENCE_TYPES + "GHOST" + GHOST_TYPE + "PIGR" + PIGR + "ANGER" + GhostGet$aggression(prDesc(GHOST)) + "INTERACT" + GhostGet$activity(prDesc(GHOST)));
        raiseEvent(0, "DEBUG");
        
    }
end

onLevelCustomGhostSpawned( ghost )

    GHOST = ghost;
    Ghost$setType( GHOST_TYPE, EVIDENCE_TYPES, DIFFICULTY, AFFIXES );
    GhostTool$setGhost(ghost, AFFIXES, EVIDENCE_TYPES, DIFFICULTY);
    
end

onGhostPower( ghost, args )
    
    // GHOST BEHAVIOR - Obukakke/jim. Adds arousal to players near it during a ghost event
    // Jim can only use it if the power is on tho
    if( GHOST_TYPE == GhostConst$type$obukakke || GHOST_TYPE == GhostConst$type$jim ){
        
        vector gpos = prPos(ghost);
        forPlayer( idx, player )
            
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

onGhostInteraction( ghost, asset, power )
    
    int level = 1+llFloor(llFrand(2));  // 2-3
    if( power ){
        
        level = 3;
        
        
        float plDistLos = getNearestGhostPlayerDistance(true);
        
        if( 
            !hasWeakAffix(ToolSetConst$affix$noEvidenceUntilSalted) &&
            EVIDENCE_TYPES & GhostConst$evidence$owometer && llFrand(1.0) < .5 &&
            // GHOST BEHAVIOR - EHEE - No EMF5 if observed
            (GHOST_TYPE != GhostConst$type$ehee || plDistLos < 0 || plDistLos > 8)
        ) // 4-5
            ++level;
        
    }
    
    if( llGetAgentSize(asset) != ZERO_VECTOR ){
        ++PL_INTERACTS;
    }
    else
        ++OBJ_INTERACTS;
    
    forPlayer( index, player )

        float arousal;
        if( player == asset )
            arousal = 2*((power>0)+1);
        else if( agentLookingAt( player, asset) ){
            
            vector as = llGetAgentSize(player);
            list ray = llCastRay(prPos(player)+<0,0,as.z*.2>, prPos(asset), RC_DEFAULT);
            if( l2i(ray, -1) < 1 || prRoot(l2k(ray, 0)) == asset )
                arousal = 2;
            
            // GHOST BEHAVIOR :: Powoltergeist - More arousal when witnessing a yeet
            if( GHOST_TYPE == GhostConst$type$powoltergeist )
                arousal *= 1.5;
            
        }
    
        if( arousal > 0 )
            addArousal(player, arousal);
        
    end
    
    float dur = 20-DIFFICULTY*4;
    Owometer$addPoint( asset, level, dur );

end

onLevelCustomGhostArouse( ghost, players, points )

    int i;
    for(; i < count(players); ++i ){
        //qd("Arousing " + llKey2Name(l2k(players, i))+" points "+points);
        addArousal(l2k(players, i), points);
    }
    
    
end

onLevelCustomGsboardSpawned( board )
    updateStatusBoard();
end

onLevelCustomToolsetPills( player )
    
    float amount = l2f(([-50,-35,-25,-20]), DIFFICULTY);
    addArousal(player, amount);
    
end

handleEvent( "#AUX", 0 )

    if( argStr(0) == "AROUSE" )
        addArousal(argKey(1), argFloat(2));
    else if( argStr(0) == "ENDGAME" )
        endGame();

end

onLevelCustomGhostCaught( ghost, player )
    
    toggleHunt(FALSE);
    int pos = llListFindList(PLAYERS, [(str)player]);
    if( pos == -1 ){
        qd("Caught player HUD not found");
        return;
    }
        
    CAUGHT_PLAYER = l2k(HUDS, pos);
    Bondage$getFree();
    
end

onLevelCustomBondageFree( chair )
    
    if( CAUGHT_PLAYER == "" )
        return;
        
    Ghost$sendToChair( chair, CAUGHT_PLAYER, (!DIFFICULTY) );
    
end

onLevelCustomBondagePlayerDied( chair, player, dead )
    
    setPlayerDead(player, dead);
    updateStatusBoard();

    // Player died not on easy mode
    if( DIFFICULTY ){
        raiseEvent(0, "RESET_TOOLS" + player);
        setTimeout("CW", 6);    // Check team wipe
    }
    
end

handleTimer( "CW" )
    
    // Team wipe
    if( allPlayersDead() ){
        
        SEL = -1;
        endGame();
        
    }

end

onGhostBoardSelect( ghost )
    SEL = ghost;
end

handleEvent( "#Nodes", 0 )

    str type = argStr(0);
    METHOD_ARGS = llDeleteSubList(METHOD_ARGS, 0, 0);
    if( type == "DECAY" ){
        
        integer i;
        for(; i < count(METHOD_ARGS) && i < count(PLAYERS); ++i ){
            
            float amt = argFloat(i);
            if( amt > 0 )
                addArousal(l2k(PLAYERS, i), amt);
            
        }
        
        
    }
    
    else if( type == "PIGR" )
        PIGR = argInt(0);

end

handleTimer( "startGhost" )

    raiseEvent(0, "SPAWN_GHOST");
    setInterval("TOUCH", 5);
    
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
        
        BFL = BFL|BFL_FRONT_DOOR;
        setTimeout("startGhost", llFrand(5)+1);
        LEVEL_START = llGetUnixTime();
        GHOST_EVENTS = OBJ_INTERACTS = PL_INTERACTS = HUNTS = 0;
        if( hasWeakAffix(ToolSetConst$affix$powerOutage) )
            setTimeout("BRK", 360);  
    }
end

// Sent from GhostBoard
onGhostBoardSpawn()
    GhostBoard$setAffixes( AFFIXES );
end

handleEvent( "#Tools", 0 )
    
    str type = argStr(0);
    if( type == "START_HUNT" )
        toggleHunt(TRUE);
    else if( type == "SALTED" || type == "REM_MOTION_AFFIX" ){
        
        integer rem = 0xF;
        if( type == "REM_MOTION_AFFIX" )
            rem = rem = 0xF0;
        AFFIXES = AFFIXES&~rem;
        sendAffixes();
        
    }
    
end

onLevelCustomVibrator()
    AFFIXES = AFFIXES&~0xF0;
    sendAffixes();
end


