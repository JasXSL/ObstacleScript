#ifndef __AnimHandler
#define __AnimHandler

/* Optional configuration

	#define AnimHandlerCfg$beforeAnim()				- Define something to run before each animation. Should return true/false
	#define AnimHandlerConf$suppressErrors 		- Prevents error messages

*/



#define AnimHandlerMethod$anim 0			// 0. (str)|(arr)anim
											// 1. (bool)start
											// 2. (float)duration
											// 3. (bool)flags
											
											// Anim can be an array of multiple animations to start/stop. 
											// It can also be an array of sub-arrays and one will be picked at random
											// Animations can also be JSON objects:
											/*
												a:(str)anim
												d:(float)duration
												s:(int)start
												f:(int)flags
											*/
											
	#define AnimHandler$animFlag$stopOnMove 0x1			// Stops the animation when the avatar moves
	#define AnimHandler$animFlag$randomize 0x2			// Picks one random element from anim instead of playing all
	#define AnimHandler$animFlag$stopOnUnsit 0x4			// Stops the animation if the avatar isn't sitting
	
#define AnimHandlerMethod$remInventory 1	// anim1, anim2...
#define AnimHandlerMethod$get 2				// (arr/str)anim | Fetch one or more animations to the sender. Owner only.


// Preprocessor shortcuts
#define AnimHandler$anim(targ, anim, start, duration, flags) \
	runMethod(targ, "AnimHandler", AnimHandlerMethod$anim, anim + start + duration + flags)

// Quick and easy methods to just start and stop
#define AnimHandler$start(targ, anim) \
	AnimHandler$anim(targ, anim, true, 0, 0)
#define AnimHandler$stop(targ, anim) \
	AnimHandler$anim(targ, anim, false, 0, 0)

#define AnimHandler$get(targ, anims) \
	runMethod(targ, "AnimHandler", AnimHandlerMethod$get, anims)

#define AnimHandler$remInventory(assets) \
	runMethod(LINK_SET, "AnimHandler", AnimHandlerMethod$remInventory, assets)

















#endif

