#ifndef __table_registry
#define __table_registry
/*
	
	This is a registry for indexed tables using the auto indexed tables.
	If you're going to use linkset data, your keys MUST be at least 3 characters long.
	The whole 1 char and 2 char ranges are reserved to make large indexed tables.
	I suggest only using this system for data that's out of your control as a dev. Such as tracking spawns.

*/
#define idbTable$SPAWNS " "			// char(32) - Owned by Spawner
#define idbTable$PLAYERS "!"		// char(33) - Owned by Com / Level / Portal
#define idbTable$HUDS "\""			// char(34) - Owned by Com / Level / Portal
#define idbTable$TOOLS "#"			// char(35) - Owned by GhostTools.template. Note: This table isn't indexed, it uses idbTable$TOOLS+itemUUID

// Todo: Implement into the game itself
#define idbTable$GHOST_SETTINGS "$"	// char(36) - Owned by Ghost / GhostHelper_Game - You can use macros in Ghost.lsh for both scripts
	#define idbTable$GHOST_SETTINGS$TYPE 0			// int - Ghost type
	#define idbTable$GHOST_SETTINGS$EVIDENCE 1		// int - Evidence types
	#define idbTable$GHOST_SETTINGS$AFFIXES 2		// int - Ghost Affixes
	#define idbTable$GHOST_SETTINGS$DIFFICULTY 3	// int - Difficulty
	#define idbTable$GHOST_SETTINGS$GHOST 4			// key - UUID of the ghost. GhostHelper_Game only
	
	
#define idbTable$INTERACT_OBJS "%"	// char(37) - Owned by GhostInteractions

// &'()*+,-./0123456789:;<=>?

#endif
