// Adds definitions for player management

#ifdef USE_PLAYERS
	
	list _H;		// Stores a list of HUDs


#else
	#define _H #error Add #define USE_PLAYERS to the top of your script to enable player tracking

#endif


