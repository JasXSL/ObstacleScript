#ifndef __Rezzer
#define __Rezzer


#define RezzerMethod$rez 1			// (str)prim, (vec)pos, (rot)rotation, (str)desc, (str)group
#define RezzerMethod$rezzed 2		// (int)id - A portal object has been rezzed and is awaiting instructions
#define RezzerMethod$cb 3			// (str)callback. Adds this to the current position in the queue. When encountered, it raises RezzerEvt$cb

#define RezzerEvt$cb 1				// (str)cb

#define Rezzer$rez( targ, asset, pos, rot, desc, group, live ) \
	runMethod(targ, "Rezzer", RezzerMethod$rez, asset + pos + rot + desc + group + live)
#define Rezzer$cb( targ, cb ) \
	runMethod(targ, "Rezzer", RezzerMethod$cb, cb)

#define Rezzer$rezzed( targ, spawnIndex ) \
	runMethod(targ, "Rezzer", RezzerMethod$rezzed, spawnIndex)



#define onRezzerCb( cb ) \
	if( SENDER_SCRIPT IS "Rezzer" AND EVENT_TYPE IS RezzerEvt$cb ){ \
		str cb = argStr(0);
		
#define onRezzerGameLoaded() \
if( SENDER_SCRIPT IS "Rezzer" AND EVENT_TYPE IS RezzerEvt$cb && argStr(0) == SpawnerConst$CB_GAME_START ){
	

#endif
