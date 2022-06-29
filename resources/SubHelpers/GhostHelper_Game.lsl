/*
	
*/
#ifndef __GhostHelper_Game
#define __GhostHelper_Game



// Handled by #AUX
#define setGameRestrictions(player)


/*
	Overrides GameHelper
*/
// The game data is stored in a list. Index 0 is ALWAYS the uuid of the player.
// We can define the other data we need to store about each player here, starting from 1
#define PD_DEAD 1           // (int)is_dead
#define PD_AROUSAL 2        // We'll put an llGetTime timestamp here for invul. 0 -> 100
#define PD_CLOTHES 3        // 20 points total, <= 10 for underwear, 0 for naked

// Put default values for above here
#define PD_DEFAULTS [0, 0, 20]
// Set this to the max value of our data fields +1. So if the max field index was 5, we set 6
#define PD_STRIDE 4



// Include the basic stuff, allowing you to only include the ghosthelper in your code
#define USE_STATE_ENTRY
#define USE_PLAYERS
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
int LEVEL_START;    // Unix timestamps
int GHOST_EVENTS;   // Nr ghost events
int OBJ_INTERACTS;  // Object interactions
int PL_INTERACTS;   // Player interactions
int HUNTS;
int AFFIXES;        // 4 bit array, rightmost are for easy affixes, left for hard
int PIGR;           // Num players in ghost room
key GHOST;
integer GHOST_TYPE;
integer SEL = -1;   // Ghost selected by the player
integer EVIDENCE_TYPES;
float ACTIVITY = 1.0;  // Generic multiplier for ghost interacts.
integer DIFFICULTY = 2; //
float LAST_EVENT;
integer BFL;
#define BFL_HUNTING 0x1
#define BFL_FRONT_DOOR 0x2
float LAST_HUNT;
key CAUGHT_PLAYER;  // We're waiting for a bondage seat for this player


// Make some helper macros
#define isPlayerDead( uuid ) \
    getPlayerDataInt(uuid, PD_DEAD)
#define setPlayerDead( uuid, dead ) \
    setPlayerData(uuid, PD_DEAD, dead)

#define getPlayerArousal( uuid ) \
    getPlayerDataFloat(uuid, PD_AROUSAL)
#define setPlayerArousal( uuid, arousal ) \
    setPlayerData(uuid, PD_AROUSAL, arousal)

#define getPlayerClothes( uuid ) \
    getPlayerDataInt(uuid, PD_CLOTHES)
#define setPlayerClothes( uuid, amount ) \
    setPlayerData(uuid, PD_CLOTHES, amount)

float getAverageArousal(){
    
    if( PLAYERS == [] )
        return 0;
    list out;
    integer i;
    for(; i < count(PLAYERS); ++i ){
        if( ~llGetAgentInfo(l2k(PLAYERS, i)) & AGENT_SITTING )
            out += getPlayerArousal(l2k(PLAYERS, i));
    }
    if( out == [] )
        return 0;
    return llListStatistics(LIST_STAT_MEAN, out);
    
}

// Checks if all players are dead
integer allPlayersDead(){

    forPlayer( index, player )
        
        if( !isPlayerDead(player) )
            return FALSE;
        
    end
    return TRUE;
    
}

// Checks if we can start a hunt
// Forwards CTH to tools which checks hornybat
// Tools then forwards CTH to nodes that makes sure players are in the building
checkStartHunt(){

	// Can't start if we're already hunting or an event is active
	if( BFL&BFL_HUNTING || llGetTime() < LAST_EVENT )
		return;
    LAST_HUNT = llGetTime();
    raiseEvent(0, "CTH");

}
// Note: use checkStartHunt on start instead since it checks horny bat
toggleHunt( integer on ){

    float dur = 30+DIFFICULTY*10*(llFrand(0.5)+.5);
    if( on && ~BFL&BFL_HUNTING ){
        
        BFL = BFL|BFL_HUNTING;
        
        
        setTimeout("HUNT_END", dur);
        ++HUNTS;
        
    }
    else if( !on && BFL&BFL_HUNTING ){
        
        BFL = BFL&~BFL_HUNTING;
        unsetTimer("HUNT_END");
        
    }
    else
        return;
    
    int hunting = (BFL&BFL_HUNTING)>0;
    Door$lock( "DO:EXT", hunting );
    if( BFL & BFL_HUNTING ){
        Door$setRotPerc( "DO:EXT", 0 );
        GhostRadio$garble( "*", TRUE );
    }
    else{
        GhostRadio$garble( "*", FALSE );
    }
    LAST_HUNT = llGetTime();
    Ghost$toggleHunt( hunting );
    GhostTool$toggleHunt( hunting, GHOST );
    Lamp$flicker( "*", hunting, dur );
    raiseEvent(0, "HUNT" + hunting);
    
}


updateStatusBoard(){
    
    list arousals;
    forPlayer( i, player )
    
        float arousal = getPlayerArousal(player);
        if( isPlayerDead(player) || hasStrongAffix(ToolSetConst$affix$noArousalMonitor) )
            arousal = -1;
        arousals += (int)arousal;
        
    end
    GhostStatus$updatePlayers( "*", arousals );
    
}

// Events
// Loading game
onGameStart(){
    
    LEVEL_START = llGetUnixTime();  // Set both here and when opening the door
    DIFFICULTY = l2i(GCONF, 0);
    
    // Generate ghost
    SEL = -1;   // Reset generated ghost
    ACTIVITY = llFrand(.8)+.4;   // This is a shuffle multiplied against the ghost type's activity
    GHOST_TYPE = 
    #ifdef FORCE_GHOST
        FORCE_GHOST
    #else
        llFloor(llFrand(15))
    #endif
    ;    
    
    AFFIXES = 0;
    if( DIFFICULTY > 0 )    // 4 rightmost bits = basic affixes
        AFFIXES = AFFIXES | llCeil(llFrand(8));
    if( DIFFICULTY > 1 )
        AFFIXES = AFFIXES | (llCeil(llFrand(8))<<4);
        
    EVIDENCE_TYPES = getEvidenceTypes( GHOST_TYPE );
    raiseEvent(0, "EVIDENCE" + EVIDENCE_TYPES + GHOST_TYPE);
    raiseEvent(0, "DIFFICULTY" + DIFFICULTY );
    sendAffixes();
    
    BFL = 0;
    
}

sendAffixes(){
    raiseEvent(0, "AFFIXES" + AFFIXES);
    GhostBoard$setAffixes( AFFIXES );
    GhostTool$setGhost(GHOST, AFFIXES, EVIDENCE_TYPES, DIFFICULTY);
    Ghost$setType( GHOST_TYPE, EVIDENCE_TYPES, DIFFICULTY, AFFIXES );
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
        GHOST_EVENTS +
        OBJ_INTERACTS +
        PL_INTERACTS +
        HUNTS
    ;
    
}





addArousal( key player, float arousal ){
    
    float cur = getPlayerArousal(player)+arousal;
    if( cur > 100 )
        cur = 100;
    else if( cur < 0 )
        cur = 0;
    setPlayerArousal(player, cur);
    
    updateStatusBoard();
            
}

// Gets distance to the nearest player, reqLos is line of sight:
// 0 = no LOS req
// 1 = LOS req
// 2 = LOS and looking towards the ghost
float gnptgd( int reqLos ){
    
    vector ghost = prPos(GHOST);
    float dist = -1;
    forPlayer( idx, pl )
        
        vector pp = prPos(pl);
        float d = llVecDist(ghost, pp);
        if( (dist < 0 || d < dist) && !isPlayerDead(pl) ){
            
            list ray;
            if( reqLos )
                ray = llCastRay(ghost+<0,0,1>, pp+<0,0,1>, RC_DEFAULT);
            
            prAngX(pl, ang);
            if( reqLos == 2 && llFabs(ang) < PI_BY_TWO )
                ray = [];    
            
            if( l2i(ray, -1) == 0 )
                dist = d;

        }
    
    end
    return dist;
    
}
#define getNearestGhostPlayerDistance( reqLos ) gnptgd( reqLos )



    
onToolsSpawned(){

    raiseEvent(0, "ROUND_START");
    ROUND_START_TIME = llGetTime();
    forPlayer( index, player )
        Rlv$unSit( player, TRUE );
    end
    GSETTINGS = GSETTINGS | GS_ROUND_STARTED;
    
    if( hasStrongAffix(ToolSetConst$affix$vibrator) ){ 
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
#define ghostHelperStateEntry() gameHelperStateEntry() llListen(6, "", llGetOwner(), "");
#define onCountdownFinished() // Unused in this mode



#endif
