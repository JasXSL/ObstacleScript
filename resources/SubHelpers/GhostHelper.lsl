#include "../GameHelper.lsl"

// ToolSet.lsh tool types. Commented is the data, followed by call to either ToolSet$trigger or GhostToolMethod$trigger
#define ToolsetConst$types$ghost$owometer 1			// (bool)on
#define ToolsetConst$types$ghost$flashlight 2		// (bool)on
#define ToolsetConst$types$ghost$hots 3				// 0
#define ToolsetConst$types$ghost$ecchisketch 4		// (int)drawing
#define ToolsetConst$types$ghost$spiritbox 5		// (bool)on
#define ToolsetConst$types$ghost$camera 6			// (int)pics_taken
#define ToolsetConst$types$ghost$salt 7				// (int)charges_used
#define ToolsetConst$types$ghost$candle 8			// NOT USED IN GAME
#define ToolsetConst$types$ghost$parabolic 9		// (bool)on | ToolSet: pos
#define ToolsetConst$types$ghost$motionDetector 10	// 0
#define ToolsetConst$types$ghost$glowstick 11		// (int)utime_turned_on
#define ToolsetConst$types$ghost$pills 12			// 0
#define ToolsetConst$types$ghost$thermometer 13		// (bool)on
#define ToolsetConst$types$ghost$weegieboard 14		// 0
#define ToolsetConst$types$ghost$vape 15			// 0
#define ToolsetConst$types$ghost$hornybat 16		// 0
#define ToolsetConst$types$ghost$saltpile 17		// (bool)stepped


#define GhostHelper$CAM_MAX_PICS 5
#define GhostHelper$SALT_MAX_CHARGES 3

#define GhostHelper$flashlightSettings (list)PRIM_POINT_LIGHT + on + <1.000, 0.928, 0.710> + 1 + 4 + 1
#define GhostHelper$ecchisketchTexture "9b2f4cf3-2796-4a6a-e5f4-0b93693c86aa"


#define GhostHelper$glowStickPerc( utimeLit ) 
#define GhostHelper$getGlowstickSettings( utimeLit ) _ghGGS(utimeLit)
list _ghGGS( integer utimeLit ){
	
	float perc = ((300.0-(float)(llGetUnixTime()-utimeLit))/300.0);
	if( perc < 0 )
		perc = 0;
		
	return (list)PRIM_POINT_LIGHT + TRUE + <0.665, 0.181, 1.000> + 1.0 + (2.5+2.5*perc) + 1.0 + PRIM_FULLBRIGHT + ALL_SIDES + TRUE + PRIM_GLOW + ALL_SIDES + (0.1+0.4*perc);

}


// Tools that don't require a remoteloaded script
// Aka all tools that can't be used from both hand and placed
#define LevelCustomType$GHOSTHELPER "oToolset"				// Generic type for traps like the lasher
		#define LevelCustomEvt$GHOSTHELPER$pills 1			// 
	
#define onLevelCustomGhosthelperPills( toolsetuuid, worldID ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$GHOSTHELPER AND argInt(2) == LevelCustomEvt$GHOSTHELPER$pills ){ \
		key toolsetuuid = argKey(0); \
		key worldID = argKey(3);


// Use parent
#define ghostHelperStateEntry() gameHelperStateEntry()
#define ghostHelperEventHandler() gameHelperEventHandler()
#define onCountdownFinished() // Unused in this mode

// Overrides GameHelper
startRound(){

	onRoundStart();
	raiseEvent(0, "ROUND_START");
	ROUND_START_TIME = llGetTime();
	forPlayer( index, player )
		Rlv$unSit( player, TRUE );
	end
	GSETTINGS = GSETTINGS | GS_ROUND_STARTED;
	
}



