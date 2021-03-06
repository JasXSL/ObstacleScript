#ifndef __LevelCustomEvents
#define __LevelCustomEvents
/*
	
	This file contains a list of obstacle events tied to an avatar instead of an obstacle, such as ladders, quicktime events, and projectile.
	These events are raised on Level through the LevelEvt$custom event
	You can obviously create your own custom ones, but follow these naming conventions:
	1. For obstacle type, start with lowercase o. Labeling it with an "o" first makes sure it doesn't collide with script names such as Trigger events. For player type start with "pl"
		Syntax is ObstacleType$<TYPE>
	2. For events, syntax is ObstacleEvt$<TYPE>$<evt>
	
	"o" type events should be defined in their obstacle header file.
	This file is for av type event.
*/

// Types starting with av are allowed for ANY player. Any other are limited to owner





#define LevelCustomType$PROJECTILE "avProj"
	#define LevelCustomEvt$PROJECTILE$hit 1			// (key)player/target

#define LevelCustomType$STAIR "avStair"		
	#define LevelCustomEvt$STAIR$seated 1 			// (key)object, (bool)sitting

#define LevelCustomType$QTE "avQTE"		
	#define LevelCustomEvt$QTE$start 1 				// (int)type, (str)callback
	#define LevelCustomEvt$QTE$end 2				// (bool)success, (str)callback





		
		
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
