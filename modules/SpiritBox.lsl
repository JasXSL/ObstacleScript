#include "ObstacleScript/resources/SubHelpers/GhostHelper.lsl"
#define USE_STATE_ENTRY
#define USE_PLAYERS
#define USE_TIMER
#define USE_LISTEN
#include "ObstacleScript/index.lsl"
string ID;


#define SCALEX 0.12500
#define SCALEY 0.50000
#define STARTX -0.43751
#define STARTY 0.25001
#define FACE 4
#define SCREEN_FACE 3

integer SUCCESS;
integer P_SPIRITBOX;
integer BFL = 0x4;
#define BFL_ON 0x1
#define BFL_HUNTING 0x2
#define BFL_DROPPED 0x4

#define isDropped() (BFL&BFL_DROPPED && !llGetAttached())

setSprite( integer sprite ){
    
    integer y = sprite/8;
    integer x = sprite%8;
    
    llSetLinkPrimitiveParamsFast(P_SPIRITBOX, (list)
        PRIM_TEXTURE + 
        FACE + 
        "1e1646ca-e9fb-b30d-5c19-6a51207968a0" +
        <SCALEX, SCALEY, 0> +
        <
            STARTX + x*1.0/8,
            STARTY - y*1.0/2,
            0
        > +
        0 +
        PRIM_COLOR + FACE + ZERO_VECTOR + 1
    );
    
}

respond(){
    
    list responses = (list) // 4 bit arrays, big endian
        0x4+    // Lewd
        0x56+   // Nice behind
        0x5C+   // Nice beans
        0x5F+   // Nice cock
        0xD+    // Youuuu
        0x9+    // owo
        0xAB+   // uwan sumfuk
        0xAC+   // uwan beans
        0x6E+   // Behind you
        0x4E   // Lewd you
    ;
    
    integer response = l2i(responses, llFloor(llFrand(count(responses))));
	
	if( !SUCCESS )
		response = 0x78;   // No signal
    
    SWEEP = [];
    
    integer i;
    for(; i < 8; ++i ){
        
        integer block = (response>>(i*4))&0xF;
        if( block )
            SWEEP = block + SWEEP;
        
    }
	
	SWEEP += -1;
    
	SWEEPING = 2;
    setSprite(l2i(SWEEP, 0));
    SWEEP = llDeleteSubList(SWEEP, 0, 0);
    setInterval("S", .75);
    
}

integer checkMessage( string message ){
    
    message = llToLower(message);
    
    list starters = (list)
        "are" +
        "what's" +
        "do" +
        "can" +
        "what" +
        "how" +
        "where" +
        "would" +
        "should" +
        "could" +
        "will" +
        "you" +
        "why"
    ;
    
    integer isDirected;
    
    integer i;
    for(; i < count(starters) && !isDirected; ++i ){
        
        string check = l2s(starters, i)+" ";
        string sub = llGetSubString(message, 0, llStringLength(check)-1);
        if( sub == check )
            isDirected = TRUE;
        
    }
    
    list words = split(message, (list)" " + "?");
    list you = (list)"u" + "you" + "your" + "yours" + "ur";
    integer isYou;
    for( i = 0; i < count(you) && !isYou; ++i ){
        
        if( ~llListFindList(words, llList2List(you, i, i)) )
            isYou = TRUE;
            
    }
    
    
    integer isQuestion = llGetSubString(message, -1, -1) == "?";
    return isYou && isQuestion && isDirected;
    
}

integer SWEEPING;
list SWEEP;
sweep(){
    
    SWEEP = (list)0 + 1 + 2 + 3 + 0 + 1 + 2 + 3;
    setInterval("S", .2);
    SWEEPING = 1;
    llLoopSound("30b60b7e-952b-f083-86d0-21280a6cc8ca", .25);
    
}


toggleOn( integer on ){
    
	// Todo: Update visual
	
    if( on ){
        
        BFL = BFL|BFL_ON;
        llStopSound();
        llLoopSound("ca52dde3-1c21-d380-442b-aa4b245e7522", 0.0001);
        
    }
    else{
        
        BFL = BFL&~BFL_ON;
        llAdjustSoundVolume(0);
        
    }
    
	llSetLinkPrimitiveParamsFast(P_SPIRITBOX, (list)PRIM_FULLBRIGHT + SCREEN_FACE + on);
           
}

onDataChanged( integer data ){
    
    toggleOn(data);
    
}




#include "ObstacleScript/begin.lsl"

handleMethod( SpiritBoxMethod$start )
	
	SUCCESS = argInt(0);
	sweep();
	
end


onStateEntry()
       
    forLink( nr, name )
    
        if( name == "SPIRITBOX" )
            P_SPIRITBOX = nr;
    
    end
    
	llSetAlpha(0, FACE);
    llListen(0, "", "", "");
    toggleOn(FALSE);
	PLAYERS = [(str)llGetOwner()];
            
end

onToolSetActiveTool( tool, data )

    if( tool != ToolsetConst$types$ghost$spiritbox )
        toggleOn(FALSE);
    else
        onDataChanged((int)data);

end

onGhostToolHunt( hunting, ghost )
    
    BFL = BFL&~BFL_HUNTING;
    if( hunting )
        BFL = BFL|BFL_HUNTING;

end

// Raised only if rezzed and not picked up. This is raised when placing the asset under the level. Can be used to hide it etc.
onGhostToolPickedUp()

    if( llGetInventoryType("ToolSet") != INVENTORY_NONE )
        return;
        
    toggleOn(FALSE);
    
end

// Raised after positioning this on the floor (if the asset is NOT attached)
onGhostToolDropped( data )

    if( llGetInventoryType("ToolSet") != INVENTORY_NONE )
        return;
    
    onDataChanged((int)data);
    
end

onListen( ch, msg )

	if( llListFindList(PLAYERS, [(str)SENDER_KEY]) == -1 )
		return;
		
	if( SWEEPING || ~BFL&BFL_ON || BFL&BFL_HUNTING )
		return;
		
	if( checkMessage(msg) )
        Level$raiseEvent( LevelCustomType$SPIRITBOX, LevelCustomEvt$SPIRITBOX$trigger, [] );

end

handleTimer( "S" )

	if( !count(SWEEP) ){
			
		unsetTimer("S");
		llStopSound();
		if( SWEEPING == 1 ){
			respond();
			
		}
		else
			SWEEPING = 0;
			
		return;
		
	}

	integer sprite = l2i(SWEEP, 0);
	SWEEP = llDeleteSubList(SWEEP, 0, 0);

	if( sprite == -1 )
		llSetLinkAlpha(P_SPIRITBOX, 0, FACE);
	else
		setSprite( sprite );
	
	
	
	
end

#include "ObstacleScript/end.lsl"





