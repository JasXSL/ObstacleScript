#ifndef __Com
#define __Com


#define ComMethod$invite 1				// void - Invites a player to your current game
#define ComMethod$inviteSuccess 2		// void - Invites a player to your current game
#define ComMethod$players 3				// void - Updates players


// Events
#define ComEvent$hostChanged 1			// (key)host - Raised with the host prim whenever you join a game


#define onComHostChanged( host ) \
	if( SENDER_SCRIPT IS "Com" AND EVENT_TYPE IS ComEvt$hostChanged ){



#define Com$invite( target ) \
	runMethod(target, "Com", ComMethod$invite, [])
#define Com$inviteSuccess( target ) \
	runMethod(target, "Com", ComMethod$inviteSuccess, [])
#define Com$players( target, players ) \
	runMethod(target, "Com", ComMethod$players, players )


#endif
