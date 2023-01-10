/*
	
*/
#ifndef __GhostHelper_Game
#define __GhostHelper_Game

#define dbg(data) llOwnerSay(mkarr(data))

// Handled by #AUX
#define setGameRestrictions(player)

/*
	Overrides GameHelper
*/


// Put default values for above here
#define PD_DEFAULTS [0, 0, 20]
// Set this to the max value of our data fields +1. So if the max field index was 5, we set 6
#define PD_STRIDE 4



// Include the basic stuff, allowing you to only include the ghosthelper in your code
#define USE_STATE_ENTRY
#define USE_TIMER       
#define USE_LISTEN          // Undefine this when not debugging to save memory
#define USE_HUDS
#include "ObstacleScript/index.lsl"
#include "../GameHelper.lsl"
#include "./GhostHelper.lsl"


/*
	Globals
*/


// STATS
int GHOST_TYPE;
int LEVEL_START;    // Unix timestamps
int GHOST_EVENTS;   // Nr ghost events
int OBJ_INTERACTS;  // Object interactions
int PL_INTERACTS;   // Player interactions
int AFFIXES;        // 4 bit array, rightmost are for easy affixes, left for hard


integer SEL = -1;   // Ghost selected by the player
integer EVIDENCE_TYPES;

integer BFL;
#define BFL_FRONT_DOOR 0x2
#define BFL_INCORRECT 0x4			// Players have guessed incorrectly at least once
#define BFL_INCORRECT_HOLD 0x8		// Players can't guess again until after the next hunt




// Events
// Loading game
onGameStart(){
    
    LEVEL_START = llGetUnixTime();  // Set both here and when opening the door
    int difficulty = GhostGet$difficulty();
	
    // Generate ghost
    SEL = -1;   // Reset generated ghost

	GHOST_TYPE = 
	#ifdef FORCE_GHOST
		FORCE_GHOST
	#else
		llFloor(llFrand(15))
	#endif
	;
	idbSetByIndex(idbTable$GHOST_SETTINGS, idbTable$GHOST_SETTINGS$TYPE, GHOST_TYPE); // Update DB ghost type

    AFFIXES = 0;
    if( difficulty > 0 )    // 4 rightmost bits = basic affixes
        AFFIXES = AFFIXES | llCeil(llFrand(8));
    if( difficulty > 1 )
        AFFIXES = AFFIXES | (llCeil(llFrand(8))<<4);
    // Affixes are not constant during a level. DB is written to in sendAffixes
		
	int full = getFullEvidenceTypes(GHOST_TYPE);
    EVIDENCE_TYPES = getDefaultEvidenceTypes(full);
	idbSetByIndex(idbTable$GHOST_SETTINGS, idbTable$GHOST_SETTINGS$EVIDENCE, EVIDENCE_TYPES);
	
	// Nightmare mode
	if( difficulty > 2 ){
		
		int forced = getForcedEvidenceTypes(full);
		list all; int numSet;
		EVIDENCE_TYPES = forced;
		int i;
		for(; i < 16; ++i ){
		
			int n = (1<<i);
			if( forced & n )
				++numSet;
			else if( full & n )
				all += n;
		}
		
		all = llListRandomize(all, 1);
		for( i = 0; i < count(all) && numSet < 2; ++i ){
		
			++numSet;
			EVIDENCE_TYPES = EVIDENCE_TYPES|l2i(all, i);
			
		}
	
	}
	
	
    raiseEvent(0, "GAMESTART");
    sendAffixes();
    
    BFL = 0;
    
}

sendAffixes(){
	idbSetByIndex(idbTable$GHOST_SETTINGS, idbTable$GHOST_SETTINGS$AFFIXES, AFFIXES); // Update DB affixes
    //raiseEvent(0, "AFFIXES" + AFFIXES);
    GhostBoard$setAffixes( AFFIXES );
	int difficulty = GhostGet$difficulty();	// Handled by dialog
    GhostTool$setGhost(GhostGet$ghost(), AFFIXES, EVIDENCE_TYPES, difficulty);
    Ghost$setType( GHOST_TYPE, EVIDENCE_TYPES, difficulty, AFFIXES );
}

list onGameEnd(){

    unsetTimer("startGhost");
    unsetTimer("TOUCH");
    GhostRadio$garble( "*", FALSE );
    setTimeout("START", 2);
    unsetTimer("BRK");
    
    Portal$killAll();
    return (list)
        (GHOST_TYPE == SEL) +
        GHOST_TYPE +
        LEVEL_START +
		// Stats
        llJson2List(
			idbGetByIndex(idbTable$GHOST_BEHAVIOR, idbTable$GHOST_BEHAVIOR$STATS)
		)
    ;
    
}


// Adds arousal and updates the status board. A "" player can be supplied to only update the board.
addArousal( key player, float arousal ){
    
	int idx = findPdata(player);
	if( player != "" && ~idx ){
	
		float cur = getPlayerArousal(idx)+arousal;
		if( cur > 100 )
			cur = 100;
		else if( cur < 0 )
			cur = 0;
		setPlayerArousal(idx, cur);
		
    }
	
	list arousals;
    forPlayer( t, i, pl )
    
		idx = findPdata(pl);
        float arousal = getPlayerArousal(idx);
        if( isPlayerDead(idx) || hasStrongAffix(AFFIXES, ToolSetConst$affix$noArousalMonitor) )
            arousal = -1;
        arousals += (int)arousal;
        
    end
    GhostStatus$updatePlayers( "*", arousals );
            
}

    
onToolsSpawned(){

    raiseEvent(0, "ROUND_START");
    ROUND_START_TIME = llGetTime();
    forPlayer( t, index, player )
        Rlv$unSit( player, TRUE );
    end
    GSETTINGS = GSETTINGS | GS_ROUND_STARTED;
    
    if( hasStrongAffix(AFFIXES, ToolSetConst$affix$vibrator) ){ 
        Spawner$nFromGroup( LINK_THIS, 1, "VIB" ); 
    }
    
}


// Overrides default behavior
startRound(){

    raiseEvent(0, "SPAWN_GEAR");
    
}

/*

	Event handler

*/
// Use GameHelper instead of GhostHelper
#define ghostHelperStateEntry() gameHelperStateEntry() llListen(6, "", llGetOwner(), ""); llOwnerSay((str)llGetUsedMemory());
#define onCountdownFinished() // Unused in this mode



#endif
