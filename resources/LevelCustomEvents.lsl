#ifndef __LevelCustomEvents
#define __LevelCustomEvents
/*
	
	This file contains a list of obstacle events you can use to standardize events across obstacle types.
	These events are raised on Level
	You can obviously create your own custom ones, but follow these naming conventions:
	1. For obstacle type, start with lowercase o. Labeling it with an "o" first makes sure it doesn't collide with script names such as Trigger events.
		Syntax is ObstacleType$<TYPE>
	2. For events, syntax is ObstacleEvt$<TYPE>$<evt>

*/

#define LevelCustomType$SHIMMY_WALL "oShimmyWall"
	#define LevelCustomEvt$SHIMMY_WALL$hitStart 1		// (key)player1, (key)player2...
	#define LevelCustomEvt$SHIMMY_WALL$hitEnd 2		// (key)player1, (key)player2...


#define LevelCustomType$TRIGGER "oTrigger"
	#define LevelCustomEvt$TRIGGER$trigger 1		// (key)player - Raised when a player triggers a collision

#define LevelCustomType$STAIR "avStair"		
	#define LevelCustomEvt$STAIR$seated 1 			// (key)object, (bool)sitting




#define onTrigger( object, player, label ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$TRIGGER AND argInt(2) == LevelCustomEvt$TRIGGER$trigger ){ \
		key object = argKey(0); \
		key player = argKey(3); \
		str _d = prDesc(object); \
		if( llGetSubString(_d, 0, 0) == "$" ) \
			_d = llDeleteSubString(_d, 0, 0); \
		str label = j(_d, 1);
		

#define onShimmyWallHit( object, start, players ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$SHIMMY_WALL AND (argInt(2) == LevelCustomEvt$SHIMMY_WALL$hitStart OR argInt(2) == LevelCustomEvt$SHIMMY_WALL$hitEnd) ){ \
		key object = argKey(0); \
		int start = argInt(2); \
		list players = llDeleteSubList(METHOD_ARGS, 0, 2);
		
#define onStairSeated( hud, stair, seated ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$STAIR AND argInt(2) == LevelCustomEvt$STAIR$seated ){ \
		key hud = argKey(0); \
		key stair = argKey(3); \
		int seated = argInt(4);



#endif
