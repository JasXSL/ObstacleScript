#ifndef __CrusherWall
#define __CrusherWall

// Wall description: [(vec)size, (var)id, (vec)translate_distance, (float)duration]

#define CrusherWallConst$CHAN (OBSTACLE_CHAN+1)	// Listener

#define CrusherWallConst$DIR_FWD 0	// Go to extended
#define CrusherWallConst$DIR_BACK 1		// Go to contracted
#define CrusherWallConst$DIR_PING_PONG 2	// This makes it ping pong back and forwards endlessly until one of the above are sent. Note that this will go out of sync with other walls


#define CrusherWall$trigger( dir, ids ) \
	llRegionSay(CrusherWallConst$CHAN, mkarr(dir + ids))



#endif
 