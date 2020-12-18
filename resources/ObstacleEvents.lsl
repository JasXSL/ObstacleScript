#ifndef __ObstacleEvents
#define __ObstacleEvents
/*
	
	This file contains a list of obstacle events you can use to standardize events across obstacle types.
	These events are raised on Level
	You can obviously create your own custom ones, but follow these naming conventions:
	1. For obstacle type, start with lowercase o. Labeling it with an "o" first makes sure it doesn't collide with script names such as Trigger events.
		Syntax is ObstacleType$<TYPE>
	2. For events, syntax is ObstacleEvt$<TYPE>$<evt>

*/

#define ObstacleType$SHIMMY_WALL "oShimmyWall"
	#define ObstacleEvt$SHIMMY_WALL$hitStart 1		// (key)player1, (key)player2...
	#define ObstacleEvt$SHIMMY_WALL$hitEnd 2		// (key)player1, (key)player2...



#endif
