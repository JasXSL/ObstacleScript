#include "ObstacleScript/helpers/Ghost/GhostHelper.lsb"
#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"
string ID;

key GHOST;  // Set to the ghost key when the ghost starts hunting
integer P_EMF;
integer BFL;
#define BFL_ON 0x1
#define BFL_HUNTING 0x2
#define BFL_DROPPED 0x4
#define BFL_VISIBLE 0x8
float DUR = 8;	// Set when receiving an EMF

list EMF_POINTS;    // key id, int strength(1-5), (float)time


integer C_EMF = -1;
// EMF changed
setEMF( integer emf ){

    if( BFL&BFL_ON && emf < 1 )
        emf = 1;
    if( emf > 5 )
        emf = 5;
        
    if( ~BFL&BFL_ON )
        emf = 0;
		
	if( llGetInventoryType("ToolSet") == INVENTORY_NONE && ~BFL&BFL_DROPPED )
		emf = 0;
        
		
    if( C_EMF == emf )
        return;
        
    C_EMF = emf;
	
	list COLORS = [
		<0.188, 1.000, 0.188>,
		<0.784, 1.000, 0.188>,
		<1.000, 0.911, 0.188>,
		<1.000, 0.626, 0.188>,
		<1.000, 0.188, 0.188>
	];

    float vol = 0.001;
    if( emf > 1 )
        vol = llPow((1.0/4*(emf-1))*.6+.2, 2);
    
	float alpha;
	if( BFL&BFL_VISIBLE || !llGetAttached() )
		alpha = 1.0;
	
	vol *= .25;
    list set;
    integer i;
    for(; i < 5; ++i ){
        
        integer face = i+1;
        integer on = emf > i;
		vector color = l2v(COLORS, i);
		if( !on )
			color *= 0.5;
        set += (list)
            PRIM_FULLBRIGHT + face + on +
            PRIM_GLOW + face + on*.1 +
			PRIM_COLOR + face + color + alpha
        ;
        
    }
	    
    llSetLinkPrimitiveParamsFast(P_EMF, set);
    llAdjustSoundVolume(vol);
    
}

toggleOn( integer on ){
    
    if( on ){
        
        BFL = BFL|BFL_ON;
        llStopSound();
        llLoopSound("ca52dde3-1c21-d380-442b-aa4b245e7522", 0.0001);
        setInterval("EMF", .5);
        
    }
    else{
        
        BFL = BFL&~BFL_ON;
        llAdjustSoundVolume(0);
        unsetInterval("EMF");
        
    }
    
    setEMF(0);
           
}

onDataChanged( integer data ){
    
    toggleOn(data);
    
}




#include "ObstacleScript/begin.lsl"

onStateEntry()
       
    forLink( nr, name )
    
        if( name == "OWOMETER" )
            P_EMF = nr;
    
    end
    
    toggleOn(FALSE);
    
    if( llGetAttached() )
        llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
    
    Portal$scriptOnline();
		
end

handleMethod( OwometerMethod$addPoint )
    
    key point = argKey(0);
    integer emf = argInt(1)%5;
	DUR = argFloat(2);
	if( DUR < 8 )
		DUR = 8;
    
    integer pos = llListFindList(EMF_POINTS, (list)point);
    if( ~pos )
        EMF_POINTS = llDeleteSubList(EMF_POINTS, pos, pos+2);
    
    EMF_POINTS += (list)point + (emf+1) + llGetTime();

end

onToolSetActiveTool( tool, data )

    if( tool != ToolsetConst$types$ghost$owometer ){
		BFL = BFL&~BFL_VISIBLE;
        toggleOn(FALSE);
	}
    else{
		BFL = BFL|BFL_VISIBLE;
		if( (int)data )
			llSleep(.1);	// Fixes audio race conditions with spirit box
        onDataChanged((int)data);
	}
end

onGhostToolHunt( hunting, ghost )
    
    GHOST = ghost;
    BFL = BFL&~BFL_HUNTING;
    if( hunting )
        BFL = BFL|BFL_HUNTING;

end

// Raised only if rezzed and not picked up. This is raised when placing the asset under the level. Can be used to hide it etc.
onGhostToolPickedUp()

    if( llGetInventoryType("ToolSet") != INVENTORY_NONE )
        return;
    
	BFL = BFL&~BFL_DROPPED;
    toggleOn(FALSE);
	
    
end

// Raised after positioning this on the floor (if the asset is NOT attached)
onGhostToolDropped( data )

    if( llGetInventoryType("ToolSet") != INVENTORY_NONE )
        return;
    
	C_EMF = -1;
	BFL = BFL | BFL_DROPPED;
    onDataChanged((int)data);
    
end

handleTimer( "EMF" )

    if( BFL & BFL_HUNTING ){
        
        integer n;
        if( llVecDist(llGetPos(), prPos(GHOST)) < 4 )
            n = llCeil(llFrand(3))+1;
        setEMF(n);
        return;
        
    }
    
    float dist;
    integer index = -1;
    
	vector front = llGetPos();
	
	if( llGetAttached() ){
	
		front = llGetPos()+llRot2Fwd(llGetRootRotation());
		if( llGetPermissions() & PERMISSION_TRACK_CAMERA && llGetAgentInfo(llGetOwner()) & AGENT_MOUSELOOK )
			front = llGetCameraPos()+llRot2Fwd(llGetCameraRot());
			
    }
    integer i;
    for( ; i < count(EMF_POINTS) && count(EMF_POINTS); i += 3 ){
        
        // Expiry check
        float time = l2f(EMF_POINTS, i+2);
        if( llGetTime()-time > DUR ){
            
            EMF_POINTS = llDeleteSubList(EMF_POINTS, i, i+2);
            i -= 3;
            
        }
        // Check EMF
        else{
            
            key id = l2k(EMF_POINTS, i);
            float d = llVecDist(front, prPos(id));
            
            // 2m radius EMF bubble
            if( (index == -1 || d < dist) && d < 2 ){
                
                dist = d;
                index = i;
                
            }
            
        }
                
    }
    
    if( index == -1 )
        setEMF(0);
    else
        setEMF(l2i(EMF_POINTS, index+1));
    
    

end


#include "ObstacleScript/end.lsl"



