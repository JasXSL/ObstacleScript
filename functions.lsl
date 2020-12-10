#ifndef __Functions
#define __Functions

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






#endif
