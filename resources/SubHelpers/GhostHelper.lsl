#include "../GameHelper.lsl"

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



