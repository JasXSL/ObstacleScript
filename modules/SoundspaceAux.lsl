

float vol_max = 1;
float vol;
integer BFL;
#define BFL_DIR_UP 1

#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"


#include "ObstacleScript/begin.lsl"



onStateEntry()
    llStopSound();
    llSetMemoryLimit(llCeil(llGetUsedMemory()*1.5));
end



handleTimer( "A" )
	float dir = -0.05;
	if( BFL&BFL_DIR_UP )
		dir = -dir;
	
	vol += dir;
	if( vol < 0 ){
	
		vol = 0;
		llStopSound();
		unsetTimer("A");
		return;
		
	}
	
	if( vol > vol_max ){
		
		vol = vol_max;
		unsetTimer("A");
		
	}
	
	llAdjustSoundVolume(vol);
end


handleInternalMethod( SoundspaceAuxMethod$set )
    int active = argInt(0);
    key sound = argKey(1);
    float v = argFloat(2);
    
	
    if( active != THIS_SUB && vol > 0 ){
        
        setInterval("A", 0.05);
        BFL = BFL&~BFL_DIR_UP;
    
    }
    else if( active == THIS_SUB ){
        
        vol = 0;
        vol_max = v;
        BFL = BFL|BFL_DIR_UP;
        llStopSound();
        llLoopSound(sound, 0.01);
        setInterval("A", 0.05);
    
    }
    
end


#include "ObstacleScript/end.lsl"


