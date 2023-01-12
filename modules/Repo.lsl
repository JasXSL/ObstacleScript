#define USE_STATE_ENTRY
#include "ObstacleScript/index.lsl"


list getViablePrims( list input ){
    
    list existing;
    integer i;
    
    for( ; i < llGetInventoryNumber(INVENTORY_ALL); ++i ){
        
        string n = llGetInventoryName(INVENTORY_ALL, i);

        if( ~llListFindList(input, (list)n) )
            existing += n;
        
    }
    
    return existing;
    
}


#include "ObstacleScript/begin.lsl"

onStateEntry()
    
end

handleOwnerMethod( RepoMethod$enum )
    
    integer callback = argInt(0);
    string cscript = argStr(1);
    
    list out = getViablePrims(llDeleteSubList(METHOD_ARGS, 0, 1));
    runMethod(SENDER_KEY, cscript, callback, out);
    
end

handleOwnerMethod( RepoMethod$fetch )
    
    integer callback = argInt(0);
    string cscript = argStr(1);
    
    list out = getViablePrims(llDeleteSubList(METHOD_ARGS, 0, 1));
    integer i;
    for(; i < count(out); ++i ) 
        llGiveInventory(SENDER_KEY, l2s(out, i));
    
    runMethod(SENDER_KEY, cscript, callback, count(out));
    

    for( i = 2; i < count(METHOD_ARGS); ++i ){
        
        string asset = llList2String(METHOD_ARGS, i);
        if( llListFindList(out, (list)asset) == -1 )
            llOwnerSay("Inventory missing: "+asset);
    
    }
       
end


#include "ObstacleScript/end.lsl"



