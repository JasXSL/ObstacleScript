#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

integer BFL;
#define BFL_REZZING 0x1


integer IDX;
list descQueue; // (int)idx, (float)time, (vector)pos, (str)desc, (str)group
list objQueue;  // contains JSON strings passed to RezzerMethod$rez


rez(){
    
    if( BFL & BFL_REZZING )
        return;
        
    if( objQueue == [] )
        return;
        
    
    ++IDX;
    
	
	
	// Callback encountered
	string s = l2s(objQueue, 0);
	while( llGetSubString(s, 0, 0) == "$" ){
		
		raiseEvent(RezzerEvt$cb, llGetSubString(s, 1, -1));
		objQueue = llDeleteSubList(objQueue, 0, 0);
		s = l2s(objQueue, 0);
		
	}
	
	if( !count(objQueue) )
		return;
		
	
	// Normal queue
    list data = llJson2List(s);
    objQueue = llDeleteSubList(objQueue, 0, 0);
    setTimeout("FAIL", 5);
    
    integer startParam;
    if( l2i(data, 5) )
        startParam = PortalConst$SP_LIVE;
        
    startParam = startParam | ((IDX<<5)&0xFFFF);
    
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
	BFL = BFL|BFL_REZZING;
    
}




#include "ObstacleScript/begin.lsl"

onStateEntry()
    
end

handleOwnerMethod( RezzerMethod$rez )

    objQueue += mkarr(METHOD_ARGS);
    rez();        

end

handleTimer( "FAIL" )

    BFL = BFL&~BFL_REZZING;
    rez();

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
        
        llOwnerSay("Error: Asset trying to fetch desc, but desc not found "+(str)id);
        return;
        
    }
    
    Portal$init( 
        SENDER_KEY, 
        l2s(descQueue, pos+2), 
        l2s(descQueue, pos+3),
        l2s(descQueue, pos+4)    
    );
    descQueue = llDeleteSubList(descQueue, 0, 4);
		
    // Continue
    if( id == IDX ){
        
        BFL = BFL&~BFL_REZZING;
        unsetTimer("FAIL");
        rez();
        
    }

end

handleOwnerMethod( RezzerMethod$initialized )
	raiseEvent(RezzerEvt$rezzed, SENDER_KEY);
end


#include "ObstacleScript/end.lsl"


