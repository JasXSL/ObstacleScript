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

// Types starting with av are allowed for ANY player. Any other are limited to owner

#define LevelCustomType$SHIMMY_WALL "oShimmyWall"
	#define LevelCustomEvt$SHIMMY_WALL$hitStart 1		// (key)player1, (key)player2...
	#define LevelCustomEvt$SHIMMY_WALL$hitEnd 2		// (key)player1, (key)player2...


#define LevelCustomType$TRIGGER "oTrigger"
	#define LevelCustomEvt$TRIGGER$trigger 1		// (key)player - Raised when a player triggers a collision


#define LevelCustomType$TRAP "oTrap"				// Generic type for traps like the lasher
	#define LevelCustomEvt$TRAP$hit 1					// (key)player1, (key)player2... - Trap has hit a player
	#define LevelCustomEvt$TRAP$seated 2				// (key)player1, (key)player2... - Trap has been sat on by one or more players
	#define LevelCustomEvt$TRAP$unseated 3				// (key)player1, (key)player2... - Trap has been unsat by one or more players

#define LevelCustomType$TRAPDOOR "oTrapdoor"
	#define LevelCustomEvt$TRAPDOOR$trigger 1		// (str)trapdoor_label, (key)player - Trapdoor has opened
	#define LevelCustomEvt$TRAPDOOR$reset 2			// (str)trapdoor_label - Trapdoor has closed
	

#define LevelCustomType$PROJECTILE "avProj"
	#define LevelCustomEvt$PROJECTILE$hit 1			// (key)player/target

#define LevelCustomType$STAIR "avStair"		
	#define LevelCustomEvt$STAIR$seated 1 			// (key)object, (bool)sitting

#define LevelCustomType$QTE "avQTE"		
	#define LevelCustomEvt$QTE$start 1 				// (int)type, (str)callback
	#define LevelCustomEvt$QTE$end 2				// (bool)success, (str)callback



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
		int start = argInt(2) == LevelCustomEvt$SHIMMY_WALL$hitStart; \
		list players = llDeleteSubList(METHOD_ARGS, 0, 2);
		
		
		
		
#define onTrapdoorTrigger( trap, label, player ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$TRAPDOOR AND argInt(2) == LevelCustomEvt$TRAPDOOR$trigger ){ \
		key trap = argKey(0); \
		string label = argStr(3); \
		key player = argKey(4); \
		
#define onTrapdoorReset( trap, label ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$TRAPDOOR AND argInt(2) == LevelCustomEvt$TRAPDOOR$reset ){ \
		key trap = argKey(0); \
		string label = argStr(3);
		
		
#define onTrapHit( trap, players ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$TRAP AND argInt(2) == LevelCustomEvt$TRAP$hit ){ \
		key trap = argKey(0); \
		list players = llDeleteSubList(METHOD_ARGS, 0, 2);

#define onTrapSeated( trap, players ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$TRAP AND argInt(2) == LevelCustomEvt$TRAP$seated ){ \
		key trap = argKey(0); \
		list players = llDeleteSubList(METHOD_ARGS, 0, 2);

#define onTrapUnseated( trap, players ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$TRAP AND argInt(2) == LevelCustomEvt$TRAP$unseated ){ \
		key trap = argKey(0); \
		list players = llDeleteSubList(METHOD_ARGS, 0, 2);

#define onProjectileHit( projectile, object ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$PROJECTILE AND argInt(2) == LevelCustomEvt$PROJECTILE$hit ){ \
		key projectile = argKey(0); \
		key object = argKey(3);

		
		
#define onStairSeated( hud, stair, seated ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$STAIR AND argInt(2) == LevelCustomEvt$STAIR$seated ){ \
		key hud = argKey(0); \
		key stair = argKey(3); \
		int seated = argInt(4);


#define onPlayerQteStarted( hud, type ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$QTE AND argInt(2) == LevelCustomEvt$QTE$start ){ \
		key hud = argKey(0); \
		int type = argInt(3);
		
#define onPlayerQteEnded( hud, success, callback ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$QTE AND argInt(2) == LevelCustomEvt$QTE$end ){ \
		key hud = argKey(0); \
		int success = argInt(3); \
		str callback = argStr(4);
		


#endif
