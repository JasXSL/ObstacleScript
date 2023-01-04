// #define SCRIPT_IS_PLAYER_MANAGER - Use this in portal/level/COM to mark that this script manages the players (prevents recursion)

#define numPlayers() idbGetIndex(idbTable$PLAYERS)
#define numHuds() idbGetIndex(idbTable$HUDS)


#define forPlayer( tot, index, player ) \
	int index; int tot = numPlayers(); \
	for(; index < tot; ++index ){ \
		key player = idbGetByIndex(idbTable$PLAYERS, index); 


#define forHuds( tot, index, hud ) \
	int index; int tot = numHuds(); \
	for(; index < tot; ++index ){ \
		key hud = idbGetByIndex(idbTable$HUDS, index); 

#define getPlayers() idbValues(idbTable$PLAYERS, true)
#define getHuds() idbValues(idbTable$HUDS, true)

#define isPlayer( id ) \
	( id == llGetOwner() || ~llListFindList(getPlayers(), (list)id) )
	



