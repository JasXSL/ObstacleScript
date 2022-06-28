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

#define hideResponse() llSetLinkAlpha(P_SPIRITBOX, 0, FACE)

#define isDropped() (BFL&BFL_DROPPED && !llGetAttached())

setSprite( integer sprite ){
    
    integer y = sprite/8;
    integer x = sprite%8;
    
    llSetLinkPrimitiveParamsFast(P_SPIRITBOX, (list)
        PRIM_TEXTURE + 
        FACE + 
        "43c422ac-4a73-2de5-0b7b-fa41fc457559" +
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

updateSound(){
	
	llStopSound();
	if( ~BFL&BFL_ON )
		return;
		
	if( SWEEP ){
		llLoopSound("30b60b7e-952b-f083-86d0-21280a6cc8ca", .25);
	}
	else
		llLoopSound("f9abe756-b788-b2b4-fd3d-7c373f83a464", 0.1);
}

respond(){
    
    list responses = (list) // 4 bit arrays, big endian
        0x56 + "beb83e3f-a9c5-7d5a-e6c0-269192f76bbb" +   // Nice behind
        0x5C + "c6932327-af78-32d0-a12b-5980e650a0da" +   // Nice beans
        0x5F + "7d99f539-0b47-fb55-5f1b-877c4eda0ac9" +   // Nice cock
        0xD + "8a39b219-d07e-53b7-32b8-84e00018b7a4" +    // Youuuu
        0x9 + "dc2bf67d-ca99-2114-1e95-550bed69e518" +    // owo
        0xA + "c263e79a-2dd4-4685-61e2-d2bb5dc8e81b" +   // E
        0x6E + "fd4f046d-f6be-fb62-dc02-1302b1c0ec12" +   // Behind you
		0x6 + "9014f0b6-a69e-f78d-24ac-9debcc01a2bb" +		// Behind
		0x4B + "5378dd3c-e414-7425-6700-eab723bcdc12" + 	// Blow me
		0x7E + "f70f8448-2cd3-c5b7-8df6-3834dd31f7ec" 		// No you
    ;
    
	integer res = llFloor(llFrand(count(responses)/2))*2;
    integer response = l2i(responses, res);
	key voice = l2k(responses, res+1);
	
	SWEEP = [];
	 
	if( !SUCCESS ){
		hideResponse();
		SWEEPING = 0;
		return;
	}
    else
		llTriggerSound(voice, 0.3);
    
   
    
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
    updateSound();
    
}


toggleOn( integer on ){
    
    if( on ){
        BFL = BFL|BFL_ON;
    }
    else{
        BFL = BFL&~BFL_ON;		
    }
	
	updateSound();
	llSetLinkPrimitiveParamsFast(P_SPIRITBOX, (list)PRIM_FULLBRIGHT + SCREEN_FACE + on + PRIM_GLOW + SCREEN_FACE + (0.1*on));
           
}

onDataChanged( integer data ){
    
    toggleOn(data);
    
}

int canSweep(){
	return !SWEEPING && BFL&BFL_ON && ~BFL&BFL_HUNTING;
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
    
	llPreloadSound("f9abe756-b788-b2b4-fd3d-7c373f83a464");
	llPreloadSound("30b60b7e-952b-f083-86d0-21280a6cc8ca");
	
	llSetAlpha(0, FACE);
    llListen(0, "", "", "");
    toggleOn(FALSE);
	PLAYERS = [(str)llGetOwner()];
    Portal$scriptOnline();
	
	//Level$forceRefreshPortal();
	
	if( llGetInventoryType("ToolSet") != INVENTORY_NONE ){
		setInterval("VO", 1);
	}
			
end

// Trigger through speaking loudly
handleTimer( "VO" )
	
	if( !canSweep() )
		return;
		
	// Memory saving hex conversion
	list anims = (list)
		0xa71890f1 +
		0x593e9a3d +
		0x55fe6788 +
		0xc1802201 +
		0x69d5a8ed
	;
	list pl = llGetAnimationList(llGetOwner());
	int i;
	for(; i < count(pl); ++i ){
	
		integer n = (int)("0x"+llGetSubString(l2s(pl, i), 0, 7));
		if( ~llListFindList(anims, (list)n) ){
		
			Level$raiseEvent( LevelCustomType$SPIRITBOX, LevelCustomEvt$SPIRITBOX$trigger, [] );
			return;
			
		}
		
	}
	

end

onToolSetActiveTool( tool, data )

    if( tool != ToolsetConst$types$ghost$spiritbox ){
        toggleOn(FALSE);
	}
    else{
		if( (int)data )
			llSleep(.1);	// Fixes audio race conditions with owometer
        onDataChanged((int)data);
	}
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
	

	// Only owner can use an attached one
	if( llGetAttached() ){
		if( SENDER_KEY != llGetOwner() )
			return;
	}
	// Any player can use a dropped on
	else{
		if( llListFindList(PLAYERS, [(str)SENDER_KEY]) == -1 )
			return;
			
		if( llVecDist(llGetPos(), prPos(SENDER_KEY)) > 3 )
			return;
			
	}
	if( !canSweep() )
		return;
				
	if( checkMessage(msg) ){
        Level$raiseEvent( LevelCustomType$SPIRITBOX, LevelCustomEvt$SPIRITBOX$trigger, [] );
	}
	
end

handleTimer( "S" )

	if( !count(SWEEP) ){
			
		updateSound();
		
		unsetTimer("S");
		if( SWEEPING == 1 )
			respond();
		else
			SWEEPING = 0;
		
		return;
		
	}

	integer sprite = l2i(SWEEP, 0);
	SWEEP = llDeleteSubList(SWEEP, 0, 0);

	if( sprite == -1 )
		hideResponse();
	else
		setSprite( sprite );
	
	
	
	
end

#include "ObstacleScript/end.lsl"





