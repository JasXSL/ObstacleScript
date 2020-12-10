#define USE_TIMER
#define USE_TIMER
#define USE_OBJECT_REZ
#define USE_SENSOR
#define USE_NO_SENSOR
#define USE_STATE_ENTRY
#include "ObstacleScript/index.lsl"

int BFL;
#define BFL_WAIT_SPAWN 0x1

list AIR_POCKETS;            // Handles all the air pockets
key PARTICLE_HELPER;        // Active particle generator prim
integer CACHE_CHAN;         // Channel it communicates on



list QUEUE;
send( string task, list data ){
    
    if( llKey2Name(PARTICLE_HELPER) )
        return llRegionSayTo(PARTICLE_HELPER, CACHE_CHAN, mkarr(task + data));
    
    QUEUE = (list)task+data;
    spawnHelper();
    
}

spawnHelper(){
    
    if( BFL&BFL_WAIT_SPAWN )
        return;
        
    llRezAtRoot("PrimSwimParts", llGetRootPosition()-<0,0,3>, ZERO_VECTOR, ZERO_ROTATION, 1);
    BFL = BFL|BFL_WAIT_SPAWN;
    setTimer("wait", 5);

}




onEvt( string script, integer evt, list data){
    
    if( script != "jas PrimSwim" )
        return;
        
    if( evt == PrimSwimEvt$onWaterEnter )
        send(jasPrimSwimParticles$onWaterEntered, data);
    
    else if( evt == PrimSwimEvt$onWaterExit )
        send(jasPrimSwimParticles$onWaterExited, data);
    
}






#include "ObstacleScript/begin.lsl"

onStateEntry()

    CACHE_CHAN = PrimSwimAuxCfg$partChan;
    llSensorRepeat(PrimSwimCfg$pnAirpocket, "", ACTIVE|PASSIVE, 90, PI, 5);
    memLim(1.5);

end


handleTimer("wait")
    BFL = BFL&~BFL_WAIT_SPAWN;
end


onObjectRez( id )
    
    if( llKey2Name(id) == "PrimSwimParts" ){
        
        if( PARTICLE_HELPER )
            llRegionSayTo(PARTICLE_HELPER, CACHE_CHAN, "DIE");
        
        PARTICLE_HELPER = id;
        PrimSwim$particleHelper(PARTICLE_HELPER);
        llSleep(.1);
        send(l2s(QUEUE, 0), llDeleteSubList(QUEUE, 0, 0));
        
    }
    
end


onSensor( total )

    list output; 
    integer i; 
    integer recache;
    for( ; i<total; i++ ){
    
        if( !recache ){
        
            integer pos = llListFindList(AIR_POCKETS, [llDetectedKey(i)]);
            if( pos==-1 )
                recache = TRUE;
                
        }
        
        output+=llDetectedKey(i);
        
    }
    
    if( !recache )
        return;
        
    AIR_POCKETS = output;
    PrimSwim$airpockets(AIR_POCKETS);

end

onNoSensor()

    if( AIR_POCKETS != [] )
        PrimSwim$airpockets([]);
    AIR_POCKETS = [];

end

handleInternalMethod( PrimSwimAuxMethod$spawn )
    spawnHelper();
end


#include "ObstacleScript/end.lsl"




