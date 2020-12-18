// Implements parts of libJasPre

// GENERAL PSEUDONYMS //
#define elseif else if
#define elif else if

#define true TRUE
#define false FALSE

#define int integer
#define str string
#define bool integer

#define count(input) (input != [])	// Sorcery!
#define Infinity 340282356779733642748073463979561713664.00000000
#define NaN ((float)"nan")
#define ONE_VECTOR <1.0,1.0,1.0>
#define MAXINT 0x7FFFFFFF
#define floor(input) ((integer)(input))

#define split(input, separator) llParseStringKeepNulls(input, (list)(separator), [])
#define join(input, separator) llDumpList2String(input, (str)(separator))

#define uuidChan( id ) ((int)("0x"+(string)id))

#define mkarr(input) llList2Json(JSON_ARRAY, (list)input)

#define trim(input) llStringTrim(input, STRING_TRIM)
	
// Making it more readable for newbs
#define AND &&
#define OR ||
#define IS ==



// Debugging
// Note, using the + operator within os$log will add that as another message, use parentheses if you want to add things within this
#define os$log( message ) \
	llOwnerSay( "["+llGetSubString(l2s(split(llGetTimestamp(), (list)"T"), 1), 6, -5)+" "+__SHORTFILE__+" @ "+(str)__LINE__+"] "+join((list)message, " :: ") )

// Can use XOBJ syntax
#define qd(message) \
	os$log(message)

#define randElem(input) \
	llList2String((list)input, llFloor(llFrand(count((list)input))))

#define memLim(multi) llSetMemoryLimit(llCeil((float)llGetUsedMemory()*multi))

#define l2s(l,n) llList2String(l, n)
#define l2i(l,n) llList2Integer(l, n)
#define l2k(l,n) llList2Key(l, n)
#define l2v(l,n) llList2Vector(l, n)
#define l2r(l,n) llList2Rot(l, n)
#define l2f(l,n) llList2Float(l, n)

// These will auto typecast strings to complex types
#define l2vs(l, n) ((vector)llList2String(l, n))
#define l2rs(l, n) ((rotation)llList2String(l, n))


#define isset(input) ((str)input!="" && (str)input!=JSON_INVALID)
#define norm2rot(normal, axis) llAxes2Rot(llVecNorm(normal % axis) % normal, llVecNorm(normal % axis), normal)

#define RC_DEFAULT (list)RC_REJECT_TYPES + (RC_REJECT_AGENTS|RC_REJECT_PHYSICAL)

// Vectors
#define int2vec(input) <((input>>21)&255), ((input>>13)&255), (input&8191)>
#define vecFloor(input) <floor(input.x), floor(input.y), floor(input.z)>
#define vec2int(input) ((integer)input.x<<21)|((integer)input.y<<13)|(integer)input.z
// Reflects a direction based on a surface normal. Normal must be normalized
#define reflect(dir, norm) (llVecNorm(dir) - norm*(2*(llVecNorm(dir)*norm)))*llVecMag(dir)


// Lookats
#define xLookAt(pos) llRotLookAt(llRotBetween(<1,0,0>, llVecNorm(pos-llGetPos())), 1, 1)
#define xLookAtLinked(link, pos) llSetLinkPrimitiveParamsFast(link, (list)PRIM_ROTATION + llRotBetween(<1,0,0>, llVecNorm(pos-llGetPos())))


// Conditions
#define idOwnerCheck \
	if( llGetOwnerKey(id) != llGetOwner() ) \
		return;
		


// PRIM FUNCTIONS //
// Gets prim info by a uuid
#define prPos(prim) llList2Vector(llGetObjectDetails(prim, [OBJECT_POS]),0)
#define prRot(prim) llList2Rot(llGetObjectDetails(prim, [OBJECT_ROT]),0)
#define prDesc(prim) (string)llGetObjectDetails(prim, [OBJECT_DESC])
#define prLinkedToMe(prim) (llList2Key(llGetObjectDetails(prim, [OBJECT_ROOT]),0) == llGetKey())
#define prRoot(prim) llList2Key(llGetObjectDetails(prim, [OBJECT_ROOT]),0)
#define prAttachPoint(prim) llList2Integer(llGetObjectDetails(prim, [OBJECT_ATTACHED_POINT]), 0)
#define prSpawner(prim) llList2Key(llGetObjectDetails(prim, [OBJECT_REZZER_KEY]), 0)
#define prPhantom(prim) llList2Integer(llGetObjectDetails(prim, [OBJECT_PHANTOM]), 0)
#define mySpawner() prSpawner(llGetKey())

// Check if prim is in front of me
#define prAngleOn(object, var, rotOffset) vector temp = (prPos(object)-llGetRootPosition())/llGetRootRotation()*rotOffset; var = llAtan2(temp.y,temp.x)
#define prAngle(object, var, rotOffset) float var; {vector temp = (prPos(object)-llGetRootPosition())/llGetRootRotation()*rotOffset; var = llAtan2(temp.y,temp.x);}
#define prAngX(object, var) prAngle(object, var, ZERO_ROTATION)
#define prAngZ(object, var) prAngle(object, var, llEuler2Rot(<0,PI_BY_TWO,0>))
// Checks if I am in front of prim
#define myAng(object, var, rotOffset) float var; {vector temp = (llGetRootPosition()-prPos(object))/prRot(object)*rotOffset; var = llAtan2(temp.y,temp.x);}
#define myAngX(object, var) myAng(object, var, ZERO_ROTATION)
#define myAngZ(object, var) myAng(object, var, llEuler2Rot(<0,PI_BY_TWO,0>))

#define j(input, val) \
	llJsonGetValue(input, (list)val)

// Conditions
// Checks if an id is owner
#define condIsOwner(id) \
	if( llGetOwnerKey(id) == llGetOwner() ){


// Lists
// Iterate  an lsl list, deleting each value after it's been run
	#define list_shift_each(input, val, fnAction) while(llGetListLength(input)){string val = llList2String(input,0); input = llDeleteSubList(input,0,0); fnAction}
	// Ex: list_shift_each(myList, v, {llSay(0, v+" has been iterated over and is now removed");})

// Iterate over links with link nr and link name
	#define links_each(linknum, linkname, fnAction)  {integer linknum; for(linknum=llGetNumberOfPrims()>1; linknum<=llGetNumberOfPrims(); linknum++){ string linkname=llGetLinkName(linknum); fnAction}}
	// Ex: links_each(num, name, {llSay(0, "Link #"+(string)num+" is called: "+name);});
	
	
