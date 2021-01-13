#ifndef __Screpo
#define __Screpo
/*
	Script remoteloader repository
*/
// Screpo reserves the first 4 bits for load status
#define ScrepoConst$SP_NONE 0			// Do not remote load
#define ScrepoConst$SP_DEFAULT 1		// Rezzed through a script but needs remoteloading
#define ScrepoConst$SP_LOADED 2			// This script has been remoteloaded



#define ScrepoMethod$get 1		// (int)pin, (int)startParam, (str)script1, (str)script2...



#define Screpo$get( pin, startParam, scripts ) \
	runMethod(llGetOwner(), "Screpo", ScrepoMethod$get, ((int)pin) + ((int)startParam) + scripts )



#endif
