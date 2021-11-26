#define USE_STATE_ENTRY
#define USE_ON_REZ
#include "ObstacleScript/index.lsl"

integer SC_MAX;
integer SC;

#ifndef NO_DEFERRED
list LOADS;	// (key)id, (float)lastUse, (str)script1, (str)script2...
pruneDeferredLoaders(){
	
	// Start by pruning
	integer i;
	for(; i < count(LOADS) && LOADS != []; ++i ){
		
		if( llGetListEntryType(LOADS, i) == TYPE_KEY ){
			
			key id = l2k(LOADS, i);
			if( llKey2Name(id) == "" ){
			
				removeFromLoads(id);
				--i;
				
			}
			
		}
		
	}
	
	// Prune loads
	while( count(LOADS) > 100 )
		removeFromLoads(l2k(LOADS, 0));

}

// Gets a slice, startPos is where the key is
list getDeferredSlice( integer startPos ){
		
	integer i = startPos+1;
	for(; i < count(LOADS); ++i ){
		
		if( llGetListEntryType(LOADS, i) == TYPE_KEY )
			return llList2List(LOADS, startPos, i-1);
		
	}
	return llList2List(LOADS, startPos, -1);

}

// Gets a deferred loader
key getDeferredLoader( string script, key target ){
	
	pruneDeferredLoaders();	// Needed so we don't try to load from a non-existing deferred

	integer x;
	for(; x < count(LOADS); ++x ){
		
		if( llGetListEntryType(LOADS, x) == TYPE_KEY && llGetTime()-l2f(LOADS, x+1) > 4 && target != l2k(LOADS, x) ){
			
			list slice = getDeferredSlice(x);
			// Need to wait 4 sec, and have successfully remoteloaded the portal onto this
			if( ~llListFindList(slice, (list)"Portal") && ~llListFindList(slice, (list)script) )
				return l2k(LOADS, x);
			
		}
	
	}
	
	return "";

}


int getNumDeferred(){
	
	integer out;
	integer i;
	for(; i < count(LOADS); ++i ){
		
		if( llGetListEntryType(LOADS, i) == TYPE_KEY )
			++out;
		
	}
	return out;
	
}

// Removes a deferred loader
removeFromLoads( key id ){
	
	integer pos = llListFindList(LOADS, (list)id);
	if( pos == -1 )
		return;
		
	integer i;
	for( i = pos+1; i < count(LOADS); ++i ){
		
		if( llGetListEntryType(LOADS, i) == TYPE_KEY ){
		
			LOADS = llDeleteSubList(LOADS, pos, i-1);
			return;
			
		}
		
	}
	LOADS = llDeleteSubList(LOADS, pos, -1);
	//qd("After DEL" + LOADS);

}


addDeferredLoaderScript( key targ, string script ){
	
	// Portal is too important to defer.
	integer pos = llListFindList(LOADS, (list)targ);
	if( ~pos )
		LOADS = llListInsertList(LOADS, (list)script, pos+2);
	else
		LOADS += (list)targ + 0 + script;
	
	//qd("LOADS:" + LOADS);
	
	pruneDeferredLoaders();
	//qd("Deferred loaders: "+getNumDeferred());

}


#define LM_PRE \
	onLm( link, nr, s, id );

onLm( int link, int nr, string s, key id ){
	
	// A script was successfully loaded
	if( !nr && s == "LD" ){
		
		list data = llJson2List((str)id);
		key targ = l2s(data, 0);
		string script = l2s(data, 1);
		addDeferredLoaderScript( targ, script );

	}
	
}
#endif

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

handleOwnerMethod( ScrepoMethod$deferredLoad )
	
	addDeferredLoaderScript( argKey(0), argStr(1) );
	
end

#ifndef NO_DEFERRED
handleOwnerMethod( ScrepoMethod$dump )
	
	llOwnerSay("Deferred loaders:");
    integer i;
	for(; i < count(LOADS); ++i ){
		
		if( llGetListEntryType(LOADS, i) == TYPE_KEY )
			llOwnerSay(mkarr(getDeferredSlice(i)));
					
	}
	
	// purge
	pruneDeferredLoaders();
	qd("After purge");
	qd(LOADS);
	
end
#endif

handleOwnerMethod( ScrepoMethod$get )
    
    integer pin = argInt(0);
    integer startParam = argInt(1);
	bool noDeferred;
	list scripts = llJson2List(argStr(2));
	// Legacy conversion
	if( llJsonValueType(argStr(2), []) != JSON_ARRAY )
		scripts = llDeleteSubList(METHOD_ARGS, 0, 1);
	else
		noDeferred = argInt(3);

    integer i;
    for( ; i < count(scripts); ++i ){
        
        string script = l2s(scripts, i);
        if( 
            llGetInventoryType(script) == INVENTORY_SCRIPT &&
            llGetSubString(script, 0, 2) != "SUB" &&
            script != llGetScriptName()
        ){
			
			
			#ifndef NO_DEFERRED
			key deferredLoader = getDeferredLoader(script, SENDER_KEY);
			if( deferredLoader != "" && !noDeferred /*&& script != "Portal"*/ ){
				
				//qd("DEFER:" + (str)deferredLoader + script + " >> " + (str)SENDER_KEY);
				Portal$remoteLoad( 
					deferredLoader, 
					SENDER_KEY, 
					script, 
					pin, 
					startParam 
				);
				integer pos = llListFindList(LOADS, (list)deferredLoader);
				if( ~pos )
					LOADS = llListReplaceList(LOADS, (list)llGetTime(), pos+1, pos+1);
				//qd("Deferred" + script + "to" + llGetSubString((str)deferredLoader, 0, 3) );
				
			}
			else{
			#endif
				//qd("LOCAL: " + script + " >> " + (str)SENDER_KEY + " TO "+(str)SC);
				llMessageLinked(LINK_THIS, 0, mkarr(
					pin +
					script +
					SENDER_KEY +
					startParam
				), "SUB"+(str)SC);
				
				++SC;
				if( SC >= SC_MAX )
					SC = 0;

			#ifndef NO_DEFERRED					
            }
			#endif
        }else
            llOwnerSay("Invalid script: "+script);
        
    }    
    
end

#include "ObstacleScript/end.lsl"


