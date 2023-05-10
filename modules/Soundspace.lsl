
#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"
#include "../shared/sound_registry.lsh"


integer BFL;
#define BFL_IN_WATER 1
#define BFL_QUEUE 2            // Timer needs to update soundspace
 
// Active sound
string currentSound; 
float currentSoundVol = .5;
float preSoundVol = 0;

// Active ground soundspace
string groundsound;
float groundsoundvol = .5;

// Active override sound set via script
key overridesound;
float overridesoundvol = .5;



float last_update;				// Last update of soundspace

// Time when last change was
float tweenStarted;
int aux;			// Which prim are we tweening up?

#define getAuxLink( pr ) l2i((list)hsr$soundspaceA + hsr$soundspaceB, pr)


updateSoundspace(){
    
    string cSound;						// 
	float cSoundVol;
	
	// Scripted sound override
	if( overridesound ){
	
		cSound = overridesound;
		cSoundVol = overridesoundvol;
		
	}
	// Underwater is second
    else if( BFL&BFL_IN_WATER ){
        
		cSound = SP_UNDERWATER;
        cSoundVol = .5;
		
    }
	// Ground sound last
    else{
        
		cSoundVol = groundsoundvol;
        cSound = groundsound;
		
    }
	
	if( cSound == "NULL" )
		cSound = "";
	
	if( cSound == currentSound && cSoundVol == currentSoundVol )
		return;
	
	// Need to wait for the current tween
	if( llGetTime()-last_update < 1.0 && ~BFL&BFL_QUEUE ){
		setTimeout("Q", llGetTime()-last_update+0.1);
		return;
	}
	
	last_update = llGetTime();
	currentSound = cSound;
	
	
	
	
	// Turn it off if NULL
    if( cSound == "" ){
	
        clearSoundspace();
        return;
		
    }

	preSoundVol = currentSoundVol;
	currentSoundVol = cSoundVol;
	
	list SS = SP_DATA;
	key sound = cSound;
	// See if sound is a shorthand
	integer i;
    for( ; i<llGetListLength(SS); i+=2 ){
	
        if( llList2String(SS,i) == cSound )
			sound = llList2String(SS,i+1);
			
	}
	
	aux = !aux;
	
	int link = getAuxLink(aux);
	llLinkPlaySound(link, sound, 0.01, SOUND_LOOP);
	tweenStarted = llGetTime();
	
	setInterval("V", 0.05);
    
}
clearSoundspace(){

    currentSound = "";
    groundsound = "";
	preSoundVol = currentSoundVol;
	currentSoundVol = 0;
	tweenStarted = llGetTime();
	aux = !aux;
	llLinkStopSound(getAuxLink(aux));
	setInterval("V", 0.05);
 
}


#include "ObstacleScript/begin.lsl"

onStateEntry()

    clearSoundspace(); 
    llSetMemoryLimit(llCeil(llGetUsedMemory()*1.5));
    setInterval("a", 0.5);
    llSetStatus(STATUS_DIE_AT_EDGE, TRUE);
    
end


handleTimer("a")

	list ray = llCastRay(llGetRootPosition(), llGetRootPosition()-<0,0,10>, [RC_REJECT_TYPES, RC_REJECT_PHYSICAL|RC_REJECT_AGENTS]);

	if( llList2Integer(ray,-1)==1 ){
	
		string desc = (string)llGetObjectDetails(llList2Key(ray,0), [OBJECT_DESC]);
		list split = llParseString2List(desc, ["$$"], []);
		
		list dta = getDescTaskData(desc, Desc$TASK_SOUNDSPACE);
		string ssp = llList2String(dta,0);  
		float v = llList2Float(dta,1);
		if( dta != [] && isset(ssp) ){
		
			if( groundsound != ssp || v != groundsoundvol ){ 
			
				groundsoundvol = v;
				groundsound = ssp;
				updateSoundspace();
					
			}
			
		} 
		
	}

end

handleTimer("V")

	float perc = llGetTime()-tweenStarted;
	if( perc > 1 ){
		perc = 1;
		unsetTimer("V");
	}
	
	integer link = getAuxLink(aux);
	llLinkAdjustSoundVolume(link, perc*currentSoundVol);
	link = getAuxLink(!aux);
	llLinkAdjustSoundVolume(link, (1.0-perc)*preSoundVol);
	
end


handleTimer( "Q" )

	BFL = BFL&~BFL_QUEUE;
	updateSoundspace();
	
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
    
    currentSound = "";
    groundsound = "";
    updateSoundspace();

end


#include "ObstacleScript/end.lsl"

