
#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"



integer BFL;
#define BFL_IN_WATER 1
#define BFL_QUEUE 2            // Timer needs to update soundspace
 
// Active sound
string currentsound; 
float currentsoundvol = .5;

// Active ground soundspace
string groundsound;
float groundsoundvol = .5;

// Active override sound set via script
key overridesound;
float overridesoundvol = .5;

float last_update;                // Last update of soundspace

integer aux = 1;   
updateSoundspace(){
    
    if( last_update+2 > llGetTime() ){
    
        BFL = BFL|BFL_QUEUE;
        return;
        
    }

    string cs = currentsound;
    float csv = currentsoundvol;
    // Scripted sound override
    if( overridesound ){
    
        cs = overridesound;
        csv = overridesoundvol;
        
    }
    // Underwater is second
    else if( BFL&BFL_IN_WATER ){
        
        cs = SP_UNDERWATER;
        csv = .5;
        
    }
    // Ground sound last
    else{
        
        csv = groundsoundvol;
        cs = groundsound;
        
    }
    
    // Turn it off if NULL
    if( cs == "" || cs == "NULL" ){
    
        clearSoundspace();
        return;
        
    }
    
    if( cs == currentsound && csv == currentsoundvol )
        return;
    
    last_update = llGetTime();
    
    list SS = SP_DATA
    #ifdef SoundspaceCfg$additionalSounds
        +SOUNDSPACE_ADDITIONAL
    #endif
    ;
    key sound = cs;
    
    // See if sound is a shorthand
    integer i;
    for( ; i<llGetListLength(SS); i+=2 ){
    
        if( llList2String(SS,i) == cs )
            sound = llList2String(SS,i+1);
            
    }
    
    SoundspaceAux$set(aux, sound, csv);
    ++aux;
    if( aux > 2 )
        aux = 1;
    
}
clearSoundspace(){

    currentsound = "";
    groundsound = "";
    SoundspaceAux$set(0, "", 0);
 
}



#include "ObstacleScript/begin.lsl"

onStateEntry()

    clearSoundspace(); 
    llSetMemoryLimit(llCeil(llGetUsedMemory()*1.5));
    setInterval("a", 0.5);
    llSetStatus(STATUS_DIE_AT_EDGE, TRUE);
    
end


handleTimer("a")

    // Raycast
    list ray = llCastRay(
        llGetRootPosition(), 
        llGetRootPosition()-<0,0,10>, 
        RC_DEFAULT
    );

    if( l2i(ray,-1) == 1 ){
    
        string desc = (string)llGetObjectDetails(llList2Key(ray,0), [OBJECT_DESC]);
        list split = llParseString2List(desc, ["$$"], []);
        
        list dta = getDescTaskData(desc, Desc$TASK_SOUNDSPACE);
        
        string ssp = llList2String(dta,0);  
        float v = llList2Float(dta,1);
        if( dta != [] && isset(ssp) ){
        
            if( groundsound != ssp || v != groundsoundvol ){ 
            
                groundsoundvol = v;
                groundsound = ssp;
                if(currentsound == "")
                    updateSoundspace();
                    
            }
            
        } 
        
    }
    
    if( BFL&BFL_QUEUE && llGetTime() > last_update+2 ){
        
        BFL = BFL&~BFL_QUEUE;
        updateSoundspace();
        
    }

end




handleMethod( SoundspaceMethod$override )

    key s = argKey(0);
    overridesound = "";
    
    if( s ){
    
        overridesound = s;
        overridesoundvol = argFloat(1);
        
    }
    
    updateSoundspace();
    
end


handleInternalMethod( SoundspaceMethod$dive )
    
    if( argInt(0) && ~BFL&BFL_IN_WATER ){
    
        BFL = BFL|BFL_IN_WATER;
        updateSoundspace();
        
    }
    else if( !argInt(0) && BFL&BFL_IN_WATER ){
    
        BFL = BFL&~BFL_IN_WATER;
        updateSoundspace();
        
    }

end

handleInternalMethod( SoundspaceMethod$reset )
    
    currentsound = "";
    groundsound = "";
    updateSoundspace();

end


#include "ObstacleScript/end.lsl"

