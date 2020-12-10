#ifdef onThud
    #define USE_COLLISION_START
#endif
#define USE_TIMER
#define USE_STATE_ENTRY
#include "ObstacleScript/index.lsl"




list gSND;  // Sounds global
list gCOL;  // Collision sounds global



string CURRENT_WALKABLE = ""; 
key CURRENT_PRIM = "";
float CURRENT_VOL = -1;
list SOUND_CACHE;
key previousSound;

integer BFL;
#define BFL_IN_AIR 1
#define BFL_SWIMMING 2

#define TIMER_STEP "a"
#define TIMER_RECHECK "b"

integer pInteract; 

string targDesc;
string WL;
key targ;


// Use "" to just init
setWalkable( string walkable ){
    
    if( 
        walkable == CURRENT_WALKABLE || 
        walkable == ""
    )return;
    CURRENT_WALKABLE = walkable;
    
    SOUND_CACHE = [];
    integer i; integer pushing;
    for( ; i < llGetListLength(SOUNDS); ++i ){ 
        
        integer type = llGetListEntryType(SOUNDS, i);
        if( type != TYPE_KEY ){ 
            if( llList2String(SOUNDS, i) == CURRENT_WALKABLE )
                pushing = TRUE;
            else if( pushing )
                return;
        }
        else if( pushing )
            SOUND_CACHE += llList2Key(SOUNDS, i);
            
    }
} 











#include "ObstacleScript/begin.lsl"

onStateEntry()

    gSND = SOUNDS;
    #ifdef onThud
    gCOL = COLS;
    #endif
    
    setWalkable("DEFAULT");
    setInterval(TIMER_STEP, FootstepsCfg$SPEED);
    setInterval(TIMER_RECHECK, .25);
end


onPrimSwimWaterEntered( speed, pos )
    BFL = BFL|BFL_SWIMMING;
end

onPrimSwimWaterExited()
    BFL = BFL &~ BFL_SWIMMING;
end




handleTimer(TIMER_STEP)

    integer status = llGetAgentInfo(llGetOwner());
    if(status&AGENT_IN_AIR){
        
        BFL=BFL|BFL_IN_AIR; 
        return;
        
    }
    
    BFL = BFL&~BFL_IN_AIR;
    if( 
        ~status&AGENT_WALKING ||
        SOUND_CACHE == [] ||
        BFL&BFL_SWIMMING
    )return;
    
    float vol = CURRENT_VOL;
    if( vol == -1 ){ 
        
        vol = FootstepsCfg$WALK_VOL;
        if( status&AGENT_ALWAYS_RUN )
            vol = FootstepsCfg$RUN_VOL;
        if( status&AGENT_CROUCHING )
            vol = FootstepsCfg$CROUCH_VOL;
            
    }
    
    if( vol <= 0 )
        return;
    
    list snd = SOUND_CACHE;
    if( llGetListLength(snd) > 1 ){
        
        int pos = llListFindList(snd, (list)previousSound);
        if( ~pos )
            snd = llDeleteSubList(snd, pos, pos);
            
    }
    llTriggerSound(randElem(snd), vol);
end

handleTimer( TIMER_RECHECK) 

    list ray = llCastRay(
        llGetRootPosition(), 
        llGetRootPosition()-<0,0,4>, 
        [RC_REJECT_TYPES, RC_REJECT_AGENTS]
    );
    
    if( llList2Integer(ray, -1) <= 0 )
        CURRENT_PRIM = "";
    else{ 
        
        if( CURRENT_PRIM == llList2Key(ray, 0) )
            return;
            
        CURRENT_PRIM = llList2Key(ray, 0);
        
        
        string desc = prDesc(llList2Key(ray,0));
        list data = getDescTaskData( desc, Desc$TASK_FOOTSTEPS  );
        
        if( count(data) ){
            setWalkable(llList2String(data,0));
            if( llGetListLength(data) >= 2 )
                CURRENT_VOL = llList2Float(data,1);
            else
                CURRENT_VOL = -1;
            return;   
        }
        

        CURRENT_VOL = -1;
        setWalkable("DEFAULT");
    }
    

end



#ifdef onThud
onCollisionStart( total )

    if( ~BFL & BFL_IN_AIR )
        return;
        
    BFL = BFL&~BFL_IN_AIR;
    vector vel = llGetVel();
    if( vel.z < -4 ){ 
    
        integer i;
        list available; integer parsing;
        for( ; i<llGetListLength(COLS); ++i ){
            
            integer type = llGetListEntryType(COLS, i);
            if( type != TYPE_KEY ){ 
            
                if( llList2String(COLS, i) == CURRENT_WALKABLE )
                    parsing = TRUE;
                else if( parsing )
                    i = llGetListLength(COLS);
                    
            } 
            else if( parsing )
                available += llList2Key(COLS, i);
            
        }
        
        if( available != [] ){
            
            llTriggerSound(randElem(available), 1);
            float range = llFabs(vel.z);
            onThud(range);
            
        }
        
    }
    
end
#endif

#include "ObstacleScript/end.lsl"



