/*
	Handles the following:
	- Stripping
	- Windlight (and windlight steps)
	- Sprint
	- Supportcube
*/
#ifndef __RLV
#define __RLV


// Flags
#define RlvFlags$IMMOBILE 0x1			// Unable to move. Todo: Currently this only affects climbing



// STATE
#define RlvConst$DRESSED 3
#define RlvConst$UNDERWEAR 2
#define RlvConst$BITS 1
#define RlvConst$IGNORE 0

// Translation for the JasX HUD
#define RlvConst$STATE [ \
	"Bits", \
	"Underwear", \
	"Dressed" \
]

// SLOT
#define RlvConst$HEAD 0
#define RlvConst$ARMS 1
#define RlvConst$TORSO 2
#define RlvConst$CROTCH 3
#define RlvConst$FEET 4

#define RlvConst$SLOTS [ \
	"Head", \
	"Arms", \
	"Torso", \
	"Crotch", \
	"Boots" \
]

// Sets clothes in 
#define RlvMethod$setClothes 1			// 5 2-bit array, little endian. Rlv$SLOT indicates the index. and Rlv$STATE indicates the state to set it to
#define RlvMethod$setWindlight 2		// (str)windlight preset. Use "" to clear

#define RlvMethod$cubeTask 3			// task1, task2... Sends a task to the RLV supportcube
#define RlvMethod$unSit 4				// (int)force - Unsits the player
#define RlvMethod$cubeFlush 5			// Sends all pending cubetasks
#define RlvMethod$sit 6					// (key)id, (bool)blockUnsit

#define RlvMethod$setMaxSprint 7		// (float)duration - Sets sprint max duration in seconds. 0 disables running, -1 sets infinite sprint
#define RlvMethod$damageSprint 8		// (float)percent

#define RlvMethod$setFlags 9			// (int)flags 
#define RlvMethod$unsetFlags 10			// (int)flags



#define RlvEvt$supportCubeSpawn 1		// (key)cube_id
#define RlvEvt$flags 2					// (int)flags



#define Rlv$setClothes( target, head, arms, torso, crotch, feet ) \
	runMethod( target, "Rlv", RlvMethod$setClothes, ( \
		(head)| \
		((arms)<<2)| \
		((torso)<<4)| \
		((crotch)<<6)| \
		((feet)<<8) \
	))

#define Rlv$setClothSlot( target, slot, state ) \
	runMethod( target, "Rlv", RlvMethod$setClothes, (state<<(slot*2)))
	
	
#define Rlv$cubeTask( target, tasks ) \
	runMethod( target, "Rlv", RlvMethod$cubeTask, tasks)
	
#define Rlv$unSit( target, force ) \
	runMethod( target, "Rlv", RlvMethod$unSit, force )
	

#define Rlv$setWindlight( target, preset ) \
	runMethod( target, "Rlv", RlvMethod$setWindlight, preset )

#define Rlv$sit( target, seat, blockUnsit ) \
	runMethod( target, "Rlv", RlvMethod$sit, seat + blockUnsit )


#define Rlv$setMaxSprint( target, dur ) \
	runMethod( target, "Rlv", RlvMethod$setMaxSprint, dur )
#define Rlv$damageSprint( target, perc ) \
	runMethod( target, "Rlv", RlvMethod$damageSprint, perc )


#define Rlv$teleportPlayer( target, pos, rot ) \
	runMethod( target, "Rlv", RlvMethod$cubeTask, SupportCubeBuildTeleport(pos, rot))
#define Rlv$teleportPlayerNoUnsit( target, pos, rot ) \
	runMethod( target, "Rlv", RlvMethod$cubeTask, SupportCubeBuildTeleportNoUnsit(pos, rot))

#define Rlv$setFlags( target, flags, important ) \
	runMethod( target, "Rlv", RlvMethod$setFlags, ((int)flags) + ((int)important) )
#define Rlv$unsetFlags( target, flags, important ) \
	runMethod( target, "Rlv", RlvMethod$unsetFlags, ((int)flags) + ((int)important) )



#define onRlvSupportCubeSpawn( id ) \
	if( SENDER_SCRIPT IS "Rlv" AND EVENT_TYPE IS RlvEvt$supportCubeSpawn ){ \
		key id = argKey(0);
		
#define onRlvFlags( flags ) \
	if( SENDER_SCRIPT IS "Rlv" AND EVENT_TYPE IS RlvEvt$flags ){ \
		int flags = argInt(0);



#endif
