#define USE_STATE_ENTRY
#define USE_CHANGED
//#define USE_TIMER
#include "ObstacleScript/index.lsl"

list psl;			// Powered sound links. Basically a cache of links that 

buildCache(){

	psl = [];
	forLink(nr, name)
		
		list l = getDescTask(l2s(llGetLinkPrimitiveParams(nr, (list)PRIM_DESC), 0), Desc$GHOST_POWERED);
		if( l )
			psl += nr;
			
	end

}


#include "ObstacleScript/begin.lsl"

onStateEntry() 
	
    // Cache 
	buildCache();
	
end

onChanged( ch )
	
	if( ch & CHANGED_LINK )
		buildCache();

end

// Method
handleInternalMethod( GhostLevelHelperMethod$togglePoweredSounds )
    
	bool on = argInt(0);
	int i;
	for(; i < count(psl); ++i ){
		
		int link = l2i(psl, i);
		if( !on )
			llLinkStopSound(link);
		else
			updateLinkSoundLoop(link);
		
	}
    
end


#include "ObstacleScript/end.lsl"

