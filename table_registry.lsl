#ifndef __table_registry
#define __table_registry
/*
	
	This is a registry for indexed tables using the auto indexed tables.
	If you're going to use linkset data, your keys MUST be at least 3 characters long.
	The whole 1 char and 2 char ranges are reserved to make large indexed tables.
	I suggest only using this system for data that's out of your control as a dev. Such as tracking spawns.

*/

#define idbTable$SPAWNS " "			// char(32) - Owned by Spawner
#define idbTable$PLAYERS "!"		// char(33) - Owned by Com / Portal
#define idbTable$HUDS "\""			// char(34) - Owned by Com / Portal


#endif
