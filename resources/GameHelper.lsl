#ifndef __GameHelper
#define __GameHelper

/*
	!! Remember that if you recompile this script, it goes out of sync with the dialog script.
	!! Make sure to clean up a game and restarting it after recompiling this script or the dialog script

	Things you may wanna use:
	
	// Required event handlers
	onGameStart(){} 			// Raised when the game starts
	list onGameEnd(){} 				// Raised when the game ends
	onRoundStart(){}			// Raised when a new round starts
	onCountdownFinished(){}		// Countdown finished when starting a round
	setGameRestrictions( key player ){}		// Raised on game start and when a player re-joins
	
	// Functions you can use
	list endGame() 						// Ends the game. This is auto called if you use DialogHelper and end the game through a dialog, but you will want to use this after declaring a winner as well
										// Should return a list of data to pass to the GSCORE global in DialogHelper, This can then be handled in onTextUpdate in the #Dialog
	endRound( float delay )			// Call this to end the current round. A delay over 0 will automatically call startRound() after that amount of seconds
	
	startGame() 					// (Optional) Force starts the game. This is auto called if you also use DialogHelper
	startRound() 					// (Optional) Called automatically
	
*/

integer GSETTINGS;
#define GS_ROUND_STARTED 0x1
#define GS_GAME_STARTED 0x2



#define PD_KEY 0            // Element 1 is the player UUID
list PLAYER_DATA;
float ROUND_START_TIME;
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
		onLevelPlayersChanged() \
			forPlayer( tot, index, player ) \
				if( llListFindList(PLAYER_DATA, (list)player) == -1 ){ \
					 \
					resetPlayerData(player); \
					 \
				} \
			end \
		end \
		onLevelPlayerJoined( player, hud ) \
			if( GSETTINGS&GS_GAME_STARTED ) \
				setGameRestrictions(player); \
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
		end \
		handleTimer( "_COUNTDOWN" ) \
			ROUND_START_TIME = llGetTime(); \
			forPlayer( t, index, player ) \
				Rlv$unSit( player, TRUE ); \
			end \
			GSETTINGS = GSETTINGS | GS_ROUND_STARTED; \
			onCountdownFinished(); \
		end


	// Put this directly under the event handler to automatically handle sending back to a checkpoint when falling in the water
	// Z is an offset from the root prim. When beneath this, you get sent back to the checkpoint
	// This requires you to have a function or macro called "getPlayerCheckpoint( key player )" that returns a vector position
	#define gameHelperAutoWater( Z ) \
		onStateEntry() \
			setInterval("_WATER", 3); \
		end \
		handleTimer( "_WATER" ) \
			vector gpos = llGetRootPosition(); \
			if( GSETTINGS & GS_ROUND_STARTED ){ \
				forPlayer( t, index, player ) \
					vector pos = prPos(player); \
					if( pos.z < gpos.z+Z ){ \
						warpPlayerToSurface( player, getPlayerCheckpoint(player), ZERO_ROTATION, TRUE ); \
					} \
				end \
			} \
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

	#define shufflePlayerData() \
		PLAYER_DATA = llListRandomize(PLAYER_DATA, PD_STRIDE)




	resetAllPlayers(){

		PLAYER_DATA = [];
		forPlayer( t, index, player )
			
			resetPlayerData(player);
		
		end

	}


	startGame(){
		
		resetAllPlayers();
		GSETTINGS = GSETTINGS &~ GS_ROUND_STARTED;
		GSETTINGS = GSETTINGS | GS_GAME_STARTED;
		
		Level$toggleGame(TRUE);
		
		forPlayer( t, idx, player )
			setGameRestrictions(player);
		end
		onGameStart();
		
		raiseEvent(0, "START_GAME");
		
	}

	endGame(){

		Level$toggleGame(FALSE);
		GSETTINGS = GSETTINGS &~ GS_GAME_STARTED;
		GSETTINGS = GSETTINGS &~ GS_ROUND_STARTED;
		
		raiseEvent(0, "END_GAME" + onGameEnd());
		
		
	}

	startRound(){

		ROUND_START_TIME = llGetTime();
		onRoundStart();
		
		forPlayer( t, index, player )
			
			Gui$startCountdown( player );
		
		end
		raiseEvent(0, "ROUND_START");
		setTimeout("_COUNTDOWN", 3);
		
	}

	endRound( float delay ){

		GSETTINGS = GSETTINGS &~GS_ROUND_STARTED;
		if( delay > 0 )
			setTimeout("_ROUND", delay);
		else
			startRound();

	}


	#define gameHelperHandleBalloonHit( dist, invulCheck ) \
		onProjectileHit( projectile, obj ) \
			 \
			if( llGetAgentSize(obj) != ZERO_VECTOR ){ \
				 \
				if( llGetAgentInfo(obj) & AGENT_SITTING || invulCheck(obj) ) \
					return; \
					 \
				vector owner = prPos(llGetOwnerKey(projectile)); \
				vector spos = prPos(obj); \
				vector offs = spos-owner; \
				offs.z = 0; \
						 \
				float time = 0.5; \
				spos += llVecNorm(offs)*dist; \
				 \
				Rlv$damageSprint( obj, 1 ); \
				Rlv$target(  \
					obj,  \
					spos,  \
					.1,  \
					time \
				); \
				  \
			} \
			 \
		end



#endif
