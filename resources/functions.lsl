#ifndef __Functions
#define __Functions

#include "../headers/Rlv.lsh"
#include "../headers/SupportCube.lsh"

// Actually triggers in a cube
_tsr( key sound, float vol, float radius ){
	
	vector pos = llGetPos();
	vector v = <radius, radius, radius>;
	llTriggerSoundLimited(sound, vol, pos+v, pos-v);

}
#define triggerSoundRadius( sound, vol, radius ) _tsr(sound, vol, radius)


// LSD functions
// Note: Do not start your idx with a unicode value below 32
// Warning: Indexed table names should be exactly 1 character to prevent collissions with other tables.
// Warning: Non indexed table names should have at least 3 characters.
// To save memory, there are no guardrails preventing you from fucking that up.
#define idbSet(table, field, val) llLinksetDataWrite(table+(str)(field), (str)(val))
#define idbGet(table, field) llLinksetDataRead(table+(str)(field))

#define idbGetByIndex(table, index) llLinksetDataRead(table+llChar(index+32))
#define idbSetByIndex(table, index, val) llLinksetDataWrite(table+llChar(index+32), (val))

#define idbSetIndex(table, val) llLinksetDataWrite(table, (str)(val))
#define idbResetIndex(table) llLinksetDataWrite(table, "0")
#define idbGetIndex(table) (int)llLinksetDataRead(table)
// Inserts and maintains an index
integer _dbi( string table, string data ){

	integer nr = idbGetIndex(table);
	idbSet(table, llChar(nr+32), data);
	idbSetIndex(table, nr+1);
	return nr;

}
#define idbInsert(table, data) _dbi((table), (string)(data))

// Get all values from a table
#define idbValues(table, full) _ia(table, full)
list _ia( string t, integer f ){
	integer max = idbGetIndex(t);
	integer i; list out;
	for(; i < max; ++i ){
		str data = idbGetByIndex(t, i);
		if( data != "" || f )
			out += data;
	}
	return out;
}

// Drop an indexed table. Relatively memory intensive.
#define idbDropInline(table) \
	/* Delete the index table */ \
	llLinksetDataDelete(table); \
	list found; integer i; \
	/* Delete any data that matches table+1char */  \
	while( (found = llLinksetDataFindKeys("^"+table+".{1}$", 0, 100)) != [] ){ \
		for( i = 0; i < count(found); ++i ) \
			llLinksetDataDelete(l2s(found, i)); \
	}


_dbd( string table ){
	idbDropInline()
}
#define idbDrop(table) _dbd(table)

#define idbForeach(table, idx, row) \
	integer idx; \
	for(; idx < idbGetIndex(table); ++idx ){ \
		string row = idbGetByIndex(table, idx);




// Lets you round floats, vectors, and rotations
#define allRound(input, places) _allRound((list)(input), places)
string _allRound( list input, integer places ){
    
    list vals = (list)llList2Float(input, 0); 
    integer type = llGetListEntryType(input, 0);
    if( type == TYPE_VECTOR ){
        vector v = llList2Vector(input, 0);
        vals = (list)v.x + v.y + v.z;
    }
    else if( type == TYPE_ROTATION  ){
        rotation v = llList2Rot(input, 0);
        vals = (list)v.x + v.y + v.z + v.s;
    }
    
    float exponent = llPow(10,places);
    integer i;
    for( ; i<llGetListLength(vals); ++i ){
        
        
        string v = (string)(
            (float)llRound(llList2Float(vals, i)*exponent)
            /exponent
        );
        while( llGetSubString(v, -1, -1) == "0" )
            v = llDeleteSubString(v, -1, -1);
        
        while( llGetSubString(v, 0, 0) == "0" )
            v = llDeleteSubString(v, 0, 0);
            
        if( llGetSubString(v, -1, -1) == "." )
            v = llDeleteSubString(v, -1, -1);
        
        if( v == "" )
            v = "0";
        
        vals = llListReplaceList(vals, (list)v, i, i);
        
    }
    
    if( llGetListLength(vals) > 1 )
        return "<"+llDumpList2String(vals, ",")+">";
    return llList2String(vals, 0);
}


// Tries to generate a KFM from JSON
list _kfmConv( list input ){

	integer i;
	for(; i < count(input); ++i ){
		
		if( llGetSubString(l2s(input, i), 0, 0) == "<" ){
			
			list spl = split(l2s(input, i), ",");
			if( count(spl) == 4 ){
			
				rotation Q = (rotation)l2s(input, i);
				float MagQ = llSqrt(Q.x*Q.x + Q.y*Q.y +Q.z*Q.z + Q.s*Q.s);
				input = llListReplaceList(input, (list)<Q.x/MagQ, Q.y/MagQ, Q.z/MagQ, Q.s/MagQ>, i, i);
				
			}
			else
				input = llListReplaceList(input, (list)[(vector)l2s(input, i)], i, i);
			
		}
		else
			input = llListReplaceList(input, (list)l2f(input, i), i, i);
		
	}
	
	return input;
	
}


// Telports player to a position. A ray is cast from position to the ground and tries to place the player there
_w2s( key player, vector checkpoint, rotation r, integer unsit ){
    
    list ray = llCastRay(checkpoint, checkpoint-<0,0,25>, RC_DEFAULT);
    vector rp = l2v(ray, 1);
    vector ascale = llGetAgentSize(player);
    checkpoint.z = rp.z+ascale.z/2;

    if( unsit ){
        Rlv$teleportPlayer(
            player, 
            checkpoint,
            r
        );
        return;
    }
    Rlv$teleportPlayerNoUnsit(
        player, 
        checkpoint,
        r
    );
    
}
#define warpPlayerToSurface( player, pos, rot, allowUnsit ) \
	_w2s( player, pos, rot, allowUnsit )

// Returns TRUE if player is looking at targ (positive X)
int _pla( key player, key targ, float angle ){
	
	vector temp = (prPos(targ)-prPos(player))/prRot(player); 
	return llFabs(llAtan2(temp.y,temp.x)) < angle;

}
#define agentLookingAt( player, targ ) \
	_pla(player, targ, PI_BY_TWO)

#define agentLookingAtRadius( player, targ, radius ) \
	_pla(player, targ, radius)

#endif
