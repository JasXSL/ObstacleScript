#include "../GameHelper.lsl"

// ToolSet.lsh tool types. Commented is the data
#define ToolsetConst$types$ghost$owometer 1			// (bool)on
#define ToolsetConst$types$ghost$flashlight 2		// (bool)on
#define ToolsetConst$types$ghost$hots 3				// 0
#define ToolsetConst$types$ghost$ecchisketch 4		// (int)drawing
#define ToolsetConst$types$ghost$spiritbox 5		// (bool)on
#define ToolsetConst$types$ghost$camera 6			// (int)free_pics
#define ToolsetConst$types$ghost$salt 7				// (int)charges
#define ToolsetConst$types$ghost$candle 8			// NOT USED IN GAME
#define ToolsetConst$types$ghost$parabolic 9		// (bool)on
#define ToolsetConst$types$ghost$motionDetector 10	// 0
#define ToolsetConst$types$ghost$glowstick 11		// (int)utime_turned_on
#define ToolsetConst$types$ghost$pills 12			// 0
#define ToolsetConst$types$ghost$thermometer 13		// (bool)on
#define ToolsetConst$types$ghost$weegieboard 14		// 0
#define ToolsetConst$types$ghost$vape 15			// 0
#define ToolsetConst$types$ghost$hornybat 16		// 0






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



