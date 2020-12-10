/*
	Handles the following:
	- Stripping
	- Windlight (and windlight steps)
	- Sprint
	- Supportcube
*/
#ifndef __RLV
#define __RLV

// STATE
#define Rlv$DRESSED 3
#define Rlv$UNDERWEAR 2
#define Rlv$BITS 1
#define Rlv$IGNORE 0

// Translation for the JasX HUD
#define Rlv$STATE [ \
	"Bits", \
	"Underwear", \
	"Dressed" \
]

// SLOT
#define Rlv$HEAD 0
#define Rlv$ARMS 1
#define Rlv$TORSO 2
#define Rlv$CROTCH 3
#define Rlv$FEET 4

#define Rlv$SLOTS [ \
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


#define RlvEvt$supportCubeSpawn 1		// (key)cube_id




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
	runMethod( target, "Rlv", RlvMethod$setWindlight, seat + blockUnsit )


#define Rlv$setMaxSprint( target, dur ) \
	runMethod( target, "Rlv", RlvMethod$setMaxSprint, dur )
#define Rlv$damageSprint( target, perc ) \
	runMethod( target, "Rlv", RlvMethod$damageSprint, perc )


#define onRlvSupportCubeSpawn( id ) \
	if( SENDER_SCRIPT IS "Rlv" AND EVENT_TYPE IS RlvEvt$supportCubeSpawn ){ \
		key id = argKey(0);



#endif
