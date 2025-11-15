#define USE_STATE_ENTRY
#define USE_LISTEN
#define USE_TOUCH_START
#define USE_ON_REZ
#define SCRIPT_IS_PLAYER_MANAGER
#include "ObstacleScript/index.lsl"

install(){
	list objects; list categories;
	integer i;
	for(; i < llGetInventoryNumber(INVENTORY_NOTECARD); ++i ){
	
		string nc = llGetInventoryName(INVENTORY_NOTECARD, i);
		list spl = split(nc, ".");
		string ext = l2s(spl, -1);
				
		string fn = join(llDeleteSubList(spl, -1, -1), ".");
		if( ext == "category" )
			categories += fn;
		else{
			if( llGetInventoryType(fn) != INVENTORY_OBJECT ){
				qd("Fatal error. Level has no object attached: " + fn);
				return;
			}
			
			objects += fn;
		}
		
	}
	
	if( objects == [] ){
		qd("Fatal error: No levels passed filter. Make sure each level has a notecard with the same name as the level, but ending with .scene");
		return;
	}
	
    Scene$reqInstall( llGetOwner(), objects, categories, llGetScriptName(), SceneInstallerMethod$install );
}

#include "ObstacleScript/begin.lsl"

onRez( total )
	
	integer pin = llCeil(llFrand(0xFFFFFFF));
	llSetRemoteScriptAccessPin(pin);
	Screpo$get( pin, 1, llGetScriptName(), TRUE );
	
end

onStateEntry()
    
    setupListenTunnel();
    llSetText("Touch To Install", <1,1,1>, 1);
	install();

end

onTouchStart( total )
	if( llDetectedKey(0) != llGetOwner() )
		return;
	install();
end

handleOwnerMethod( SceneInstallerMethod$install )
    
    list items = llJson2List(argStr(0));
	list cats = llJson2List(argStr(1));
    integer i;
    for(; i < count(items); ++i ){
        
        string item = l2s(items, i);
        llGiveInventory(SENDER_KEY, item);
        llGiveInventory(SENDER_KEY, item+".scene");
        
    }
	for( i = 0; i < count(cats); ++i ){
		string item = l2s(cats, i)+".category";
		llGiveInventory(SENDER_KEY, item);
	}
    Scene$installComplete(prRoot(SENDER_KEY));

end

handleListenTunnel()


#include "ObstacleScript/end.lsl"




