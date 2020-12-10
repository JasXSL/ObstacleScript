

#define USE_STATE_ENTRY
#define USE_TIMER
#define USE_LISTEN
#include "ObstacleScript/index.lsl"


#define TIMER_TICK "A" // Tick windlight
#define TIMER_SPRINT_CHECK "a"
#define TIMER_SPRINT_QUICK "b"
#define TIMER_SPRINT_START_REGEN "c"
#define TIMER_SPRINT_FADE "d"


integer BFL;
#define BFL_NO_UNSIT 0x1
#define BFL_SPRINTING 0x2
#define BFL_RUN_LOCKED 0x4
#define BFL_SPRINT_STARTED 0x8

#define SPRINT_SIZE <0.22981, 0.06894, 0.02039>
#define SPRINT_POS <0, 0, .23>

string cFL; // Cache floor windlight
string cWL; // Cache windlight
key cPrim;  // Cache prim

string W_OR;    // Windlight override

list SLOTS = Rlv$SLOTS;
list STATE = Rlv$STATE;
// Outputs the windlight if it has changed
setWindlight( string preset ){
    
    if( cWL == preset )
        return;
    cWL = preset;
    llOwnerSay("@setenv_preset:"+preset+"=force");
    
}
// Gets the highest level windlight setting
updateWindlight(){
    
    if( W_OR ){
        setWindlight(W_OR);
        return;
    }
    
    vector pos = llGetPos();
    list ray = llCastRay(pos, pos-<0,0,10>, RC_DEFAULT);
    // Prim changed
    if( l2i(ray, -1) == 1 && l2k(ray, 0) != cPrim ){
        
        cPrim = l2k(ray, 0);    
        string desc = fetchDesc(cPrim);
        list data = getDescTaskData( desc, Desc$TASK_WL_PRESET );
        desc = l2s(data, 0);
        if( desc )
            cFL = l2s(data, 0);
        
    }
    
    setWindlight(cFL);
        
    
}









// Sprint
#define SPRINT_GRACE 3
float MAX_SPRINT = 4;
float sprint = MAX_SPRINT;
integer sprintPrim;
float sprintFadeModifier = 1;
float sprintRegenModifier = 1;

outputSprint(){

    llSetLinkPrimitiveParamsFast(sprintPrim, [
        PRIM_TEXTURE, 
        Gui$BAR_BAR_OVERLAY, 
        Gui$BAR_TEXTURE_MAIN, 
        <1,.5,0>, 
        <0,-.25+(1-sprint/MAX_SPRINT)*.5,0>, 
        -PI_BY_TWO
    ]);
    
}

startSprint(){
    
    if( BFL&BFL_SPRINT_STARTED )
        return;
        
    unsetTimer(TIMER_SPRINT_START_REGEN);
    BFL = BFL|BFL_SPRINT_STARTED;
        
    // Show the sprint bar and stop fading
    unsetTimer(TIMER_SPRINT_FADE);
    toggleSprintBar(TRUE);
    
}

toggleSprintBar( int on ){
    
    vector pos;
    if( on )
        pos = SPRINT_POS;
    else{
        
        unsetTimer(TIMER_SPRINT_QUICK);
        unsetTimer(TIMER_SPRINT_START_REGEN);
        unsetTimer(TIMER_SPRINT_FADE);
        
    }
    llSetLinkPrimitiveParamsFast(sprintPrim, (list)
        PRIM_POSITION + pos
    );
    
    
}

damageSprint( float amount ){

    sprint -= llFabs(amount);
    if( sprint<=0 ){
    
        sprint = 0;
        if( ~BFL&BFL_RUN_LOCKED ){
        
            BFL = BFL|BFL_RUN_LOCKED;
            llOwnerSay("@alwaysrun=n,temprun=n");
            
        }
        
    }
    
    startSprint();
    outputSprint();
    
}








// Cube
float lastCube;    // Time last tried rezz
key supportcube;
list cubetasks;
cubeTask( list tasks ){
    
    cubetasks+=tasks;
    if( cubetasks ){
        
        if( llKey2Name(supportcube) != "" ){
            
            runMethod(
                supportcube, 
                "SupportCube", 
                SupportCubeMethod$execute, 
                cubetasks
            );
            cubetasks = [];
            
        }
        else if( llGetTime()-lastCube > 1.0 ){
            
            lastCube = llGetTime();
            llRezAtRoot(
                "SupportCube", 
                llGetRootPosition()-<0,0,3>, 
                ZERO_VECTOR, 
                ZERO_ROTATION, 
                300
            );

        }
        
    }
}















#include "ObstacleScript/begin.lsl"


onStateEntry()

    setInterval(TIMER_TICK, 0.5);
    llListen(SupportCubeCfg$INIT_CHAN, "SupportCube", "", "");
    links_each(num, ln, 
        if( ln == "SPRINT" )
            sprintPrim = num;
    )
    
    llSetLinkPrimitiveParamsFast(sprintPrim, (list)
        PRIM_COLOR + ALL_SIDES + ZERO_VECTOR + 0 +
        PRIM_COLOR + Gui$BAR_BORDER + <.75,1,.75> + 1 +
        //PRIM_COLOR + Gui$BAR_BAR_BG + Gui$BAR_COLOR_BG + Gui$BAR_ALPHA_BG +
        PRIM_POSITION + ZERO_VECTOR +
        PRIM_SIZE + SPRINT_SIZE +
        PRIM_COLOR + Gui$BAR_BAR_OVERLAY + <.5,1,.5> + 1 +
        PRIM_TEXTURE + Gui$BAR_BAR_OVERLAY + Gui$BAR_TEXTURE_MAIN + <1,.5,1> + <0,-.25,0> + -PI_BY_TWO
    );
    
    setInterval(TIMER_SPRINT_CHECK, .5);
    
end


onListen( chan, message )
    
    if( chan == SupportCubeCfg$INIT_CHAN && isEventByOwnerInline() ){
            
        supportcube = SENDER_KEY;
        raiseEvent(RlvEvt$supportCubeSpawn, supportcube);
        cubeTask([]);
    
    }
    

end







// Timer
handleTimer( TIMER_TICK )
    updateWindlight();
end

handleTimer( TIMER_SPRINT_CHECK ) 

    integer pstatus = llGetAgentInfo(llGetOwner());
    if( pstatus&AGENT_ALWAYS_RUN && pstatus&AGENT_WALKING ){
    
        startSprint();
        if( ~BFL&BFL_SPRINTING )
            setInterval(TIMER_SPRINT_QUICK, .1);
        BFL=BFL|BFL_SPRINTING;
        
    }
    else{
    
        if(BFL&BFL_SPRINT_STARTED){
            unsetTimer(TIMER_SPRINT_QUICK);
            setTimeout(TIMER_SPRINT_START_REGEN, SPRINT_GRACE);
            BFL = BFL&~BFL_SPRINT_STARTED;
        }
        BFL = BFL&~BFL_SPRINTING;
        
    }
    
end

handleTimer( TIMER_SPRINT_QUICK )
    
    if( BFL&BFL_SPRINTING ){
    
        damageSprint(.1*sprintFadeModifier);
        return;
        
    }
    
    if( BFL&BFL_RUN_LOCKED && sprint > 0 ){
    
        llOwnerSay("@alwaysrun=y,temprun=y");
        BFL = BFL&~BFL_RUN_LOCKED;
        
    }
    
    sprint += .025*sprintRegenModifier;
    if( sprint >= MAX_SPRINT )
        toggleSprintBar(FALSE);

    if( sprint < 0 )
        sprint = 0;
    else if( sprint > MAX_SPRINT )
        sprint = MAX_SPRINT;
    outputSprint();
    
end

handleTimer( TIMER_SPRINT_START_REGEN )
    setInterval(TIMER_SPRINT_QUICK, .1);
end
    












// Methods
handleMethod( RlvMethod$setClothes )
    
    integer n = argInt(0);
    integer i;
    for(; i < 5; ++i ){
        
        integer st = (n >> (i*2))&3;
        if( st ){
            
            --st;
            llRegionSayTo(
                llGetOwner(), 
                1, 
                "jasx.setclothes "+l2s(STATE, st)+"/"+l2s(SLOTS, i)
            );
            
        }
        
    }

end

handleMethod( RlvMethod$cubeTask )
    
    cubeTask(METHOD_ARGS);
    
end

handleOwnerMethod( RlvMethod$cubeFlush )
    
    cubeTask([]);
    
end

handleMethod( RlvMethod$setWindlight )
    
    W_OR = argStr(0);
    updateWindlight();
    
end


handleMethod( RlvMethod$sit )
    
    key seat = argKey(0);
    bool ignoreUnsit = argInt(1);
    
    // If we're already force sat, that can't be overridden by a non-force sit
    if( !ignoreUnsit && BFL&BFL_NO_UNSIT )
        return;
    
    BFL = BFL&~BFL_NO_UNSIT;
    if( ignoreUnsit )
        BFL = BFL|BFL_NO_UNSIT;
        
    string unsit = "y";
    if( BFL&BFL_NO_UNSIT )
        unsit = "n";
    llOwnerSay("@sit:"+(str)seat+"=force,unsit="+unsit);

end

handleMethod( RlvMethod$unSit )
    
    bool force = argInt(0);
    if( BFL&BFL_NO_UNSIT && !force )
        return;
        
    BFL = BFL&~BFL_NO_UNSIT;
    llOwnerSay("@unsit=yes,unsit=force");

end

handleMethod( RlvMethod$setMaxSprint )
    
    MAX_SPRINT = argFloat(0);
    
    toggleSprintBar(FALSE);
    
    // Toggle timers
    if( MAX_SPRINT <= 0 )
        unsetTimer(TIMER_SPRINT_CHECK);
    else
        setInterval(TIMER_SPRINT_CHECK, 0.5);
        
    // Infinity
    if( MAX_SPRINT != 0.0 )
        llOwnerSay("@temprun=y,alwaysrun=y");
    else
        llOwnerSay("@temprun=n,alwaysrun=n");
    
    sprint = MAX_SPRINT;


end

handleMethod( RlvMethod$damageSprint )
    
    if( MAX_SPRINT <= 0 )
        return;
        
    float perc = argFloat(0);
    damageSprint(MAX_SPRINT*perc);
    
end


#include "ObstacleScript/end.lsl"

