#define USE_STATE_ENTRY
#include "ObstacleScript/index.lsl"



key ghost = "1af76701-c79b-57d8-c41c-8efe2ab1c8f9";

// Note that the same index can appear multiple times
#define RM_INDEX 0      // (Position in ROOMS list divided by ROOMS stride)
#define RM_POS 1
#define RM_ROT 2
#define RM_SCALE 3

#define RM_STRIDE NodesConst$rmStride
list ROOM_MARKERS = [];



list portals;      // 8bArray roomIndexes, uuid

#define getRoomIndexByName(name) llListFindList(llList2ListStrided(ROOMS, 0, -1, 2), (list)name)
#define getRoomNameByIndex(index) l2s(ROOMS, (index)*2)

list portal2names( integer bitArray8 ){
    
    return (list)
        getRoomNameByIndex(bitArray8&0xFF) + 
        getRoomNameByIndex((bitArray8>>8)&0xFF)
    ;
    
}

// Returns the absolute positions in the ROOM_MARKERS array where roomIndex is at
list getRoomMarkersByRoomIndex( integer roomIndex ){
    
    list out;
    list l = llList2ListStrided(ROOM_MARKERS, 0, -1, RM_STRIDE);
    integer i;
    for(; i < count(l); ++i ){
        
        if( l2i(l, i) == roomIndex )
            out += (i*RM_STRIDE);
        
    }
    
    return out;
    
}

// Could probably improve this with a proper pathfinding algorithm
// But I don't expect there to be a huge nr of rooms
// Returns an empty array if it's a dead end
list findShortestPath( string from, string to, list visited ){

    visited += from;
    
    list path;
    integer i;
    for(; i < count(portals); i += 2 ){
        
        list names = portal2names(l2i(portals, i));
        integer pos = llListFindList(names, (list)from);
        // This portal connects to from
        if( ~pos ){

            // Get the room this portal connects us to
            string other = l2s(names, !pos);
            
            // Found the end goal
            if( other == to )
                return (list)from + other;
            
            
            // Ignore if visited to prevent recursion
            if( llListFindList(visited, (list)other) == -1 ){
                
                list test = findShortestPath(other, to, visited);
                if( count(test) && (!count(path) || count(test) < count(path)) )
                    path = test;

            }
            
        }
        
    }
    
    // Dead end
    if( !count(path) )
        return path;
    
    // Returns the shortest path from this node
    return (list)from + path;
    
}

// Gets the UUID of a portal that contains a and b
key getPortalWithNodes( string a, string b ){
    
    integer i;
    for(; i < count(portals); i += 2 ){
        
        list spl = portal2names(l2i(portals, i));
        if(
            ~llListFindList(spl, (list)a) &&
            ~llListFindList(spl, (list)b)
        )return l2k(portals, i+1);
        
    }
    
    return "";
    
}

list pathToNodes( list nodes ){
    
    list out = [];
    while( count(nodes) > 1 ){
        
        key find = getPortalWithNodes(l2s(nodes, 0), l2s(nodes, 1));
        if( find ){
            
            nodes = llDeleteSubList(nodes, 0, 0);
            out += find;
            
        }
        // Fail
        else
            nodes = [];
        
    }
    return out;
    
}

// Checks if pos is within a bounding box
// i is the absolute position in the ROOM_MARKERS list pointing towards the first element of the stride
integer isPosInRoomMarker( vector pos, integer i ){
    
    rotation bbRot = l2r(ROOM_MARKERS, i+RM_ROT);
    vector bbPos = l2v(ROOM_MARKERS, i+RM_POS)+llGetRootPosition();
    vector bbSize = l2v(ROOM_MARKERS, i+RM_SCALE);       
    bbPos /= bbRot;
    pos /= bbRot;
    return (
        pos.x < bbPos.x+bbSize.x/2 && pos.x > bbPos.x-bbSize.x/2 &&
        pos.y < bbPos.y+bbSize.y/2 && pos.y > bbPos.y-bbSize.y/2 &&
        pos.z < bbPos.z+bbSize.z/2 && pos.z > bbPos.z-bbSize.z/2
    );
    
}

// Returns the room label
string getPosRoom( vector point ){
    
    integer i;
    for(; i < count(ROOM_MARKERS); i += RM_STRIDE ){
        
        if( isPosInRoomMarker( point, i) )
            return l2s(ROOMS, l2i(ROOM_MARKERS, i)*2);
        
    }
    
    return "";
    
}

onGroupsCached(){
	/*
	if( DEBUG_TARG )
		sendGhostToRoom(DEBUG_TARG);
    */
}

// Returns absolute indexes from the portals list of portals in the room marker
list findPortalsInRoom( integer roomIndex ){
    
    // Get absolute position of room bounding box in 
    list rmPos = getRoomMarkersByRoomIndex(roomIndex);
    list out;
    
    integer p;
    integer i;
    for(; i < count(rmPos); ++i ){
        
        integer markerAbsoluteIndex = l2i(rmPos, i);
        for(; p < count(portals); p += 2 ){
            
            vector pos = prPos(l2k(portals, p+1));
            if( isPosInRoomMarker(pos, markerAbsoluteIndex) )
                out += p;
            
        }
    }
    return out;
    
}

// Tries to find the closest room label based on proximity from pos
// Used to warp a ghost if they're out of bounds
string getClosestRoom( vector pos ){
    
    string closest = ""; float dist;
    integer i;
    for(; i < count(ROOM_MARKERS);  i += RM_STRIDE ){
        
        vector p = l2v(ROOM_MARKERS, i+RM_POS);
        float d = llVecDist(p, pos);
        if( d < dist || closest == "" ){
            
            dist = d;
            closest = l2s(ROOMS, l2i(ROOM_MARKERS, i));
            
        }
        
    }
    return closest;
    
}








#include "ObstacleScript/begin.lsl"

onSpawnerGetGroups( callback, spawns )
    
    list rindex = llList2ListStrided( ROOMS, 0, -1, 2 );
    
    if( callback == "init" ){

        integer i;
        for(; i < count(spawns); ++i ){
            
            string spawn = l2s(spawns, i);
            string label = j(spawn, 3 + 1);
            
            integer pos = llListFindList(rindex, (list)label);
            if( pos == -1 )
                qd("Warn" + label + "room index not found");
            ROOM_MARKERS += (list)
                pos +
                (vector)j(spawn, 1) +
                (rotation)j(spawn, 2) +
                (vector)j(spawn, 3 + 0)
            ;
            
        }
        
        //qd("Cached" + count(ROOM_MARKERS)/4 + "Markers");
        
        onGroupsCached();
            
    }

end



onStateEntry()

    // Get room markers
    Spawner$getGroups("init", "rooms");
    
    
    list unfoundRooms = llList2ListStrided(ROOMS, 0, -1, 2);
    // Sanity check our portals
    links_each( nr, name,
        
        if( name == "PORTAL" ){
            
            list spl = split(prDesc(llGetLinkKey(nr)), ":");
            integer i;
            for(; i < count(spl); ++i ){
                
                string n = l2s(spl, i);
                if( llListFindList(ROOMS, (list)n) == -1 )
                    qd("Error: Please add" + n + " to the ROOMS list");
                else{
                    
                    integer pos = llListFindList(unfoundRooms, (list)n);
                    if( ~pos )
                        unfoundRooms = llDeleteSubList(unfoundRooms, pos, pos);
                       
                }
            }
            
        }
        
    )
    
    if( count(unfoundRooms) )
        qd("Error: The following rooms require room markers:" + unfoundRooms);
    
    // Next make a 2-stride list of each portal with the first value containing the two room indexes, and the second being the UUID of the portal
    links_each( nr, name,
        
        if( name == "PORTAL" ){
            
            list spl = llParseString2List(
                l2s(llGetLinkPrimitiveParams(nr, (list)PRIM_DESC), 0), 
                (list)":", 
                []
            );
            portals +=  (list)(
                getRoomIndexByName(l2s(spl, 0)) | 
                (getRoomIndexByName(l2s(spl, 1)) << 8)
            ) + llGetLinkKey(nr);
            
        }
        
    )
    

end


handleMethod( NodesMethod$getRooms )
	
	integer i;
	for(; i < count(ROOM_MARKERS); i += RM_STRIDE ){
	
		list slice = llList2List(ROOM_MARKERS, i, i+RM_STRIDE-1);
		slice = llListReplaceList(slice, (list)(l2v(ROOM_MARKERS, i+RM_POS)+llGetRootPosition()), RM_POS, RM_POS);
		runMethod(SENDER_KEY, argStr(0), argInt(1), i + slice);
		
	}
	
end

handleMethod( NodesMethod$getPath )

	string ss = argStr(0);
	int cb = argInt(1);
	vector startPos = argVec(2);
	string room = argStr(3);
	if( (vector)room != ZERO_VECTOR )
		room = getPosRoom((vector)room);
		
	// Get the index of the room the ghost is in
    string currentRoom = getPosRoom(startPos);
    // Already there!
    if( currentRoom == room )
        return;
    
    // Out of bounds, we'll have to improvise
    if( currentRoom == "" )
        currentRoom = getClosestRoom(startPos);

    integer ri = getRoomIndexByName(currentRoom);
    // Start by trying to find a node in the current room
    if( ~ri ){

        list path = findShortestPath(currentRoom, room, []);
        qd("Trying to path from "+currentRoom+"to"+room);
        list nodes = pathToNodes(path);
        qd(path);
        
        runMethod(SENDER_KEY, ss, cb, nodes);
        
    }
    

end



#include "ObstacleScript/end.lsl"
