
#define onInteract \
	if( type == "Interact::suc" ){




// Syntax ex: D$name$id$type$args
#define makeInteractive() \
    llSetObjectDesc("I$INTERACTIVE$UNKNOWN$NA$0");

#define modifyDesc( index, val ) \
    llSetObjectDesc(\
        llDumpList2String( \
            llListReplaceList(\
                explode("$",llGetObjectDesc()), \
                (list)(val), \
                index, index \
            ), \
            "$" \
        ) \
    )

#define interactionLabel( name ) \
    modifyDesc(1, name);

#define interactionType( type ) \
    modifyDesc(3, type);
    
#define interactionId( id ) \
    modifyDesc(2, id);
	
	
#define TYPE_DOOR "D"



