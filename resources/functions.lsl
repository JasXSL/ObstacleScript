#ifndef __Functions
#define __Functions

#include "../headers/Rlv.lsh"
#include "../headers/SupportCube.lsh"


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




#endif
