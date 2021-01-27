
#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

#define FACE_SIZE 1016
#define TABLE_SIZE (FACE_SIZE*2-1)

// DB tables are structured as [TABLE_NAME, data1, data2...]
integer P_DB;   // Database prim
list DB_TABLES = [-1, -1];  // contains faces, index mapped to TABLE_* below
list DB_MAP = ["SPA","SPB"];    // Shorthand labels for above
#define TABLE_SPAWNS_A 0
#define TABLE_SPAWNS_B 1
list ASSET_TABLES = [
    TABLE_SPAWNS_A, TABLE_SPAWNS_B
];

string SAVE_ROUND;      // When calling a save, this is the label
integer SAVE_NR;        // When calling a save, this store nr of items saved

string stripHTTP( string input ){
    
    if( input == "https://" || input == "http://" )
        return "";
    
    integer pos = llSubStringIndex(input, "//");
    if( ~pos )
        return llGetSubString(input, pos+2, -1);
    return input;
}
list getTableData( integer table ){
    
    integer face = l2i(DB_TABLES, table);
    return llDeleteSubList(llJson2List(
        stripHTTP(
            (string)llGetLinkMedia(P_DB, face, [PRIM_MEDIA_HOME_URL])
        )+
        stripHTTP(
            (string)llGetLinkMedia(P_DB, face, [PRIM_MEDIA_CURRENT_URL])
        )
    ), 0, 0);
    
}
setTableData( integer table, list data ){
    
    integer face = l2i(DB_TABLES, table);
    string output = mkarr(l2s(DB_MAP, table) + data);
    llSetLinkMedia(P_DB, face, (list)
        PRIM_MEDIA_PERMS_INTERACT + PRIM_MEDIA_PERM_NONE +
        PRIM_MEDIA_PERMS_CONTROL + PRIM_MEDIA_PERM_NONE +
        PRIM_MEDIA_HOME_URL + ("http://"+llGetSubString(output, 0, FACE_SIZE-1)) +
        PRIM_MEDIA_CURRENT_URL + ("http://"+llGetSubString(output, FACE_SIZE, FACE_SIZE*2-1))
    );
    
}

fetchAssets(){

	list assets;
	integer i;
	for(; i < llGetInventoryNumber(INVENTORY_OBJECT); ++i )
		assets += llGetInventoryName(INVENTORY_OBJECT, i);
    Repo$enum( SpawnerMethod$callbackRepoEnum, assets );

}


#include "ObstacleScript/begin.lsl"

onStateEntry()

	if( llGetStartParameter() == 1 )
		Level$scriptInit();
    	
	integer i;
    for( i = 1; i <= llGetNumberOfPrims(); ++i ){
        
        string name = llGetLinkName(i);
        if( name == "DB" )
            P_DB = i;
        
    } 
    
    if( !P_DB ){
        llDialog(llGetOwner(), "DB prim missing! Please make a box, name it DB, link it to the level, and then say debug Spawner", [], 123);
        return;
    }
    
    integer nrFaces = llGetLinkNumberOfSides(P_DB);
    if( nrFaces < count(DB_TABLES) ){
        llDialog(llGetOwner(), "DB prim does not have enough sides! Please use a cube.", [], 123);
        return;
    }
    

    list emptyFaces;
    
    // Find existing tables
    for( i = 0; i < nrFaces; ++i ){
        
        list data = llJson2List(
            stripHTTP(
                (string)llGetLinkMedia(P_DB, i, [PRIM_MEDIA_HOME_URL])
            )+
            stripHTTP(
                (string)llGetLinkMedia(P_DB, i, [PRIM_MEDIA_CURRENT_URL])
            )
        );
        
        string table = l2s(data, 0);
        integer pos = llListFindList(DB_MAP, (list)table);
        if( ~pos )
            DB_TABLES = llListReplaceList(DB_TABLES, (list)i, pos, pos);
        else
            emptyFaces += i;
        
    }
    
    // Create missing tables
    for( i = 0; i < count(DB_TABLES); ++i ){
        
        if( l2i(DB_TABLES, i) == -1 ){
            
            integer face = l2i(emptyFaces, 0);
            emptyFaces = llDeleteSubList(emptyFaces, 0, 0);
            string table = l2s(DB_MAP, i);
            
            llSetLinkMedia(P_DB, face, (list)
                PRIM_MEDIA_PERMS_INTERACT + PRIM_MEDIA_PERM_NONE +
                PRIM_MEDIA_PERMS_CONTROL + PRIM_MEDIA_PERM_NONE +
                PRIM_MEDIA_HOME_URL + ("http://"+mkarr(table)) +
                PRIM_MEDIA_CURRENT_URL + "http://"
            );
            llOwnerSay("Created table: " + table);
            
        }
        
    }    
    
end



onLevelInit()
	
	fetchAssets();

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
    
    
    integer index;
    integer i;
    llOwnerSay("== SPAWNS ==");
    for( ; i < count(ASSET_TABLES); ++i ){
        
        list data = getTableData(l2i(ASSET_TABLES, i));
        integer spawn;
        for(; spawn < count(data); ++spawn ){
            
            llOwnerSay("["+(str)index+"] "+l2s(data, spawn));
            ++index;
            
        }
        
    }
    

end

handleOwnerMethod( SpawnerMethod$setSpawnValue )
    
    int targ = argInt(0);
	int param = argInt(1);
	string desc = argStr(2);
	
    integer index;
    integer i;
    for( ; i < count(ASSET_TABLES); ++i ){
        
        list data = getTableData(l2i(ASSET_TABLES, i));
        // The object is in this table
        if( index+count(data) >= targ ){
            
            integer de = targ-index;
			
			// Get object settings
			list settings = llJson2List(l2s(data, de));
			settings = llListReplaceList(settings, (list)desc, param, param);
			
			
			data = llListReplaceList(data, (list)mkarr(settings), de, de);
            setTableData(l2i(ASSET_TABLES, i), data);
            llOwnerSay("Object updated");
            return;
            
        }
        index += count(data);
        
    }
    
    llOwnerSay("Object not found");
    

end

handleOwnerMethod( SpawnerMethod$callbackRepoFetch )
    
    qd("All assets have been delivered");
    
end


handleOwnerMethod( SpawnerMethod$purge )

    integer i;
    for( ; i < count(ASSET_TABLES); ++i )
        setTableData(l2i(ASSET_TABLES, i), []);
    llOwnerSay("Purge complete");
    
end


handleOwnerMethod( SpawnerMethod$delete )
    
    integer delIndex = argInt(0);

    
    integer index;
    integer i;
    for( ; i < count(ASSET_TABLES); ++i ){
        
        list data = getTableData(l2i(ASSET_TABLES, i));
        // The object is in this table
        if( index+count(data) >= delIndex ){
            
            integer de = delIndex-index;
            data = llDeleteSubList(data, de, de);
            setTableData(l2i(ASSET_TABLES, i), data);
            llOwnerSay("Object deleted");
            return;
            
        }
        index += count(data);
        
    }
    
    llOwnerSay("Object not found");
    
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
    
    integer i;
    for( ; i < count(ASSET_TABLES); ++i ){
        
        list data = getTableData(l2i(ASSET_TABLES, i));
        if( llStringLength(mkarr(data))+llStringLength(saveData)+8 <= TABLE_SIZE ){
            
            data += saveData;
            setTableData(l2i(ASSET_TABLES, i), data);
            ++SAVE_NR;
            return;
            
        }
        
    }
	
	qd("Error: out of DB space");

end


// Spawn a batch
handleOwnerMethod( SpawnerMethod$load )
    
    integer live = argInt(1);
	string cb = argStr(0);
	
    METHOD_ARGS = llDeleteSubList(METHOD_ARGS, 0, 1);
    if( !count(METHOD_ARGS) )
        METHOD_ARGS = (list)"";
    
	raiseEvent(SpawnerEvt$loadStart, cb + live + METHOD_ARGS);
	
    integer i;
    for( ; i < count(ASSET_TABLES); ++i ){
        
        list data = getTableData(l2i(ASSET_TABLES, i));
        integer idx;
        for( ; idx < count(data); ++idx ){
            
            list spawn = llJson2List(l2s(data, idx));
            if( ~llListFindList(METHOD_ARGS, (list)l2s(spawn, 4)) )
                Rezzer$rez( 
                    LINK_THIS, 
                    l2s(spawn, 0),
                    (llGetRootPosition()+(vector)l2s(spawn, 1)), 
                    l2s(spawn, 2),
                    l2s(spawn, 3),
                    l2s(spawn, 4), 
                    live
                );
            
        }
        
    }
	
	if( cb != JSON_INVALID )
		Rezzer$cb(LINK_THIS, cb);
    

end

// Spawn specific
handleOwnerMethod( SpawnerMethod$spawnByIndex )
    
    integer live = argInt(0);
    METHOD_ARGS = llDeleteSubList(METHOD_ARGS, 0, 0);
    	
	integer I;
    integer i;
    for( ; i < count(ASSET_TABLES); ++i ){
        
        list data = getTableData(l2i(ASSET_TABLES, i));
        integer idx;
        for( ; idx < count(data); ++idx ){
            
            list spawn = llJson2List(l2s(data, idx));
            if( ~llListFindList(METHOD_ARGS, (list)I) ){
			
                Rezzer$rez( 
                    LINK_THIS, 
                    l2s(spawn, 0),
                    (llGetRootPosition()+(vector)l2s(spawn, 1)), 
                    l2s(spawn, 2),
                    l2s(spawn, 3),
                    l2s(spawn, 4), 
                    live
                );
			}
			
			++I;
            
        }
        
    }
    

end


handleOwnerMethod( SpawnerMethod$fetchFromHud )
	fetchAssets();
end




handleOwnerMethod( SpawnerMethod$savePortals )

    SAVE_NR = 0;
    SAVE_ROUND = argStr(0);
    Portal$save();
    setTimeout("ADD", 6);

end
handleTimer( "ADD" )
    
    llOwnerSay("Saved "+(str)SAVE_NR+" assets!");

end


#include "ObstacleScript/end.lsl"

