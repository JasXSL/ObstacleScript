#include "ObstacleScript/helpers/Ghost/GhostHelper.lsb"
#define USE_STATE_ENTRY
#define USE_TIMER
#define USE_LISTEN
#define USE_DATASERVER
#include "ObstacleScript/index.lsl"

list toRead;
key getLines;
string Nc;
int listenChan;

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

list IncomingObjects;
key IncomingSender;
str IncomingScript;		// Script to reply to
int IncomingMethod;		// Method to reply to
list IncomingCategories;

#include "ObstacleScript/begin.lsl"

onStateEntry()
    
    readNotecards();
	listenChan = llCeil(llFrand(0xFFFFFFF));
    llListen(listenChan, "", "", "");
    
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
                else if( field == SceneFile$version )
					k = SceneKey$version;
				else if( field == SceneFile$rotation ){
					k = SceneKey$rotation;
				}
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


handleInternalMethod( SceneMethod$clean )
	Portal$killAllStatic();
	Level$cleanup();
end
handleInternalMethod( SceneMethod$launch )
	
	string levelName = argStr(0);
	// Find the level
	idbForeach(idbTable$SCENES, idx, row)
		
		if( j(row, SceneKey$object) == levelName ){
		
			rotation r = (rotation)j(row, SceneKey$rotation);
			llOwnerSay("Spawning level, please wait...");
			llPlaySound("3c8fc726-1fd6-862d-fa01-16c5b2568db6", .5);	
			llRezAtRoot(argStr(0), llGetPos()+<0,0,9>, ZERO_VECTOR, r, 1);
			return;
			
		}
	
	end
	
	llOwnerSay("Error: Level not found: "+levelName);
	
	
end

handleOwnerMethod( SceneMethod$reqInstall )
	
	IncomingObjects = llJson2List(argStr(0));		// Object names
	IncomingCategories = llJson2List(argStr(1));
	if( IncomingObjects == [] )
		return;
	
	IncomingScript = argStr(2);
	IncomingMethod = argInt(3);
	
	IncomingSender = SENDER_KEY;
	
	int newItems; int replacements;
	integer i;
	for(; i < count(IncomingObjects); ++i ){
		
		int ty = llGetInventoryType(l2s(IncomingObjects, i));
		if( ty == INVENTORY_NONE )
			++newItems;
		else if( ty == INVENTORY_OBJECT )
			++replacements;
		else
			return;
		
	}
	
	list cats;
	for( i = 0; i < count(IncomingCategories); ++i ){
		
		string n = l2s(IncomingCategories, i)+".category";
		if( llGetInventoryType(n) == INVENTORY_NONE )
			cats += l2s(IncomingCategories, i);
	
	}
	IncomingCategories = cats;
	
	string diag = "The object secondlife:///app/objectim/"+(str)SENDER_KEY+"/?name="+llEscapeURL(llKey2Name(SENDER_KEY))+" has requested to install:";
	if( newItems )
		diag += "\n- "+(string)newItems+" new level.";
	if( replacements )
		diag += "\n- "+(string)replacements+" level update.";
	if( count(cats) )
		diag += "\n- "+(string)count(cats)+" category.";
	
	llDialog(llGetOwner(), diag, ["Accept", "Reject"], listenChan);
	
	

end

handleOwnerMethod( SceneMethod$installComplete )

	if( IncomingObjects ){
		
		IncomingObjects = [];
		llOwnerSay("Install completed!");
		readNotecards();
		Browser$refresh();
		
	}
	
end


onListen( ch, msg )
	if( llGetOwnerKey(SENDER_KEY) != llGetOwner() )
		return;
	if( IncomingObjects == [] )
		return;
	
	if( msg == "Accept" ){
		
		// We need to delete the object and manifest
		int i;
		for(; i < count(IncomingObjects); ++i ){
		
			string obj = l2s(IncomingObjects, i);
			if( llGetInventoryType(obj) != INVENTORY_NONE )
				llRemoveInventory(obj);
			if( llGetInventoryType(obj+".scene") != INVENTORY_NONE )
				llRemoveInventory(obj+".scene");
			
		}
		
		runMethod(IncomingSender, IncomingScript, IncomingMethod, mkarr(IncomingObjects) + mkarr(IncomingCategories));
		
	}
	else if( msg == "Reject" ){
		IncomingObjects = [];
	}
	

end


#include "ObstacleScript/end.lsl"




