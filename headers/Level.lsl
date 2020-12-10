#ifndef __Level
#define __Level

	#define LevelMethod$invite 1			// (key)player - Invites a specific player to your game. Using * will invite all players within 10m of the game starter
	#define LevelMethod$resetPlayers 2		// Resets players to owner only
	#define LevelMethod$acceptInvite 3		// void - Accepts an invite
	

	#define LevelEvt$mainMenu 1			// Raised when the owner clicks the level controller
	

	#define onLevelMainMenu() \
		if( SENDER_SCRIPT IS "Level" AND EVENT_TYPE IS LevelEvt$mainMenu ){

	#define Level$invite( player ) \
		runMethod(LINK_THIS, "Level", LevelMethod$invite, player)
	#define Level$inviteNearby() \
		runMethod(LINK_THIS, "Level", LevelMethod$invite, "*")
	#define Level$resetPlayers() \
		runMethod(LINK_THIS, "Level", LevelMethod$resetPlayers, "*")
	#define Level$acceptInvite( target ) \
		runMethod(target, "Level", LevelMethod$acceptInvite, [])
	


#endif
