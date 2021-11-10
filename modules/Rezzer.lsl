#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

// Nr things to rez simulatenously
#define PARALLEL 3

integer IDX;
list descQueue; // (int)idx, (float)time, (vector)pos, (str)desc, (str)group
#define DQSTRIDE 5
list objQueue;  // contains JSON strings passed to RezzerMethod$rez

// Removes a slice from dq, idx is the absolute index in the list to start from
#define removeDqSlice( absoluteIndex ) \
	descQueue = llDeleteSubList(descQueue, absoluteIndex, absoluteIndex+DQSTRIDE-1)

#define dqFull() \
	(count(descQueue)/DQSTRIDE >= PARALLEL)

rez(){
    
    if( dqFull() || objQueue == [] )
        return;
        

	// Callback encountered
	string s = l2s(objQueue, 0);
	objQueue = llDeleteSubList(objQueue, 0, 0);
	
	if( llGetSubString(s, 0, 0) == "$" ){
		
		raiseEvent(RezzerEvt$cb, llGetSubString(s, 1, -1));
		
	}
	// Rez something
	else{
	
		++IDX;
		
		// Normal queue
		list data = llJson2List(s);
		setTimeout("FAIL:"+(str)IDX, 60);
		
		integer startParam;
		if( l2i(data, 5) )
			startParam = PortalConst$SP_LIVE;
			
		startParam = startParam | ((IDX&0xFFFF)<<5);
		
		descQueue += (list)
			IDX + 
			llGetTime() +
			l2s(data, 1) +
			l2s(data, 3) +
			l2s(data, 4)
		;
		
		llRezAtRoot(
			l2s(data, 0), 
			llGetPos()-<0,0,5>, 
			ZERO_VECTOR,
			(rotation)l2s(data, 2), 
			startParam
		);

	}
	
	setTimeout("C", .1);	// Unblock for a moment
    
}




#include "ObstacleScript/begin.lsl"

onStateEntry()
    if( llGetStartParameter() == 1 )
		Level$scriptInit();
end


handleOwnerMethod( RezzerMethod$rez )

    objQueue += mkarr(METHOD_ARGS);
    rez();        

end

onTimer( label )

	if( label == "C" )
		rez();
	else if( llGetSubString(label, 0, 4) == "FAIL:" ){

		integer idx = (int)llGetSubString(label, 5, -1);
		integer pos = llListFindList(descQueue, (list)idx);
		if( ~pos ){
			
			qd("Failed to rez " + llList2List(descQueue, pos, pos+DQSTRIDE-1) + "Try restarting the sim?");
			removeDqSlice( pos );
			rez();
		
		}
	
	}

end

handleOwnerMethod( RezzerMethod$cb )
	
	string cb = "$"+argStr(0);
	objQueue += cb;
	rez();	
	
end

handleOwnerMethod( RezzerMethod$rezzed )

    
    integer id = argInt(0);
    integer pos = llListFindList(descQueue, (list)id);
    if( pos == -1 ){
        
        llOwnerSay("Rezzer.lsl : Error: Asset trying to fetch desc, but desc not found "+(str)id + " in queue: " + mkarr(descQueue));
		llOwnerSay("Make sure you're not overriding llSetText until the portal is initialized");
        return;
        
    }
    
    Portal$init( 
        SENDER_KEY, 
        l2s(descQueue, pos+2), 
        l2s(descQueue, pos+3),
        l2s(descQueue, pos+4)    
    );
	removeDqSlice( pos );
    unsetTimer("FAIL:"+(str)id);
	rez();

end

handleOwnerMethod( RezzerMethod$initialized )
	raiseEvent(RezzerEvt$rezzed, SENDER_KEY);
end


#include "ObstacleScript/end.lsl"


