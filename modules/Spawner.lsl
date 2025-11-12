
#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

#define FACE_SIZE 1016
#define TABLE_SIZE (FACE_SIZE*2-1)

int STATIC_SPAWNED; 	// True when PortalConst$spawnGroup$static has been spawned.
string SAVE_ROUND;      // When calling a save, this is the label
int DEL_ON_INSERT;		// If true, we tell the asset to derez after adding it

fetchAssets(){

	list assets;
	integer i;
	for(; i < llGetInventoryNumber(INVENTORY_OBJECT); ++i ){
		assets += llGetInventoryName(INVENTORY_OBJECT, i);
		if( llStringLength(mkarr(assets)) > 400 ){
			Repo$enum( SpawnerMethod$callbackRepoEnum, assets );
			assets = [];
		}
	}
	if( count(assets) )
		Repo$enum( SpawnerMethod$callbackRepoEnum, assets );
}


string getBatchData( list spawnData, integer live ){
	return mkarr(
		l2s(spawnData, SpawnerConst$E_NAME) +
		(llGetRootPosition()+(vector)l2s(spawnData, SpawnerConst$E_POS)) +
		l2s(spawnData, SpawnerConst$E_ROT) + 
		l2s(spawnData, SpawnerConst$E_DESC) + 
		l2s(spawnData, SpawnerConst$E_GROUP) +  
		live
	);
}


// Helps rez asynchronously by only sending 10 items to the rezzer at a time, and only when it's handling fewer than 5 items
list SPAWNQUEUE;		// (str)table, (int)continue_from_index, (int)live
#define SQSTRIDE SpawnerConst$queueStride
spawnBatch(){

	if( SPAWNQUEUE == [] ){
		return;
	}
	
	setTimeout("SP", 0.5);
	
	int rezzerQueue = RezzerGet$queueLength();
	if( rezzerQueue >= 10 )
		return;
	
	list groups = llJson2List(l2s(SPAWNQUEUE, SpawnerConst$queueIndex$groups));
	int startFrom = l2i(SPAWNQUEUE, SpawnerConst$queueIndex$current);			// Tracks the row in the table
	int live = l2i(SPAWNQUEUE, SpawnerConst$queueIndex$live);
	str cb = l2s(SPAWNQUEUE, SpawnerConst$queueIndex$cb);
	integer spawned = l2i(SPAWNQUEUE, SpawnerConst$queueIndex$spawned);			// Tracks the nr of items we've spawned

	list batch;
	idbForeachFrom(idbTable$SPAWNS, idx, data, startFrom)
	
		list spawn = llJson2List(data);
		if( ~llListFindList(groups, (list)l2s(spawn, 4)) && llStringLength(data) ){
		
			batch += getBatchData(spawn, live);
			
			if( count(batch) == 10 ){
			
				Rezzer$rezMulti( 
					LINK_THIS, 
					batch
				);
				
				startFrom = idx+1;
				SPAWNQUEUE = llListReplaceList(SPAWNQUEUE, (list)startFrom, SpawnerConst$queueIndex$current, SpawnerConst$queueIndex$current);
				SPAWNQUEUE = llListReplaceList(SPAWNQUEUE, (list)(spawned+10), SpawnerConst$queueIndex$spawned, SpawnerConst$queueIndex$spawned);
				
				spawnQueueChanged();
				return; // REACHED CAP
			
			}
			
		}
		
	end

	// If we reached this point, we're done with this spawn cycle
	if( count(batch) )
		Rezzer$rezMulti(LINK_THIS, batch);
		
	//qd("Batch: " + count(batch) + " idx " + idx +" max " + idbGetIndex(idbTable$SPAWNS));
	// This time we can trigger the callback
	if( cb != JSON_INVALID && (count(batch) || idx == idbGetIndex(idbTable$SPAWNS)) )
		Rezzer$cb(LINK_THIS, cb);

	SPAWNQUEUE = llDeleteSubList(SPAWNQUEUE, 0, SQSTRIDE-1);
	spawnQueueChanged();

}


spawnQueueChanged(){

	idbSet(idbTable$SPAWNER, idbTable$SPAWNER$QUEUE, mkarr(SPAWNQUEUE));
	raiseEvent(SpawnerEvt$queueChanged, []);
	
}

// XMOD BEGIN //
#include "ObstacleScript/begin.lsl"

onStateEntry()

	if( llGetStartParameter() == 1 )
		Level$scriptInit();
    
end

// Continue spawning unless rezzer is busy
handleTimer( "SP" )
	spawnBatch();
end


onLevelInit()
	
	fetchAssets();

end


handleOwnerMethod( SpawnerMethod$devMeta )
	
	int task = argInt(0);
	if( task == SpawnerMethod$devMeta$plPos )
		llOwnerSay((string)(prPos(SENDER_KEY)-llGetRootPosition()));
	

end

handleOwnerMethod( SpawnerMethod$offsetAll )

	vector offs = argVec(0);
	integer max = idbGetIndex(idbTable$SPAWNS);
	integer i;
	for( ; i < max; ++i ){
	
		str row = idbGetByIndex(idbTable$SPAWNS, i);
		if( row ){
			integer valid = TRUE;
			list data = llJson2List(row);
			vector pos = (vector)l2s(data, 1);
			vector new = pos+offs;
			qd(i + pos + "->" + new);
			data = llListReplaceList(data, (list)new, 1, 1);
			idbSetByIndex(idbTable$SPAWNS, i, mkarr(data));
		}
	}
	
end

handleOwnerMethod( SpawnerMethod$callbackRepoEnum )

    integer i;
    for(; i < count(METHOD_ARGS); ++i ){
        
        string asset = l2s(METHOD_ARGS, i);
        integer itype = llGetInventoryType(asset);
        if( itype != INVENTORY_NONE && itype != INVENTORY_SCRIPT )
            llRemoveInventory(asset);
        
    }
    
	
    Repo$fetch(SpawnerMethod$callbackRepoFetch, METHOD_ARGS);
    
end

handleOwnerMethod( SpawnerMethod$reset )
    llResetScript();
end

handleOwnerMethod( SpawnerMethod$listSpawns )
    
	integer start = argInt(0);
	str filter;
	integer filterField; // When set to -1, quick filter
	integer filterLen = -1;
	integer ch0 = llOrd(argStr(0), 0);
	if( ch0 < 0x30 || ch0 > 0x39 ){
		// Quick filter that searches spawns by name
		filter = argStr(0);
		filterField = -1;
	}
	else if( ~llSubStringIndex(argStr(0), "=") ){
		
		list spl = split(argStr(0), "=");
		start = 0;
		filterField = l2i(spl, 0);
		filter = llToLower(l2s(spl, 1));
		
		// A percent sign allows wildcards after that point
		filterLen = llSubStringIndex(filter, "%");
		if( ~filterLen ){
			--filterLen;
			filter = llDeleteSubString(filter, -1, -1);
		}
				
	}
	integer nr = argInt(1);
	if( !nr )
		nr = -1;
    
    integer i;
    llOwnerSay("== SPAWNS ==");
	integer max = idbGetIndex(idbTable$SPAWNS);
	integer found;
	for( i = start; i < max && (found < nr || nr == -1); ++i ){
	
		str row = idbGetByIndex(idbTable$SPAWNS, i);
		if( row ){
			integer valid = TRUE;
			
			// Quick filter
			if( filterField == -1 ){
				
				string fd0 = llToLower(join(split(j(row, SpawnerConst$E_NAME), " "), "_"));
				string fd1 = llToLower(join(split(j(row, SpawnerConst$E_GROUP), " "), "_"));
				valid = ~llSubStringIndex(fd0, filter) || ~llSubStringIndex(fd1, filter);
			}
			else if( filter ){
							
				// Quick filter
				// Escape space with underscore
				string fd = llGetSubString(j(row, filterField), 0, filterLen);
				fd = join(split(fd, " "), "_");
				valid = (filter == llToLower(fd));
				
			}
			
			if( valid ){
				llOwnerSay("["+(str)i+"] "+row);
				++found;
			}
		}
	}

end

handleOwnerMethod( SpawnerMethod$setSpawnValue )
    
    int targ = argInt(0);
	int param = argInt(1);
	string desc = argStr(2);
	
	integer max = idbGetIndex(idbTable$SPAWNS);
	if( targ >= max || targ < 0 ){
		
		llOwnerSay("Unable to modify: Index out of bounds.");
		return;
		
	}
	
	
	string cur = idbGetByIndex(idbTable$SPAWNS, targ);
	list set = llJson2List(cur);
	set = llListReplaceList(set, (list)desc, param, param);
	llOwnerSay("["+(str)targ+"]\nPre: "+cur+"\nPost: "+mkarr(set));
	idbSetByIndex(idbTable$SPAWNS, targ, mkarr(set));

end

handleOwnerMethod( SpawnerMethod$callbackRepoFetch )
    
	int amount = argInt(0);
    qd(((str)amount+" assets have been delivered"));
    
end


handleOwnerMethod( SpawnerMethod$purge )

    idbDropInline(idbTable$SPAWNS);
    llOwnerSay("Purge complete");
    
end


handleOwnerMethod( SpawnerMethod$delete )
    
	integer max = idbGetIndex(idbTable$SPAWNS);
	integer i;
	for(; i < count(METHOD_ARGS); ++i ){
			
		string s = argStr(i);		
		int dash = llSubStringIndex(s, "-");
		list del = (list)s;
		// You can use a-b for a range
		if( ~dash ){
			
			del = [];
			str as = llGetSubString(s, 0, dash-1);
			str bs = llGetSubString(s, dash+1, -1);
			if( llJsonValueType(as, []) != JSON_NUMBER || llJsonValueType(bs, []) != JSON_NUMBER ){
				llOwnerSay("Unable to remove range, non-number detected in '"+s+"'");
			}
			else{
				int a = (int)as;
				int b = (int)bs;
				int sub;
				for(; sub < b-a+1; ++sub )
					del += (a+sub);
			}		
		}
		int sub;
		for(; sub < count(del); ++sub ){
			
			str val = l2s(del, sub);
			int delIndex = (int)val;
			
			if( llJsonValueType(val, []) != JSON_NUMBER ){
				llOwnerSay("Unable to delete '"+val+"', invalid number");
			}
			else if( delIndex >= max || delIndex < 0 ){
				llOwnerSay("Unable to delete '"+val+"', index out of bounds.");
			}
			else{
				
				
				string cur = idbGetByIndex(idbTable$SPAWNS, delIndex);
				if( cur ){
					llOwnerSay("Spawn deleted ["+(str)delIndex+"]: "+cur);
					idbDeleteByIndex(idbTable$SPAWNS, delIndex);
				}
				
			}
			
		}
		
	}

	
    
end


handleOwnerMethod( SpawnerMethod$add )
    
    list pData = llGetObjectDetails(SENDER_KEY, (list)
        OBJECT_POS + OBJECT_ROT + OBJECT_DESC
    );
    
    string desc;
    if( llGetSubString(l2s(pData, 2), 0, 0) == "$" )
        desc = llGetSubString(l2s(pData, 2), 1, -1);
    
    list rot = [0];
    if( l2r(pData, 1) != ZERO_ROTATION )
        rot = (list)allRound(l2r(pData, 1), 2);
		
    string saveData = mkarr(
        llKey2Name(SENDER_KEY) +
        allRound(l2v(pData, 0)-llGetRootPosition(), 2) +
        rot +
        desc +
        SAVE_ROUND
    );
    
	// First off, find an empty slot to put it in
	int max = idbGetIndex(idbTable$SPAWNS);
	integer i; integer out = -1;
	for(; i < max && out == -1; ++i ){
		
		if( idbGetByIndex(idbTable$SPAWNS, i) == "" ){

			out = i;
			idbSetByIndex(idbTable$SPAWNS, i, saveData);
			
		}
		
	}
	
	// No free slot, INSERT new
	if( out == -1 )
		out = idbInsert(idbTable$SPAWNS, saveData);
	
	string kill;
	if( DEL_ON_INSERT ){
		Portal$kill(SENDER_KEY);
		kill = "(Killed)";
	}
	llOwnerSay("Insert ["+(str)out+"]: "+saveData + kill);

end

// Spawn N elements from a group
handleMethod( SpawnerMethod$nFromGroup )
	
	int nr = argInt(0);
	if( nr < 1 )
		nr = 1;
		
	str group = argStr(1);
	list batch; integer i;
	idbForeach(idbTable$SPAWNS, idx, data)
		
		list spawn = llJson2List(data);
		if( l2s(spawn, 4) == group && data != "" )
			batch += getBatchData(spawn, TRUE);
	
	end
	
	Rezzer$rezMulti( 
		LINK_THIS, 
		llList2List(llListRandomize(batch, 1), 0, nr-1)
	);

end


// Spawn a batch
handleOwnerMethod( SpawnerMethod$load )
    
    integer live = argInt(1);
	string cb = argStr(0);
	
    METHOD_ARGS = llDeleteSubList(METHOD_ARGS, 0, 1);
    if( !count(METHOD_ARGS) ){
        
		METHOD_ARGS = (list)"";

    }
	
	integer pos = llListFindList(METHOD_ARGS, (list)PortalConst$spawnGroup$staticOpt);
	if( ~pos ){
		if( STATIC_SPAWNED )
			METHOD_ARGS = llDeleteSubList(METHOD_ARGS, pos, pos);
		else
			METHOD_ARGS = llListReplaceList(METHOD_ARGS, (list)PortalConst$spawnGroup$static, pos, pos);
	}
	
	
	if( ~llListFindList(METHOD_ARGS, (list)"") && !STATIC_SPAWNED ){
		METHOD_ARGS += PortalConst$spawnGroup$static;
	}
	
	if( ~llListFindList(METHOD_ARGS, (list)PortalConst$spawnGroup$static) )
		STATIC_SPAWNED = TRUE;
	
	raiseEvent(SpawnerEvt$loadStart, cb + live + METHOD_ARGS);
	
	
	SPAWNQUEUE += (list)mkarr(METHOD_ARGS) + 0 + live + cb + 0;
	spawnBatch();
	
end

// Spawn specific
handleOwnerMethod( SpawnerMethod$spawnByIndex )
    
    integer live = argInt(0);
    METHOD_ARGS = llDeleteSubList(METHOD_ARGS, 0, 0);
    
	integer i; list batch;
	for(; i < count(METHOD_ARGS); ++i ){
	
		list spawn = llJson2List(idbGetByIndex(idbTable$SPAWNS, l2i(METHOD_ARGS, i)));
		batch += getBatchData(spawn, live);
		
	}
	
	if( count(batch) )
		Rezzer$rezMulti(LINK_THIS, batch);

end


handleOwnerMethod( SpawnerMethod$fetchFromHud )
	fetchAssets();
end

handleOwnerMethod( SpawnerMethod$savePortals )

    SAVE_ROUND = argStr(0);
	if( argStr(0) == "\"\"" )
		SAVE_ROUND = "";
	DEL_ON_INSERT = argInt(1);
    Portal$save();

end

handleOwnerMethod( SpawnerMethod$resetStatic )
	STATIC_SPAWNED = FALSE;
end


#include "ObstacleScript/end.lsl"

