#ifndef __GameHelper
#define __GameHelper

/*
	!! Remember that if you recompile this script, it goes out of sync with the dialog script.
	!! Make sure to clean up a game and restarting it after recompiling this script or the dialog script

	Things you may wanna use:
	
	// Required event handlers
	onGameStart(){} 	// Raised when the game starts
	onGameEnd(){} 		// Raised when the game ends
	onRoundStart(){}	// Raised when a new round starts
	
	// Functions you can use
	list endGame() 						// Ends the game. This is auto called if you use DialogHelper and end the game through a dialog, but you will want to use this after declaring a winner as well
										// Should return a list of data to pass to the GSCORE global in DialogHelper, This can then be handled in onTextUpdate in the #Dialog
	endRound( float delay )			// Call this to end the current round, triggers onRoundEnd. A delay over 0 will automatically call startRound() after that amount of seconds
	
	startGame() 					// (Optional) Force starts the game. This is auto called if you also use DialogHelper
	startRound() 					// (Optional) Called automatically
	
*/

integer GSETTINGS;
#define GS_ROUND_STARTED 0x1
#define GS_GAME_STARTED 0x2



#define PD_KEY 0            // Element 1 is the player UUID
list PLAYER_DATA;

list GCONF;	// This is custom data passed from DialogHelper

#define resetPlayerData( id ) _rpd(id)
#define setPlayerData( id, index, val ) _spd( id, index, (list)(val))
#define getPlayerDataInt( id, index ) l2i(_gpd(id, index), 0)
#define getPlayerDataStr( id, index ) l2s(_gpd(id, index), 0)
#define getPlayerDataVec( id, index ) l2v(_gpd(id, index), 0)
#define getPlayerDataRot( id, index ) l2r(_gpd(id, index), 0)
#define getPlayerDataFloat( id, index ) l2f(_gpd(id, index), 0)
#define getPlayerDataKey( id, index ) l2k(_gpd(id, index), 0)



// Add this to your state entry handler
#define gameHelperStateEntry() \
	//resetPlayerData(llGetOwner())

#define gameHelperEventHandler() \
	onPlayersUpdated() \
		forPlayer( index, player ) \
			if( llListFindList(PLAYER_DATA, (list)player) == -1 ){ \
				 \
				resetPlayerData(player); \
				 \
			} \
		end \
	end \
	handleEvent( "#Dialog", 0 ) \
		 \
		string type = argStr(0); \
		if( type == "START_GAME" ){ \
			 \
			GCONF = llDeleteSubList(METHOD_ARGS, 0, 0); \
			startGame(); \
			 \
		} \
		else if( type == "END_GAME" ) \
			endGame(); \
		else if( type == "INI" ) \
			llResetScript(); \
		else if( type == "START_ROUND" ) \
			startRound(); \
		\
	end \
	handleTimer( "_ROUND" ) \
		startRound(); \
	end


// Resets player data, if player doesn't exists, it adds
_rpd( key id ){
    
    // Default values, except uuid
    list DEFAULTS = PD_DEFAULTS;
    
    integer pos = llListFindList(PLAYER_DATA, (list)id);
    if( ~pos )
        PLAYER_DATA = llListReplaceList(
            PLAYER_DATA, 
            DEFAULTS, 
            pos+1, 
            pos+PD_STRIDE-1
        );
    else
        PLAYER_DATA += (list)id + DEFAULTS;    
    
}

list _gpd( key player, integer index ){
	
	integer pos = llListFindList(PLAYER_DATA, (list)player);
	if( ~pos )
		return llList2List(PLAYER_DATA, pos+index, pos+index);
	
	return [];
	
}

_spd( key id, integer index, list val ){
    
    integer pos = llListFindList(PLAYER_DATA, (list)id);
    if( pos == -1 )
        return;
    
    val = llList2List(val, 0, 0);
    PLAYER_DATA = llListReplaceList(PLAYER_DATA, val, pos+index, pos+index);
    
}






resetAllPlayers(){

	PLAYER_DATA = [];
	forPlayer( index, player )
		
		resetPlayerData(player);
	
	end

}

startGame(){
	
	resetAllPlayers();
	GSETTINGS = GSETTINGS &~ GS_ROUND_STARTED;
    GSETTINGS = GSETTINGS | GS_GAME_STARTED;
	
	onGameStart();
	
	raiseEvent(0, "START_GAME");
	
}

endGame(){

	GSETTINGS = GSETTINGS &~ GS_GAME_STARTED;
    GSETTINGS = GSETTINGS &~ GS_ROUND_STARTED;
	
	raiseEvent(0, "END_GAME" + onGameEnd());
	
	
}

startRound(){

	onRoundStart();
	
}

endRound( float delay ){

	onRoundEnd();
	if( delay > 0 )
		setTimeout("_ROUND", delay);

}




#endif
