/*
	This script offloads GhostNodes.template by taking care of pathing.
	
	
*/
#define USE_TIMER
#define USE_STATE_ENTRY
#define SE_OVERRIDE handleStateEntry();
//#include "ObstacleScript/helpers/Ghost/GhostHelper.lsb"
#include "ObstacleScript/index.lsl"

#ifndef debugUncommon
	#define debugUncommon(text)
#endif

// Portals are the little boxes that mark entrances to rooms
list portals;      // 8bArray roomIndexes, (int)linkNum
#define getRoomLabel( idx ) idbGetByIndex(idbTable$NODES_ROOM_LABELS, (idx))
#define portal2names( bitArray8 ) ((list)getRoomLabel(bitArray8&0xFF) + getRoomLabel((bitArray8>>8)&0xFF))


integer getRoomIndexByTable( str name, str table ){

	idbForeach( table, i, val )
		
		if( val == name )
				return i;
	
	end
	return -1;
	
}
#define getRoomIndexByLabel(label) getRoomIndexByTable((label), idbTable$NODES_ROOM_LABELS)
#define getRoomIndexByReadable(name) getRoomIndexByTable((name), idbTable$NODES_ROOM_NAMES)


list adjacentRoomIndexes( integer roomIndex ){
    
    list out;
    integer i;
    for( ; i < count(portals); i += 2 ){
        integer v = l2i(portals, i);
        integer a = (v >> 8)&0xFF;
        integer b = v & 0xFF;
        integer find = -1;
        if( a == roomIndex )
            find = b;
        else if( b == roomIndex )
            find = a;
            
        if( ~find ){
            if( llListFindList(out, (list)find ) == -1 )
                out += find;
        }
        
    }
    
    return out;
            
}

// Creates a path of room indexes to walk
list findShortestPath( string fromLabel, string toLabel ){
    
    integer fromIndex = getRoomIndexByLabel(fromLabel);
    integer toIndex = getRoomIndexByLabel(toLabel);
    list queue = (list)mkarr(fromIndex);
    list visited = (list)fromIndex;
    
    while( queue != [] ){
        
        list currentPath = llJson2List(l2s(queue, 0));
        queue = llDeleteSubList(queue, 0, 0);
        
        integer currentRoom = l2i(currentPath, -1);
        if( currentRoom == toIndex )
            return currentPath;
        
        list adjacentRoomIndexes = adjacentRoomIndexes(currentRoom);
        
        // Debug
        list adjacentNames;
        integer n;
        for(; n < count(adjacentRoomIndexes); ++n )
            adjacentNames += getRoomLabel(l2i(adjacentRoomIndexes, n));
        // Debug
        
        integer i;
        for( ; i < count(adjacentRoomIndexes); ++i ){
            
            integer ri = l2i(adjacentRoomIndexes, i);
            if( llListFindList(visited, (list)ri) == -1 ){
                
                visited += ri;
                queue += mkarr(currentPath + ri);
                
            }
            
        }
        
    }
    
    return [];
    
}

integer getPortalLinkByRooms( integer a, integer b ){
    
    integer i;
    for(; i < count(portals); i += 2 ){
        
        integer arr = l2i(portals, i);
        integer ta = arr & 0xFF;
        integer tb = (arr>>8) & 0xFF;
        
        // Todo: Find 
        if( (ta == a || ta == b) && (tb == a || tb == b) )
            return l2i(portals, i+1);

    }
    
    return -1;
    
}

list pathToPortals( list roomIndexes ){
    
    list out;
    integer i;
    for( i = 1; i < count(roomIndexes); ++i ){
        
        integer pre = l2i(roomIndexes, i-1);
        integer cur = l2i(roomIndexes, i);
        integer portal = getPortalLinkByRooms(pre, cur);
        if( portal == -1 ){
            llOwnerSay("Unable to find viable portal for rooms "+(str)pre+":"+(str)cur);
            return [];
        }
        out += portal;
        
    }
    return out;
    
}

list getLinkKeys( list links ){
	
	list out; integer i;
	for( ; i < count(links); ++i ){
		
		out += llGetLinkKey(l2i(links, i));
		
	}
	
	return out;

}


begin(){
	
	portals = [];
	list found;
	
	list rindex;
	// fetch ghost labels
	idbForeach(idbTable$NODES_ROOM_LABELS, idx, val)
		rindex += val;
	end
	
	// Sanity check our portals
	links_each( nr, name,
		
		if( name == "PORTAL" ){
			
			list spl = split(prDesc(llGetLinkKey(nr)), ":");
			integer i;
			for(; i < count(spl); ++i ){
				
				string n = l2s(spl, i);
				if( ~llListFindList(found, (list)n ) ){}
				else if( llListFindList(rindex, (list)n) == -1 ){
					llOwnerSay("GhostNodes: Add '" + n + "' to ROOMS");
					return;
				}
				else{
					
					integer pos = llListFindList(rindex, (list)n);
					if( ~pos ){
						rindex = llDeleteSubList(rindex, pos, pos);
						found += n;
					}
					
				}
			}
			
		}
		
	)
	
	if( count(rindex) )
		llOwnerSay("No room markers:" + llList2CSV(rindex));

	
	// Next make a 2-stride list of each portal with the first value containing the two room indexes, and the second being the UUID of the portal
	links_each( nr, name,
		
		if( name == "PORTAL" ){
			list spl = llParseString2List(
			
				l2s(llGetLinkPrimitiveParams(nr, (list)PRIM_DESC), 0), 
				(list)":", 
				[]
			);
			portals +=  (list)(
				getRoomIndexByLabel(l2s(spl, 0)) | 
				(getRoomIndexByLabel(l2s(spl, 1)) << 8)
			) + nr;
			
		}
		
	)
	
	llOwnerSay("Cached "+(string)(count(portals)/2)+" room portals");
	
	
}

handleStateEntry(){
	
	raiseEvent(GhostPathingEvt$stateEntry, []);

}


float COOLDOWN;

#include "ObstacleScript/begin.lsl"


handleMethod( GhostPathingMethod$begin )
	begin();
end

handleMethod( GhostPathingMethod$getPath )

	// Ignore all requests 1 sec after finishing one
	if( llGetTime()-COOLDOWN < 1 )
		return;

	// SENDER_KEY, ss, cb, currentRoom, room
	string senderKey = argStr(0);	// Callback target
	string ss = argStr(1);		// Callback script
	int cb = argInt(2);			// Callback method
	string currentRoom = argStr(3);		// Unique Label
	string targRoom = argStr(4);		// Unique Label
	
	list path = findShortestPath(currentRoom, targRoom); 	// room indexes
	path = pathToPortals(path); 							// link numbers
	path = getLinkKeys(path);								// uuids
	
	runMethod(senderKey, ss, cb, path);
	COOLDOWN = llGetTime();
        

end


#include "ObstacleScript/end.lsl"


