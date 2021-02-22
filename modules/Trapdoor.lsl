#define USE_STATE_ENTRY
#define USE_TIMER
#define USE_PLAYERS
#define USE_COLLISION_START
#define USE_COLLISION_END 
#define USE_LISTEN
#include "ObstacleScript/index.lsl"

list KFM;
int FLAGS = 1;
str ID;
    
float PREDELAY = 0.5;
float HOLDTIME = 2;
float CD = 2;

integer BFL;
#define BFL_TRIG 0x1

rotation startRot;
vector startPos;

list COLLIDERS;

// After predelay
stageA(){
	
	 if( FLAGS & TrapdoorConst$FLAG_BLINK )
        llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, (list)
            PRIM_FULLBRIGHT + ALL_SIDES + FALSE
        );
    
	integer both = TrapdoorConst$FLAG_ROT|TrapdoorConst$FLAG_POS;
	integer stride = 2+((FLAGS & both) == both);
	
    float timeout;
    integer i;
    for(; i < count(KFM); i += stride )
        timeout += l2f(KFM, i+stride-1);
        
	
     
	list data;
	
	 
	if( (FLAGS & both) != both ){
	
		data += KFM_DATA;
		if( FLAGS& TrapdoorConst$FLAG_ROT )
			data += KFM_ROTATION;
		else
			data += KFM_TRANSLATION;
		
	}
    llSetKeyframedMotion(KFM, data);
	
	float b = timeout+HOLDTIME;
	if( b > 0 )
		setTimeout("B", b);
	else
		stageB();

}

// Reset
stageB(){
	
	// Reset
    llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
    llSleep(.2);
    llSetRegionPos(startPos);
    llSetRot(startRot);
    
	if( CD > 0 )
		setTimeout("C", CD);
	else
		stageC();

}

stageC(){
	
	BFL = BFL&~BFL_TRIG;
	
	Level$raiseEvent( 
		LevelCustomType$TRAPDOOR, 
		LevelCustomEvt$TRAPDOOR$reset,
		ID
	);
	
	if( FLAGS & TrapdoorConst$FLAG_RETRIGGER && count(COLLIDERS) )
		trigger( TRUE );

}


trigger( bool evt ){

	if( evt ){
	
		Level$raiseEvent( 
			LevelCustomType$TRAPDOOR, 
			LevelCustomEvt$TRAPDOOR$trigger,
			ID + llDetectedKey(0)
		);
	
	}

	BFL = BFL|BFL_TRIG;
    if( FLAGS&TrapdoorConst$FLAG_BLINK )
        llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, (list)
            PRIM_FULLBRIGHT + ALL_SIDES + TRUE
        );
    
    float pre = PREDELAY;
    if( pre < 0.1 )
		stageA();
    else 
		setTimeout("A", pre);
	
}







#include "ObstacleScript/begin.lsl"

onPortalLoadComplete( desc )

    list data = llJson2List(desc);  
	
	ID = l2s(data, TrapdoorDesc$id);
	
	
	list kfm = llJson2List(l2s(data, TrapdoorDesc$kfm));
	if( count(kfm) > TrapdoorDesc$kfm )
		KFM = _kfmConv(kfm);
	
	int flags = l2i(data, TrapdoorDesc$flags);
	float pre = l2f(data, TrapdoorDesc$predelay);
    float hold = l2f(data, TrapdoorDesc$holdtime);
	float cd = l2f(data, TrapdoorDesc$cooldown);
	
    if( flags != -1 )
		FLAGS = flags;
		
	if( (int)pre != -1 )
		PREDELAY = pre;
	if( (int)hold != -1 )
		HOLDTIME = hold;
	if( (int)CD != -1 )
		CD = cd;

	integer both = TrapdoorConst$FLAG_ROT|TrapdoorConst$FLAG_POS;
	if( !(FLAGS&both) )
		FLAGS = FLAGS | both;
	
    startRot = llGetRot();
    startPos = llGetPos();
    
end

onStateEntry()
    
    KFM = (list)ZERO_VECTOR + llEuler2Rot(<0,PI_BY_TWO,0>) + 0.12;
    startRot = llGetRot();
    startPos = llGetPos();
	
	Portal$scriptOnline();
	
	llListen(TrapdoorConst$CHAN, "", "", "");
    
end




onCollisionStart( total )
	
	integer i;
	for(; i < total; ++i ){
	
		string k = llDetectedKey(i);
	
		if( ~llListFindList(PLAYERS, (list)k) && llListFindList(COLLIDERS, (list)k) == -1 )
			COLLIDERS += k;
			
	}
	
	if( COLLIDERS == [] || BFL&BFL_TRIG )
		return;
		
	
    trigger( true );

end

onCollisionEnd( total )

	integer i;
	for(; i < total; ++i ){
	
		string k = llDetectedKey(i);
		integer pos = llListFindList(COLLIDERS, (list)k);
		if( ~pos )
			COLLIDERS = llDeleteSubList(COLLIDERS, pos, pos);
			
	}

end



onListen( chan, msg )
	
	if( llGetOwnerKey(SENDER_KEY) != llGetOwner() )
		return;
		
	list data = llJson2List(msg);
	
	if( l2s(data, 0) != "*" && l2s(data, 0) != ID )
		return;
	
	integer task = l2i(data, 1);
	data = llDeleteSubList(data, 0, 1);
	
	if( task == TrapdoorTask$trigger ){
	
		if( BFL&BFL_TRIG )
			return;
			
		trigger( FALSE );
		
	}

	
end








// Trigger
handleTimer( "A" )

   stageA();
    
end

handleTimer( "B" )

    stageB();

end

handleTimer( "C" )
	
	stageC();

end

#include "ObstacleScript/end.lsl"



