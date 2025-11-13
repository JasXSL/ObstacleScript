#include "ObstacleScript/helpers/Ghost/GhostHelper.lsb"
#define USE_STATE_ENTRY
#define USE_TIMER
#define USE_DATASERVER
#include "ObstacleScript/index.lsl"

list toRead;
key getLines;
string Nc;

readNotecards(){
    
    idbDropInline(idbTable$SCENES);
    idbDropInline(idbTable$CATEGORIES);
    
    
    integer i;
    for(; i < llGetInventoryNumber(INVENTORY_NOTECARD); ++i ){
        
        string name = llGetInventoryName(INVENTORY_NOTECARD, i);
        list sn = split(name, ".");
        string ext = llList2String(sn, -1);
        // Scenes need to have an object tied to them
        if( ext == "scene" ){
            string obj = join(llDeleteSubList(sn, -1, -1), ".");
            if( llGetInventoryType(obj) != INVENTORY_OBJECT )
                llOwnerSay("Missing scene: "+obj);
            else
                toRead += name;
        }
        else
            toRead += name;
        
    }
    
    readNext();
    
}

readNext(){
    if( toRead == [] ){
        qd("Cached" + idbGetIndex(idbTable$SCENES) + "scenes and " + idbGetIndex(idbTable$CATEGORIES) + "categories");
        return;
    }
    
    Nc = l2s(toRead, 0);
    getLines = llGetNumberOfNotecardLines(Nc);
    
}


#include "ObstacleScript/begin.lsl"

onStateEntry()
    
    readNotecards();
    
    
end

handleTimer( "CONT" )
    readNext();
end

onDataserver( req, data )
    
    if( req != getLines )
        return;
    
    list na = split(Nc, ".");
    string ncName = join(llDeleteSubList(na, -1, -1), ".");
    string ncFile = llToLower(l2s(na, -1));
    
    integer i; integer lines = (integer)data;
    string proto = llList2Json(JSON_OBJECT, [
        SceneKey$name, "Unnamed",
        SceneKey$category, "wipeout",
        SceneKey$minPlayers, 1,
        SceneKey$maxPlayers, 16,
        SceneKey$landImpact, 0,
        SceneKey$creator, "Unknown",
        SceneKey$object, ncName
    ]);
    string table = idbTable$SCENES;
    if( ncFile == "category" ){
        table = idbTable$CATEGORIES;
        proto = llList2Json(JSON_OBJECT, [
            CategoryKey$description, "Unknown",
            CategoryKey$color, "#EEEEEE",
            CategoryKey$label, llToLower(ncName)
        ]);
    }
    
    integer success = TRUE;
    for(; i < lines; ++i ){
        string line = llGetNotecardLineSync(Nc, i);
        if( line == NAK ){
            success = FALSE;
        }
        else{
            list spl = split(line, ":");
            string field = llToLower(trim(l2s(spl, 0)));
            string k; string v = trim(l2s(spl, 1));
            
            if( ncFile == "category" ){
                
                if( field == CategoryFile$description )
                    k = CategoryKey$description;
                else if( field == CategoryFile$color )
                    k = CategoryKey$color;                    
                
            }
            else if( ncFile == "scene" ){
                
                if( field == SceneFile$name )
                    k = SceneKey$name;
                else if( field == SceneFile$category ){
                    k = SceneKey$category;
                    v = llToLower(v);
                }
                else if( field == SceneFile$minPlayers ){
                    k = SceneKey$minPlayers;
                    v = (string)((int)v);
                }
                else if( field == SceneFile$maxPlayers ){
                    k = SceneKey$maxPlayers;
                    v = (string)((int)v);
                }
                else if( field == SceneFile$description )
                    k = SceneKey$description;
                else if( field == SceneFile$landImpact ){
                    k = SceneKey$landImpact;
					v = (string)((int)v);
				}
                else if( field == SceneFile$creator )
                    k = SceneKey$creator;
                
            }
            if( k )
                proto = llJsonSetValue(proto, (list)k, v);
            
        }
    }
    
    if( success ){
        idbInsert(table, proto);
        toRead = llDeleteSubList(toRead, 0, 0);
    }
        
    setTimeout("CONT", 0.1);
    
end

/*
handleOwnerMethod()
    raiseEvent(GhostToolEvt$data, METHOD_ARGS);
end
*/

#include "ObstacleScript/end.lsl"




