#ifndef __SoundspaceAux
#define __SoundspaceAux

/*
	Before compiling the package, add
	#define THIS_SUB 1 for the main one, and #define THIS_SUB 2 for the second prim
	Soundspaces will tween between 2 sounds, which is why this is needed
*/

#define SoundspaceAuxMethod$set 1				// (int)controller, (key)uuid, (float)vol

#define SoundspaceAux$set(controller, uuid, vol) \
	runMethod(LINK_SET, "SoundspaceAux", SoundspaceAuxMethod$set, controller + uuid + vol)



#endif
