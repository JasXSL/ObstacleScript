#ifndef __Repo
#define __Repo



#define RepoMethod$enum 1		// (int)callbackMethod, (str)callbackScript, prim1, prim2... - Send a list of prim names to the repo, the repo will return a list of shareable prims by running callbackMethod on the sending script
#define RepoMethod$fetch 2		// (int)callbackMethod, (str)callbackScript, prim1, prim2...	- Gives inventory of the selected prims to the prim that calls this method, sends a callback to that script with a method specified


#define Repo$enum( callback, prims ) \
	runMethod(llGetOwner(), "Repo", RepoMethod$enum, ((int)callback) + llGetScriptName() + prims)
#define Repo$fetch( callback, prims ) \
	runMethod(llGetOwner(), "Repo", RepoMethod$fetch, ((int)callback) + llGetScriptName() + prims)



#endif
