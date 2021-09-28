// #define SCRIPT_IS_PLAYER_MANAGER - Use this in portal/level/COM to mark that this script manages the players

// Adds definitions for player management
#ifdef USE_PLAYERS
	
	list _P;
	#define PLAYERS _P
	
	
	// Player list
	#define isPlayer( targ ) \
		(~llListFindList(PLAYERS, (list)((str)targ)))


	#define forPlayer( index, player ) \
	int index; \
	for(; index < count(_P); ++index ){ \
		key player = l2k(_P, index); 


#else
	#define _P #error Add #define USE_PLAYERS to enable player tracking
	#define PLAYERS _P
#endif

#ifdef USE_HUDS
	
	list _H;		// Stores a list of HUDs
	#define HUDS _H

#else
	#define _H #error Add #define USE_HUDS to the top of your script to enable HUD tracking
	#define HUDS _H
#endif


