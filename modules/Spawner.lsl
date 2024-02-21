
#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

#define FACE_SIZE 1016
#define TABLE_SIZE (FACE_SIZE*2-1)



string SAVE_ROUND;      // When calling a save, this is the label

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



// XMOD BEGIN //
#include "ObstacleScript/begin.lsl"

onStateEntry()

	if( llGetStartParameter() == 1 )
		Level$scriptInit();
    
end



onLevelInit()
	
	fetchAssets();

end


handleOwnerMethod( SpawnerMethod$devMeta )
	
	int task = argInt(0);
	if( task == SpawnerMethod$devMeta$plPos )
		llOwnerSay((string)(prPos(SENDER_KEY)-llGetRootPosition()));
	

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
	
	llOwnerSay("Insert ["+(str)out+"]: "+saveData);

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
    if( !count(METHOD_ARGS) )
        METHOD_ARGS = (list)"";
    
	raiseEvent(SpawnerEvt$loadStart, cb + live + METHOD_ARGS);
	
	list batch;
	idbForeach(idbTable$SPAWNS, idx, data)
	
		list spawn = llJson2List(data);
		if( ~llListFindList(METHOD_ARGS, (list)l2s(spawn, 4)) && llStringLength(data) ){
		
			batch += getBatchData(spawn, live);
			
			if( count(batch) > 10 ){
			
				Rezzer$rezMulti( 
					LINK_THIS, 
					batch
				);
				batch = [];
			
			}
			
		}
		
	end

	
	if( count(batch) )
		Rezzer$rezMulti(LINK_THIS, batch);
	
	if( cb != JSON_INVALID )
		Rezzer$cb(LINK_THIS, cb);
    

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
    Portal$save();

end


#include "ObstacleScript/end.lsl"

