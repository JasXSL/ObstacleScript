#ifndef __Level
#define __Level

	#define LevelMethod$invite 1			// (key)player - Invites a specific player to your game. Using * will invite all players within 10m of the game starter
	#define LevelMethod$resetPlayers 2		// Resets players to owner only
	#define LevelMethod$acceptInvite 3		// void - Accepts an invite
	#define LevelMethod$raiseEvent 4		// (str)script, (int)evt, (var)data1, (var)data2... - Owner only

	#define LevelEvt$mainMenu 1				// Raised when the owner clicks the level controller
	#define LevelEvt$custom 2				// (key)sender, (str)script, (int)evt, (var)data1, (var)data2...

	#define onLevelMainMenu() \
		if( SENDER_SCRIPT IS "Level" AND EVENT_TYPE IS LevelEvt$mainMenu ){
		
	#define isEventLevelCustom() \
		(SENDER_SCRIPT IS "Level" AND EVENT_TYPE IS LevelEvt$custom)
		
	#define onLevelCustom( sender, script, evt, data ) \
		if isEventLevelCustom() { \
			key sender = argKey(0); \
			str script = argStr(1); \
			int evt = argInt(2); \
			list data = llDeleteSubList(METHOD_ARGS, 0, 2);
			
	

	#define Level$invite( player ) \
		runMethod(LINK_THIS, "Level", LevelMethod$invite, player)
	#define Level$inviteNearby() \
		runMethod(LINK_THIS, "Level", LevelMethod$invite, "*")
	#define Level$resetPlayers() \
		runMethod(LINK_THIS, "Level", LevelMethod$resetPlayers, "*")
	#define Level$acceptInvite( target ) \
		runMethod(target, "Level", LevelMethod$acceptInvite, [])
	#define Level$raiseEvent( evt, data ) \
		runMethod(mySpawner(), "Level", LevelMethod$raiseEvent, llGetScriptName() + evt + data )
	


#endif
