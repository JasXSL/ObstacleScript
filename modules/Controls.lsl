

#define USE_STATE_ENTRY
#define USE_CONTROL
#define USE_TOUCH_START
#include "ObstacleScript/index.lsl"

int BFL;
#define BFL_SWIMMING 0x1    // Swimming
#define BFL_CLIMBING 0x2
#define BFL_CONTROLS_BLOCKED 0x4    // Method

updateControls(){
    
    if( BFL & BFL_CONTROLS_BLOCKED )
        return;
    
    if( ~llGetPermissions() & PERMISSION_TAKE_CONTROLS ){
        
        if( llGetAttached() )
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
        return;
        
    }
        
    integer c = CONTROL_ML_LBUTTON|CONTROL_UP; // Needs to bind at least one
    if( BFL&BFL_SWIMMING )
        c = c|
            CONTROL_FWD|CONTROL_BACK|
            CONTROL_UP|CONTROL_DOWN|
            CONTROL_LEFT|CONTROL_RIGHT
        ;
        
    if( BFL&BFL_CLIMBING )
        c = c|
            CONTROL_LEFT|CONTROL_RIGHT|
            CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT|
            CONTROL_FWD|CONTROL_BACK
        ;
        
    llTakeControls(c, TRUE, FALSE);
    
}



#include "ObstacleScript/begin.lsl"

onStateEntry()

    if( llGetAttached() )
        llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);

end

onRunTimePermissions( perms )
    if( perms & PERMISSION_TAKE_CONTROLS )
        updateControls();
end

onControl( level, edge )
    
    if( !edge )
        return;
        
    raiseEvent(ControlsEvt$keypress, (level&edge) + (~level&edge));
    
    
end

onPrimSwimWaterEntered( speed, position )

    BFL = BFL|BFL_SWIMMING;
    updateControls();
    
end

onPrimSwimWaterExited()
    BFL = BFL&~BFL_SWIMMING;
    updateControls();
    
end

onClimbStart( a, b )
    BFL = BFL|BFL_CLIMBING;
    updateControls();
end
onClimbEnd( a, b )
    BFL = BFL&~BFL_CLIMBING;
    updateControls();
end

onTouchStart( total )
    if( llDetectedKey(0) != llGetOwner() )
        return;
    
    integer ln = llDetectedLinkNumber(0);
    string name = llGetLinkName(ln);
    qd("Clicked" + name);

end







// Methods
handleMethod( ControlsMethod$toggle )
    
    bool on = argInt(0);
    BFL = BFL&~BFL_CONTROLS_BLOCKED;
    
    if( on )
        updateControls();   
    else{
        
        BFL = BFL|BFL_CONTROLS_BLOCKED;
        llReleaseControls();
                
    }
        
    
end

#include "ObstacleScript/end.lsl"

