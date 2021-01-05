#define USE_ON_REZ
#define USE_TIMER
#define USE_STATE_ENTRY
#include "ObstacleScript/index.lsl"

float CLIMBSPEED = .65;  // M/S

integer RLVFLAGS;

integer BFL;
#define BFL_MOVING 1
#define BFL_DISMOUNTING 2
#define BF_CLIMB_INI 8
#define BFL_DIR_UP 0x10
#define BFL_CLIMBING 0x20
// Prevents messages to SC more than every 0.4 sec
#define BFL_LAST_UPDATE 0x40
#define BFL_GRACE_PERIOD 0x80        // Grace period for dismount

integer KEY_FILTER;

// Used in timer_move
integer BFL_CACHE;

// Frame ticker
#define TIMER_MOVE "a"
// Dismount complete
#define TIMER_DISMOUNTING "b"
// Mount complete
#define TIMER_INI "c"
// Can send a new translate request
#define TIMER_CD "d"
// Blocks dismount through E
#define TIMER_GRACE "e"

key CUBE;
key ladder;
vector ladder_root_pos;
rotation ladder_root_rot;
list nodes;

// Cache animation from desc
string anim_active = "";
string anim_active_down = "";
string anim_passive = "";
string anim_dismount_top = "";
string anim_dismount_bottom = "";

string anim_active_cur;
string onStart;
string onEnd;

integer onNode;
rotation rot;
float perc;



#define setCubePos(pos) \
    llRegionSayTo( \
        CUBE,  \
        SupportCubeCfg$listenOverride,  \
        llList2CSV((list) \
            SupportCubeOverride$tSetPosAndRot +  \
            pos +  \
            (rot*ladder_root_rot) \
        ) \
    )

translateCubePos( vector pos ){
    
    vector p = pos-prPos(CUBE);
    rotation rot = rot*ladder_root_rot/prRot(CUBE);
    
	llRegionSayTo(
        CUBE, 
        SupportCubeCfg$listenOverride, 
        llList2CSV((list)
            SupportCubeOverride$tKFM + 
            p + 
            rot + 
            0.5
        )
    );

}

dismount(integer atoffset){

    if( BFL&BFL_DISMOUNTING )
		return;
		
    BFL = BFL|BFL_DISMOUNTING;
    unsetTimer(TIMER_MOVE);
    BFL = BFL&~BF_CLIMB_INI;
    BFL = BFL&~BFL_CLIMBING;
    anim_active_cur = "";
    
	
    
    if(anim_active != "")
        AnimHandler$stop(LINK_SET, anim_active);
    
    if(anim_active_down != ""){
        AnimHandler$stop(LINK_SET, anim_active_down);
    }
    
    string anm = anim_dismount_bottom;
    if(atoffset){
        vector gpos = llGetRootPosition();
        vector offset = offset2global(llList2Vector(nodes,0));
        
        if(~BFL&BFL_DIR_UP){
            offset = offset2global(llList2Vector(nodes,-1));
            anm = anim_dismount_top;
        }
        if( isset(anm) )
            AnimHandler$start(LINK_SET, anm);
        
        setCubePos(offset);
    }
    
    float to = .1;
    if( isset(anm) )
        to = 1;
        
    if( anim_passive != "" )
        AnimHandler$stop(LINK_SET, anim_passive);
    
    
    setTimeout(TIMER_DISMOUNTING, to);
    raiseEvent(ClimbEvt$end, mkarr(([(string)ladder, onEnd])));
	Level$raiseEvent( LevelCustomType$STAIR, LevelCustomEvt$STAIR$seated, ladder + 0 );
	
}

mount(){
    
    BFL_CACHE = 0;
    findNearestNode();
    // Position cube at node and start
    vector p = offset2global(llList2Vector(nodes, onNode));

    
    if( llKey2Name(CUBE) == "" ){
        
        Rlv$cubeTask(LINK_THIS,
            SupportCubeBuildTask(SupportCube$tSetPos, p) +
            SupportCubeBuildTask(SupportCube$tSetRot, (rot*ladder_root_rot))
        );
        
    }
    
    setCubePos(p);
    
    
    Rlv$cubeTask(
        LINK_THIS,
        SupportCubeBuildTask(SupportCube$tForceSit, [])
    );

    // Wait a little while to start ticking
    setTimeout(TIMER_MOVE, 1);
    
    if( isset(anim_passive) )
        AnimHandler$start(LINK_SET, anim_passive);
    
    // Mounting complete
    setTimeout(TIMER_INI, 5);
    BFL = BFL|BF_CLIMB_INI;
    BFL = BFL|BFL_CLIMBING;
    raiseEvent(ClimbEvt$start, ladder + onStart);
    
    BFL = BFL|BFL_GRACE_PERIOD;
    // Can't dismount for this period due to SL fuckiness
    setTimeout(TIMER_GRACE, 1.5);
	
	Level$raiseEvent( LevelCustomType$STAIR, LevelCustomEvt$STAIR$seated, ladder + 1 );

}

vector offset2global(vector offset){
    return ladder_root_pos+offset*ladder_root_rot;
}


findNearestNode(){
    list l = llList2List(nodes, 1, -2);
    integer nn; float dist;
    
    integer i;
    for(i=0; i<llGetListLength(l); i++){
        float d = llVecDist(llGetRootPosition(), offset2global(llList2Vector(l,i)));
        if(dist == 0 || d<dist){
            nn = i; dist = d;
        }
    }
    perc = (float)nn/(llGetListLength(l)-1);
    onNode = nn+1;
}




#include "ObstacleScript/begin.lsl"


// Events
onRlvSupportCubeSpawn( id )
    CUBE = id;
end

onControlsKeyPress( pressed, released )

    integer up = CONTROL_FWD|CONTROL_RIGHT|CONTROL_UP|CONTROL_ROT_RIGHT;
    integer dn = CONTROL_BACK|CONTROL_LEFT|CONTROL_DOWN|CONTROL_ROT_LEFT;
	
	if( KEY_FILTER ){
	
		pressed = pressed & KEY_FILTER;
		released = released & KEY_FILTER;
		
	}
    if( released&(up|dn) ){
	
        BFL = BFL&~BFL_MOVING;
        BFL = BFL&~BFL_DIR_UP;
		
    }
    
    if( pressed&(up|dn) ){
        
        BFL = BFL|BFL_MOVING;
        if( pressed&up )
            BFL = BFL&~BFL_DIR_UP;
        else 
            BFL = BFL|BFL_DIR_UP;
            
    }
        
end

onRlvFlags( flags )

	RLVFLAGS = flags;

end


// Timers
handleTimer( TIMER_MOVE )

    if( BFL&BFL_DISMOUNTING )
        return;
    
    setTimeout(TIMER_MOVE, .1);
    
    // Agent has unsat
    if( ~llGetAgentInfo(llGetOwner()) & AGENT_SITTING ){
        
        if( BFL&BF_CLIMB_INI )
            return;
            
        dismount(FALSE);
        return;
        
    }
	
	integer bfl = BFL;
	if( RLVFLAGS & RlvFlags$IMMOBILE )
		bfl = BFL&~BFL_MOVING;
    
    
    // This is used to limit updates to 0.4 sec unless moving has just started or ended
    if( BFL&BFL_LAST_UPDATE && (bfl&BFL_MOVING) == (BFL_CACHE&BFL_MOVING) )
        return;

    BFL = BFL|BFL_LAST_UPDATE;
    setTimeout(TIMER_CD, 0.4);
    
    if( bfl & BFL_MOVING ){
        
        vector nodea = offset2global(llList2Vector(nodes,1)); 
        vector nodeb = offset2global(llList2Vector(nodes,2));
        float maxdist = llVecDist(nodea, nodeb);
        float spd = CLIMBSPEED/maxdist*.5;
            
        if( bfl&BFL_DIR_UP )
            perc-=spd;
        else
            perc+=spd;
                
        if( anim_active != "" ){
            
            string a = anim_active;
                
            if( ~bfl&BFL_DIR_UP )
                a = anim_active_down;
				
            if( a != anim_active_cur ){
			
				if( anim_active_cur )
					AnimHandler$stop(LINK_SET, anim_active_cur);
                AnimHandler$start(LINK_SET, a);
				
            }
            anim_active_cur = a;
            
        }
            
            
        // Reached top or bottom
        if( perc > 1 || perc < 0 ){
            
            dismount(TRUE);
            unsetTimer(TIMER_MOVE);
            return;
            
        }
        
		
		
        // Move
        vector point = llVecNorm(nodeb-nodea)*maxdist*perc+nodea;
        translateCubePos(point);
        
    }
    
    else{
    
        if( anim_active_cur != "" ){
            
            AnimHandler$stop(LINK_SET, anim_active_cur);
            anim_active_cur = "";
            
        }
        
        // We just stopped moving, tell the cube
        if( bfl&BFL_MOVING != BFL_CACHE&BFL_MOVING )
            llRegionSayTo(
                CUBE, 
                SupportCubeCfg$listenOverride, 
                (str)SupportCubeOverride$tKFMEnd
            );
        
    }
    
    BFL_CACHE = bfl;
     

end

    
// Dismount complete
handleTimer( TIMER_DISMOUNTING )
    
    if( llGetAgentInfo(llGetOwner())&AGENT_SITTING )
        Rlv$unSit(LINK_THIS, 0);
    
    // Raise climb unsit event
    BFL=BFL&~BFL_DISMOUNTING;
    
end
    
// Initialization complete
handleTimer( TIMER_INI )
    
    BFL = BFL&~BF_CLIMB_INI;
    
end
    
handleTimer( TIMER_CD )
    BFL = BFL&~BFL_LAST_UPDATE;
end

handleTimer( TIMER_GRACE )
    BFL = BFL&~BFL_GRACE_PERIOD;
end

onStateEntry()
    dismount(FALSE);
    memLim(1.5);
end

onRez( nr )
    llResetScript();
end

handleMethod( ClimbMethod$stop )

    if( 
        BFL&BFL_CLIMBING && 
        (
            ~BFL&BFL_GRACE_PERIOD || 
            ~llGetAgentInfo(llGetOwner()) & AGENT_SITTING 
        )
    )dismount(FALSE);
    
end

handleInternalMethod( ClimbMethod$start )

    if( BFL&BFL_CLIMBING ){
        
        if( ~BFL&BFL_GRACE_PERIOD )
            dismount(FALSE);
        return;
        
    }
    
    ladder = trim(argStr(0));
    rot = argRot(1);
    anim_passive = argStr(2);
    anim_active = argStr(3);
    anim_active_down = argStr(4);
    if( anim_active_down == "" )
        anim_active_down = anim_active;
    anim_dismount_top = argStr(5);
    anim_dismount_bottom = argStr(6);
    nodes = llCSV2List(argStr(7));
    CLIMBSPEED = argFloat(8);
    onStart = argStr(9);
    onEnd = argStr(10); 
    KEY_FILTER = argInt(11);
	
	// Need to release and re-press the movement key for filter to work
	BFL = BFL&~BFL_MOVING;
    BFL = BFL&~BFL_DIR_UP;

    if( CLIMBSPEED<=0 )
        CLIMBSPEED = ClimbCfg$defaultSpeed;
    
    list dta = llGetObjectDetails(ladder, [OBJECT_POS, OBJECT_ROT]);
    ladder_root_pos = llList2Vector(dta,0);
    ladder_root_rot = llList2Rot(dta, 1);
    
    integer i;
    if( llGetListLength(nodes) == 2 )
        nodes = llList2List(nodes,0,0)+nodes+llList2List(nodes,-1,-1);
        
    for(; i < llGetListLength(nodes); ++i )
        nodes = llListReplaceList(nodes, [(vector)llList2String(nodes,i)], i, i);
    
    if( llGetListLength(nodes) == 4 )
        mount();
    
end

#include "ObstacleScript/end.lsl"







