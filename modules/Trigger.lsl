#define USE_STATE_ENTRY
#include "ObstacleScript/index.lsl"

string ID;
integer FLAGS;

#include "ObstacleScript/begin.lsl"

onStateEntry()
    
    Portal$scriptOnline();  // required for portal to function
    
end

onPortalLoadComplete( desc )
    
	list json = llJson2List(desc);
	vector size = (vector)l2s(json, 0);
	if( size == ZERO_VECTOR )
		return;
		
	ID = l2s(json, 1);
	FLAGS = l2i(json, 2);
		
	llSetScale(size);
	
	// Todo: Continue here
    
end


#include "ObstacleScript/end.lsl"

