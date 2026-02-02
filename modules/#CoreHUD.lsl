 #define USE_ON_REZ
#define USE_STATE_ENTRY
#define USE_LISTEN

#include "ObstacleScript/index.lsl"

#include "ObstacleScript/begin.lsl"


onRez( nr )
    llResetScript();  
end

onStateEntry()
    
    // No data needs to be stored in the HUD LSD
    llLinksetDataReset();
    globalAction$resetAll();
    llListen(0, "", llGetOwner(), "");
    
end

onListen( ch, msg )
    
    list spl = split(msg, " ");
    str type = l2s(spl, 0);
    spl = llDeleteSubList(spl, 0, 0);
    
    if( type == "A2R" ){
        vector v = (vector)join(spl, "");
        llOwnerSay("Angle to rot ("+(string)v+") -> "+(string)llEuler2Rot(v*DEG_TO_RAD));
    }
    
    if( type == "VEC" ){
        
        list inputs = llParseString2List(join(spl, " "), [">"], []);
        vector out;
        integer i;
        for( ; i < count(inputs); ++i ){
            
            string mod = llStringTrim(l2s(inputs, i), STRING_TRIM)+">";
            if( !i )
                out = (vector)mod;
            else{
                
                string operation = llGetSubString(mod, 0, 0);
                mod = llStringTrim(llGetSubString(mod, 1, -1), STRING_TRIM);
                
                vector v = (vector)mod;
                if( operation == "+" )
                    out += v;
                else if( operation == "-" )
                    out -= v;
                else
                    llOwnerSay("Unknown operation: "+operation);                
            }
            
        }
        llOwnerSay((string)out);
        
    }

    // Saves all rezzed items
    // // Usage: SAVE <group="">
    if( type == "SAVE" ){
        llOwnerSay("Adding all spawned assets to DB");
        runOmniMethod("Spawner", SpawnerMethod$savePortals, join(spl, " "));
    }
    else if( type == "SAVEDEL" ){
        llOwnerSay("Adding all spawned assets to DB");
        runOmniMethod("Spawner", SpawnerMethod$savePortals, join(spl, " ") + 1);
    }
    // Delete the whole DB
    // Usage: TRUNCATE ALL
    else if( msg == "TRUNCATE ALL" ){
        runOmniMethod("Spawner", SpawnerMethod$purge, []);
    }
    // Unrez all portal objects
    // Usage: CLOSE
    else if( msg == "CLOSE" ){
        Portal$killAll();
    }
    else if( msg == "CLOSE ALL" ){
        Portal$killAllStatic();
    }
    else if( type == "OFFSALL" )
        Spawner$offsetAll(join(spl, ""));
    // Delete an item by index
    // Usage: DELETE <idx>
    else if( type == "DELETE" ){
        runOmniMethod("Spawner", SpawnerMethod$delete, spl);
        Spawner$resetStaticOmni();
    }
    // List spawns
    // Usage: LIST, (int)tail
    else if( type == "LIST" ){
        runOmniMethod("Spawner", SpawnerMethod$listSpawns, l2s(spl, 0) + l2i(spl, 1));
    }
    
    else if( type == "POS" )
        Spawner$devMeta(SpawnerMethod$devMeta$plPos);
    else if( type == "STARTPOS" )
        Level$setStartPos( llGetRootPosition(), llGetRootRotation(), TRUE);
    // Set group of an index
    // Usage: SETGROUP <idx> <group>
    else if( type == "SETGROUP" ){
        
        runOmniMethod(
            "Spawner", 
            SpawnerMethod$setSpawnValue, 
            l2i(spl, 0) + 4 + join(llDeleteSubList(spl, 0, 0), " ")
        );
        
    }
    // Updates description of an asset by index
    // Usage: SETDESC <idx> <desc>
    else if( type == "SETDESC" ){
        
        runOmniMethod(
            "Spawner", 
            SpawnerMethod$setSpawnValue, 
            l2i(spl, 0) + 3 + join(llDeleteSubList(spl, 0, 0), " ")
        );
        
    }
    // Spawns a group as nonlive
    // Usage: LOAD <group>
    else if( type == "LOAD" ){
        
        llOwnerSay("Loading");
        runOmniMethod(
            "Spawner", 
            SpawnerMethod$load, 
            JSON_INVALID + 0 + join(spl, " ")
        );
        
    }
    // Spawns a group as live
    else if( type == "LIVE" ){
        
        llOwnerSay("Loading live");
        runOmniMethod(
            "Spawner", 
            SpawnerMethod$load, 
            JSON_INVALID + 1 + join(spl, " ")
        );
        
    }
    
    // Spawns selected assets live by index
    // Usage: SPAWN id1 id2 id3...
    else if( type == "SPAWN" ){
        
        list l; integer i;
        for( ; i < count(spl); ++i )
            l += l2i(spl, i);
        
        qd("Spawning live " + l);
        runOmniMethod(
            "Spawner", 
            SpawnerMethod$spawnByIndex, 
            1 + l
        );
        
    }
    // Spawns selected assets nonlive by index
    else if( type == "TEST" ){
        
        
        list l; integer i;
        for( ; i < count(spl); ++i )
            l += l2i(spl, i);
        
        qd("Testing " + l);
            
        runOmniMethod(
            "Spawner", 
            SpawnerMethod$spawnByIndex, 
            0 + l
        );
        
    }
    else if( type == "SOUND" )
        llTriggerSound(l2s(spl, 0), 1);

end

handleMethod( 0 )
    globalAction$resetAll();
    llResetScript();
end


#include "ObstacleScript/end.lsl"

