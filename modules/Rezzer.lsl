#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

// Nr things to rez simulatenously
#define PARALLEL 3

integer IDX;
list descQueue; // (int)idx, (float)time, (vector)pos, (str)desc, (str)group, (str)name -- Name is only used for debugging
#define DQSTRIDE 6
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
	
	//qd("Rezzing" + s);
	
	if( llGetSubString(s, 0, 0) == "$" ){
		
		raiseEvent(RezzerEvt$cb, llGetSubString(s, 1, -1));
		
	}
	// Rez something
	else{
		
	
		++IDX;
		
		// Normal queue
		list data = llJson2List(s);
		str name = l2s(data, 0);
		if( llGetInventoryType(name) != INVENTORY_OBJECT ){
			qd("Unable to rez" + name + "Object missing from inventory");
		}
		else{
		
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
				l2s(data, 4) +
				name
			;
			
			llRezAtRoot(
				name, 
				llGetPos()-<0,0,5>, 
				ZERO_VECTOR,
				(rotation)l2s(data, 2), 
				startParam
			);
		
		}

	}
	
	setTimeout("C", .1);	// Unblock for a moment
    
}




#include "ObstacleScript/begin.lsl"

onStateEntry()
    if( llGetStartParameter() == 1 )
		Level$scriptInit();
end

handleOwnerMethod( RezzerMethod$rezMulti )
	
	objQueue += METHOD_ARGS;
	rez();
	
end

handleOwnerMethod( RezzerMethod$rez )
	
    objQueue += mkarr(METHOD_ARGS);
    rez();        

end

onTimer( label )

	if( label == "C" )
		rez();
	else if( llGetSubString(label, 0, 4) == "FAIL:" ){
	
		list spl = split(label, ":");
		integer idx = l2i(spl, 1);
		integer pos = llListFindList(descQueue, (list)idx);
		if( ~pos ){
			
			qd("Failed to rez " + llList2List(descQueue, pos, pos+DQSTRIDE-1) + "Try restarting the sim?");
			removeDqSlice( pos );
			rez();
		
		}
		else
			qd("Failed to rez an item: " + idx + "but it was not found in queue somehow");
	
	}

end

handleOwnerMethod( RezzerMethod$cb )
	
	string cb = "$"+argStr(0);
	objQueue += cb;
	rez();	
	
end

handleOwnerMethod( RezzerMethod$debug )
	
	qd(("Obj queue ["+(str)count(objQueue)+"]") + objQueue);
	qd(("descQueue ["+(str)(count(descQueue)/DQSTRIDE)+"]") + descQueue);
	
end

handleOwnerMethod( RezzerMethod$rezzed )

    //qd("INI" + llKey2Name(SENDER_KEY) + SENDER_KEY);
	
    integer id = argInt(0);
    integer pos = llListFindList(descQueue, (list)id);
    if( pos == -1 ){
        
        llOwnerSay("Rezzer.lsl : Error: '"+llKey2Name(SENDER_KEY)+"' trying to fetch desc, but id "+(str)id + " not found in descqueue: " + mkarr(descQueue));
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


