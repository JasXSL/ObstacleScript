#ifndef __Rezzer
#define __Rezzer


#define RezzerMethod$rez 1			// (str)prim, (vec)pos, (rot)rotation, (str)desc, (str)group
#define RezzerMethod$rezzed 2		// (int)id - A portal object has been rezzed and is awaiting instructions

#define Rezzer$rez( targ, asset, pos, rot, desc, group, live ) \
	runMethod(targ, "Rezzer", RezzerMethod$rez, asset + pos + rot + desc + group + live)

#define Rezzer$rezzed( targ, spawnIndex ) \
	runMethod(targ, "Rezzer", RezzerMethod$rezzed, spawnIndex)

#endif
