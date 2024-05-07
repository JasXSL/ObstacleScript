
#define USE_TIMER
#define USE_STATE_ENTRY
#define USE_CONTROL
#define USE_TOUCH_START
#include "ObstacleScript/index.lsl"

int BFL;
#define BFL_SWIMMING 0x1    // Swimming
#define BFL_CLIMBING 0x2
#define BFL_CONTROLS_BLOCKED 0x4    // Method
#define BFL_QTE 0x8

int RLV_FLAGS;

updateControls(){
    
    if( BFL & BFL_CONTROLS_BLOCKED )
        return;
    
    if( ~llGetPermissions() & PERMISSION_TAKE_CONTROLS ){
        
        if( llGetAttached() )
            llRequestPermissions(llGetOwner(), PERMISSION_TAKE_CONTROLS);
        return;
        
    }
	
	int takeAll = RLV_FLAGS&RlvFlags$IMMOBILE || BFL&BFL_QTE;
        
	// RLVFlags pick both since together they grab all controls
    integer c = CONTROL_ML_LBUTTON|CONTROL_UP; // Needs to bind at least one
    if( BFL&BFL_SWIMMING || takeAll )
        c = c|
            CONTROL_FWD|CONTROL_BACK|
            CONTROL_UP|CONTROL_DOWN|
            CONTROL_LEFT|CONTROL_RIGHT
        ;
        
    if( BFL&BFL_CLIMBING || takeAll )
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
	setInterval("CTL", 10);

end

handleTimer( "CTL" )
	updateControls(); // Workaround for people with shitty attachments
end

onRunTimePermissions( perms )
    if( perms & PERMISSION_TAKE_CONTROLS )
        updateControls();
end

onControl( level, edge )
    
    if( !edge )
        return;
        
    raiseEvent(ControlsEvt$keypress, (level&edge) + (~level&edge));
	
	if( edge & CONTROL_ML_LBUTTON ){
		
		int evt = PortalCustomEvt$LCLICK$start;
		if( ~level & CONTROL_ML_LBUTTON )
			evt = PortalCustomEvt$LCLICK$end;
			
		Portal$raiseEvent( llGetOwner(), PortalCustomType$LCLICK, evt, [] );
		
    }
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

onQteStart( type )
	BFL = BFL|BFL_QTE;
	updateControls();
end
onQteEnd( success )
	BFL = BFL&~BFL_QTE;
	updateControls();
end

onTouchStart( total )
    if( llDetectedKey(0) != llGetOwner() )
        return;
    
    integer ln = llDetectedLinkNumber(0);
    string name = llGetLinkName(ln);
	raiseEvent(ControlsEvt$click, name);
	
	Level$targRaiseEvent( ComGet$host(), LevelCustomType$HUDCLICK, LevelCustomEvt$HUDCLICK$click, name );
	
end

onRlvFlags( flags )
	
	RLV_FLAGS = flags;
	updateControls();


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

