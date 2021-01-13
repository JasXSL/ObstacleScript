#define USE_STATE_ENTRY
#define USE_ON_REZ
#include "ObstacleScript/index.lsl"

integer SC_MAX;
integer SC;

#include "ObstacleScript/begin.lsl"

onRez( _a )
    llResetScript();
end

onStateEntry()
    
    memLim(2);
    integer i;
    for(; i < llGetInventoryNumber(INVENTORY_SCRIPT); ++i ){
        
        if( llGetSubString(llGetInventoryName(INVENTORY_SCRIPT, i), 0, 2) == "SUB" )
            ++SC_MAX;
        
    }
    
end

handleOwnerMethod( ScrepoMethod$get )
    
    integer pin = argInt(0);
    integer startParam = argInt(1);

    integer i;
    for( i = 2; i < count(METHOD_ARGS); ++i ){
        
        string script = l2s(METHOD_ARGS, i);
        if( 
            llGetInventoryType(script) == INVENTORY_SCRIPT &&
            llGetSubString(script, 0, 2) != "SUB" &&
            script != llGetScriptName()
        ){
            
            llMessageLinked(LINK_THIS, 0, mkarr(
                pin +
                script +
                SENDER_KEY +
                startParam
            ), "SUB"+(str)SC);
			
			++SC;
			if( SC >= SC_MAX )
				SC = 0;
            
        }else
            llOwnerSay("Invalid script: "+script);
        
    }    
    
end

#include "ObstacleScript/end.lsl"


