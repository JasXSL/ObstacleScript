#define USE_RUN_TIME_PERMISSIONS
#define USE_STATE_ENTRY
#define USE_ATTACH
#define USE_TIMER
#define USE_LISTEN
#include "ObstacleScript/index.lsl"
#include "ObstacleScript/helpers/Ghost/GhostHelper.lsb"


int BFL;
#define BFL_USING 0x1   // Using an item

// Equipped tools
int C_TOOL;			// cache of active tool
int ACTIVE_TOOL;    // index of stride in TOOLS. Use activeType for type
// (int)tool, (var)setting, (key)id
list TOOLS;
#define TOOLSTRIDE 3
#define TTEMPLATE (list)0 + 0 + 0    // Empty slot

#define activeType() l2i(TOOLS, ACTIVE_TOOL*TOOLSTRIDE)

#define PP llSetLinkPrimitiveParamsFast
#define AL llSetLinkAlpha

#define getActiveToolInt() l2i(TOOLS, ACTIVE_TOOL*TOOLSTRIDE+1)
#define getActiveToolStr() l2s(TOOLS, ACTIVE_TOOL*TOOLSTRIDE+1)
#define getActiveToolWorldId() l2k(TOOLS, ACTIVE_TOOL*TOOLSTRIDE+2)
#define getActiveToolList() llList2List(TOOLS, ACTIVE_TOOL*TOOLSTRIDE+1, ACTIVE_TOOL*TOOLSTRIDE+1)
// Raises active tool event
#define sendActiveTool( tool ) raiseEvent(ToolSetEvt$activeTool, tool + getActiveToolList())
// Accepts one argument, can be any type. Lists passed must be JSON encoded
#define setActiveToolVal( val ) TOOLS = llListReplaceList(TOOLS, (list)(val), ACTIVE_TOOL*TOOLSTRIDE+1, ACTIVE_TOOL*TOOLSTRIDE+1)

integer P_OWOMETER;
integer P_FLASHLIGHT;
integer P_FLASHLIGHTBEAM;
integer P_HOTS;
integer P_HOTSBALL;
integer P_ECCHISKETCH;
integer P_SPIRITBOX;
integer P_SALT;
integer P_VAPE;
integer P_OUIJA;
integer P_PLANCHETTE;
integer P_PILLS;
integer P_PIR;
integer P_PIR_CAN;
integer P_BAT;
integer P_GSTICK;
integer P_PARA;
integer P_PARAMON;
//integer P_CAM;
integer P_THERMO;
integer P_THERMO_POSTIT;
integer P_VCAM;

int DT;	// Force detach on perms

vector SOUND_SPOT;
float SOUND_TIME;
float TEMP_TIME;
integer TEMPERATURE;

string curAnim;

int AFFIXES;

list toggleAsset( integer link, integer on ){
	
	list textures = llCSV2List(getLinkDesc(link));
	list out = (list)PRIM_LINK_TARGET + link;
	
	if( textures == [] )
		return textures;
	if( !on )
		return out + PRIM_RENDER_MATERIAL + ALL_SIDES+ TEXTURE_HIDDEN;
	
	key base = l2k(textures, 0);
	
	// If there's only one texture set, we expect ALL_SIDES to have this
	if( count(textures) == 1 )
		return out + PRIM_RENDER_MATERIAL + ALL_SIDES + base;
		
	// Start by clearing render material to unhide any invisible non-PBR textures
	out += (list)PRIM_RENDER_MATERIAL + ALL_SIDES + "";
		
	integer i;
	for(; i < count(textures); ++i ){
		
		str texture = l2s(textures, i);
		if( (key)texture )
			out += (list)
				PRIM_RENDER_MATERIAL + i + texture
			;
		// Set to "a" to use the base texture
		else if( llToLower(texture) == "a" )
			out += (list)
				PRIM_RENDER_MATERIAL + i + base
			;
		
	}
	return out;
	
	
}

// Attachment data received for the active asset
onDataUpdate(){
    
    integer tool = activeType();
    integer on = getActiveToolInt();
	
    if( tool == ToolsetConst$types$ghost$flashlight ){
		
		list d = llJson2List(getActiveToolStr());
		on = l2i(d, 0);
		integer percent = l2i(d, 1);
		if( !on )
			percent = 0;
        PP(
            P_FLASHLIGHTBEAM, 
            GhostHelper$getFlashlightLightSettings( on, percent )
        );
        PP(
            P_FLASHLIGHT,
			GhostHelper$getFlashlightFrontSettings( P_FLASHLIGHT, percent )
        );
        
    }
    else if( tool == ToolsetConst$types$ghost$ecchisketch ){
        
		// The art layer doesn't use materials
        AL(P_ECCHISKETCH, on, 4);
        if( on ){
            
            --on;
            PP(
                P_ECCHISKETCH, 
                (list)PRIM_TEXTURE + 4 + "9b2f4cf3-2796-4a6a-e5f4-0b93693c86aa" + <.5, .5, 0> + <-.25+(on%2)*.5, .25-(on/2)*.5, 0> + 0
            );
            
        }
        
    }
    else if( tool == ToolsetConst$types$ghost$glowstick ){
	
		list d = llJson2List(getActiveToolStr());
		int perc = l2i(d, 1);
		PP(P_GSTICK, GhostHelper$getGlowstickSettings(P_GSTICK, l2i(d, 0), perc));
		
	}
    else if( tool == ToolsetConst$types$ghost$parabolic ){
        
        PP( P_PARAMON, (list)
            PRIM_COLOR + 4 + ZERO_VECTOR + on +
            PRIM_COLOR + 5 + ZERO_VECTOR + on +
            PRIM_COLOR + 6 + ZERO_VECTOR + on +
            PRIM_COLOR + 7 + ZERO_VECTOR + on +
			gsmFullbright(P_PARAMON, 3, (<.25,.25,.25>*on))
        );
        onTick();
        
    }
	/*
	else if( tool == ToolsetConst$types$ghost$camera ){
		
		integer pics = GhostHelper$CAM_MAX_PICS-on;
		if( pics < 0 )
			pics = 0;
			
		PP( P_CAM, (list)
			PRIM_TEXTURE + 4 + "2aaf7eb6-4ebb-52da-b32a-7e2d4d45c73d" + <0.06250,0.7,0> + <-0.46875+0.0625*pics,0,0> + 0
		);
		
	}
	*/
	
    else if( tool == ToolsetConst$types$ghost$thermometer ){
	
		integer f = getActiveToolInt();
		llSetLinkPrimitiveParamsFast(P_THERMO, (list)
			PRIM_TEXTURE + 6 + "2aaf7eb6-4ebb-52da-b32a-7e2d4d45c73d" + <1.0/16, 1, 0> + <-0.46875+.0625*(14-f*2), 0, 0> + 0 // F/C
		);
		TEMP_TIME = 0;
		onTick();
		
	}    
    
    sendActiveTool(tool);
    
}


// Draws the currently active tool
drawActiveTool(){
    
    integer tool = activeType();
	if( tool == C_TOOL )
		return; // Prevent redundant draws
	C_TOOL = tool;
	
	
    list remLight = (list)PRIM_POINT_LIGHT + FALSE + <1.000, 0.928, 0.710> + 1 + 4 + 1;

    // Owometer
	list set;
	set += toggleAsset(P_OWOMETER, tool == ToolsetConst$types$ghost$owometer);

    // Flashlight
	set += toggleAsset(P_FLASHLIGHT, tool == ToolsetConst$types$ghost$flashlight); // Note: this sets the link target
    set += gsmFullbright(P_FLASHLIGHT, 2, ZERO_VECTOR);
	set += (list)PRIM_LINK_TARGET + P_FLASHLIGHTBEAM + remLight;

	PP(0, set);
	set = [];

	
	
    // HOTS
    set += toggleAsset(P_HOTS, tool == ToolsetConst$types$ghost$hots);
	set += toggleAsset(P_HOTSBALL, tool == ToolsetConst$types$ghost$hots);
	
	// Ecchisketch
	set += toggleAsset(P_ECCHISKETCH, tool == ToolsetConst$types$ghost$ecchisketch);
	
	// Spiritbox
	set += toggleAsset(P_SPIRITBOX, tool == ToolsetConst$types$ghost$spiritbox);
    AL(P_SPIRITBOX, 0, 4); // The display doesn't use materials
	
	set += toggleAsset(P_SALT, tool == ToolsetConst$types$ghost$salt);
	set += toggleAsset(P_VAPE, tool == ToolsetConst$types$ghost$vape);
	
	set += toggleAsset(P_OUIJA, tool == ToolsetConst$types$ghost$weegieboard);
	set += toggleAsset(P_PLANCHETTE, 0);
	
	set += toggleAsset(P_PILLS, tool == ToolsetConst$types$ghost$pills);
	
    set += toggleAsset(P_PIR, tool == ToolsetConst$types$ghost$motionDetector);
    set += toggleAsset(P_PIR_CAN, tool == ToolsetConst$types$ghost$motionDetector);
	
	PP(0, set);
	set = [];
	
	
	set += toggleAsset(P_BAT, tool == ToolsetConst$types$ghost$hornybat);
	
	set += toggleAsset(P_GSTICK, tool == ToolsetConst$types$ghost$glowstick);
	set += gsmFullbright(P_GSTICK, 0, ZERO_VECTOR);
	set += (list)PRIM_LINK_TARGET + P_GSTICK + remLight;
	
	set += toggleAsset(P_PARAMON, tool == ToolsetConst$types$ghost$parabolic);
    set += toggleAsset(P_PARA, tool == ToolsetConst$types$ghost$parabolic);
	
	set += toggleAsset(P_THERMO, tool == ToolsetConst$types$ghost$thermometer);
	set += gsmFullbright(P_THERMO, 2, (<.3,.3,.2>*(tool == ToolsetConst$types$ghost$thermometer)));
	set += toggleAsset(P_THERMO_POSTIT, tool == ToolsetConst$types$ghost$thermometer);
	
	set += toggleAsset(P_VCAM, tool == ToolsetConst$types$ghost$videoCamera);

	
	PP(0, set);
	set = [];

    onDataUpdate();
    
    string anim;
    if( llGetPermissions()&PERMISSION_TRIGGER_ANIMATION ){
        
        if( tool ){
            anim = "default_hold_better";
            
			integer on = getActiveToolInt();
            if( tool == ToolsetConst$types$ghost$parabolic )
                anim = "paramic_hold";
			else if( tool == ToolsetConst$types$ghost$thermometer )
                anim = "thermometer_hold";
			else if( tool == ToolsetConst$types$ghost$hornybat )
				anim = "bat_idle";
			else if( tool == ToolsetConst$types$ghost$spiritbox )
				anim = "spiritbox_hold";
			else if( tool == ToolsetConst$types$ghost$owometer )
				anim = "emf_hold";
			else if( tool == ToolsetConst$types$ghost$flashlight )
				anim = "flashlight_hold";
			else if( tool == ToolsetConst$types$ghost$hots )
				anim = "default_hold_up";
			else if( tool == ToolsetConst$types$ghost$glowstick ){
			
				anim = "glowstick_hold";
				if( !on )
					anim += "_off";
				
			}
			else if( tool == ToolsetConst$types$ghost$weegieboard )
				anim = "default_hold";
			
        }
            
        
        if( curAnim != anim ){
            
            if( curAnim )
                llStopAnimation(curAnim);
            if( anim )
                llStartAnimation(anim);
            
            curAnim = anim;
        } 

    }
    
    
}

int dropTool(){
	
	key id = getActiveToolWorldId();
	//qd(id + BFL_USING );
	if( id == "" || BFL&BFL_USING )
		return FALSE;
		
	list rc = getRcPlacement(FALSE);
	//qd(rc);
	if( rc == [] )
		return FALSE;
	
	vector vr = llRot2Euler(llGetRootRotation());
	vr = <0,0,vr.z>;
		
	
	// qd("Raising level evt");
	Level$raiseEvent( 
		LevelCustomType$TOOLSET, 
		LevelCustomEvt$TOOLSET$drop, 
		id + l2v(rc, 0) + llEuler2Rot(vr)
	);
	return TRUE;
	
}

onTick(){
    
    integer type = activeType();
    integer toolInt = getActiveToolInt();
    if( type == ToolsetConst$types$ghost$parabolic ){
        
        key texture = "87aea93e-75df-8a53-a016-7e0497530e19";
        float between;
        
        if( SOUND_TIME > 0 && llGetTime()-SOUND_TIME < 6 ){
            
            vector pos = SOUND_SPOT;
            
            vector temp = (pos-llGetCameraPos())/llGetCameraRot(); 
            between = 1.0 - llFabs(llAtan2(temp.y,temp.x))/PI;
            between = llPow(between, 3);
            float dist = llVecDist(pos, llGetRootPosition());
            between *= (1.0-dist/10.0);
            if( between < 0 )
                between = 0;
            
            between *= 70;
            
        }
        
        string text = (string)between;
        integer p = llSubStringIndex(text, ".");
        text = llGetSubString(text, 0, p+1);
        if( between < 10 )
            text = "0"+text;
        
        PP( P_PARAMON, (list)
            PRIM_TEXTURE + 4 + texture + <0.0625,1,0> + <-0.46875+0.0625*(float)llGetSubString(text,0,0),0,0> + 0 +
            PRIM_TEXTURE + 5 + texture + <0.0625,1,0> + <-0.46875+0.0625*(float)llGetSubString(text,1,1),0,0> + 0 +
            PRIM_TEXTURE + 7 + texture + <0.0625,1,0> + <-0.46875+0.0625*(float)llGetSubString(text,-1,-1),0,0> + 0
        );
        
    }
	else if( type == ToolsetConst$types$ghost$thermometer && llGetTime()-TEMP_TIME > 2 ){
	
		// Request a reading
		TEMP_TIME = llGetTime();
		Nodes$getTempQuick( ToolSetMethod$temp );
	
	}
        
}


integer addTool( integer tool, list data, key id ){
    
    if( !count(data) )
        data = [0];
    
    integer i;
    for( ; i < count(TOOLS); i += TOOLSTRIDE ){
        
        integer n = (i+ACTIVE_TOOL*TOOLSTRIDE) % count(TOOLS);
        
        integer type = l2i(TOOLS, n);
        if( !type ){
            
            // Attach it here
            TOOLS = llListReplaceList(TOOLS, (list)tool + llList2List(data, 0, 0) + id, n, n+TOOLSTRIDE-1);
            
            if( n == ACTIVE_TOOL*TOOLSTRIDE )
                drawActiveTool();
				
			if( tool == ToolsetConst$types$ghost$motionDetector ){
				Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, id + 0 );
			}
            return TRUE;
            
        }
        
    }
    
    return FALSE;
}

removeToolById( key id ){
	
	integer pos = llListFindList(TOOLS, (list)id);
	if( pos == -1 )
		return;
		
	TOOLS = llListReplaceList(TOOLS, TTEMPLATE, pos-(TOOLSTRIDE-1), pos);
	drawActiveTool();
    
}


// Raycasts for a placement pos, returns empty on fail
// If wall is TRUE it only allows placement on vertical objects
// Otherwise it only allows horizontal
// Returns (vec)pos, (vec)normal
list getRcPlacement( integer wall ){
	
	rotation fwd = llGetRootRotation();
	vector base = llGetRootPosition()+<0,0,.5>;
	if( llGetPermissions() & PERMISSION_TRACK_CAMERA ){
		
		fwd = llGetCameraRot();
		if( llGetAgentInfo(llGetOwner()) & AGENT_MOUSELOOK )
			base = llGetCameraPos();
		
	}
	
	list ray = llCastRay(base, base+llRot2Fwd(fwd)*2.5, RC_DEFAULT + RC_DATA_FLAGS + (RC_GET_NORMAL|RC_GET_ROOT_KEY) );
	//qd("Fwd ray" + ray);
	if( l2i(ray, -1) < 1 )
		return [];
		
	// Prevents placement on interactive objects. Not graceful since it assumes $I is after D$. But it saves memory.
	//qd("");
	if( llSubStringIndex(prDesc(l2k(ray, 0)), "LEVEL") == -1 )
		return [];
		
	vector n = l2v(ray, 2);
	if( (n.z < .95 && !wall) || (wall && llFabs(n.z) > .05) )
		return [];
		
	return (list)l2v(ray, 1) + n;

}

resetTools(){

	ACTIVE_TOOL = 0;
	TOOLS = [];
	integer i;
    for(; i < ToolSetConst$MAX_ACTIVE; ++i )
        TOOLS += TTEMPLATE;
	drawActiveTool();
	
}


#include "ObstacleScript/begin.lsl"
onAttach( id )
    llResetScript();
end

handleTimer( "T" )
	onTick();
end

onStateEntry()

    resetTools();
    
    forLink( nr, name )
        
        if( name == "OWOMETER" )
            P_OWOMETER = nr;
        else if( name == "FLASHLIGHT" )
            P_FLASHLIGHT = nr;
        else if( name == "FLASHLIGHTBEAM" )
            P_FLASHLIGHTBEAM = nr;
        else if( name == "HOTS" )
            P_HOTS = nr;
        else if( name == "HOTSBALL" )
            P_HOTSBALL = nr;
        else if( name == "ECCHISKETCH" )
            P_ECCHISKETCH = nr;
        else if( name == "SPIRITBOX" )
            P_SPIRITBOX = nr;
        else if( name == "SALT" )
            P_SALT = nr;
        else if( name == "VAPE" )
            P_VAPE = nr;
        else if( name == "OUIJA" )
            P_OUIJA = nr;
        else if( name == "PILLS" )
            P_PILLS = nr;
        else if( name == "PIR" )
            P_PIR = nr;
        else if( name == "PIR_CAN" )
            P_PIR_CAN = nr;
        else if( name == "BAT" )
            P_BAT = nr;
        else if( name == "GSTICK" )
            P_GSTICK = nr;
        else if( name == "PARA" )
            P_PARA = nr;
        else if( name == "PARAMON" )
            P_PARAMON = nr;
		//else if( name == "CAM" )
        //    P_CAM = nr;
		else if( name == "VCAM" )
			P_VCAM = nr;
        else if( name == "THERMO" )
            P_THERMO = nr;
        else if( name == "PLANCHETTE" )
            P_PLANCHETTE = nr;
        else if( name == "TPOST" )
			P_THERMO_POSTIT = nr;
    end
    
    setInterval("T", 1);
    
    if( llGetAttached() )
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION|PERMISSION_TRACK_CAMERA);
    
	C_TOOL = -1;
	drawActiveTool();
    // Facelight
    PP(P_FLASHLIGHT, (list)PRIM_POINT_LIGHT + 1 + <1.000, 0.928, 0.710> + .1 + 1.5 + 0.5);
    
    llSetAlpha(0, ALL_SIDES);
    //addTool(ToolsetConst$types$ghost$flashlight, (list)0, "");
	//addTool(ToolsetConst$types$ghost$owometer, (list)0, "");
	//addTool(ToolsetConst$types$ghost$spiritbox, (list)1, "");
	
	#ifdef DEBUG_TOOL
	addTool(DEBUG_TOOL, (list)
		#ifdef DEBUG_TOOL_DATA
			DEBUG_TOOL_DATA
		#else
			0
		#endif
		, 
	"");
	#endif
	
    
	llListen(3, "", llGetOwner(), "");
	llListen(1432, "", "", "");
	
	llRegionSay(1432, "TOOL_ONLINE");
	Portal$scriptOnline();
	
	llSleep(.5);
	Com$updatePortal();
	Level$raiseEvent( LevelCustomType$TOOLSET, LevelCustomEvt$TOOLSET$get, [] );    
	
end

onGhostToolData( data, uuid )

	integer pos = llListFindList(TOOLS, (list)uuid);
	if( ~pos ){
	
		TOOLS = llListReplaceList(TOOLS, (list)data, pos-1, pos-1);
		if( ACTIVE_TOOL*TOOLSTRIDE == pos-2 ){
			onDataUpdate();
		}
		
	}

end

// USE
onPortalLclickStarted( hud )

	integer tool = activeType();
	if( !tool || BFL&BFL_USING )
		return;
		
	str outData;
		
    list toggled = (list)
        ToolsetConst$types$ghost$owometer +
        ToolsetConst$types$ghost$spiritbox +
        ToolsetConst$types$ghost$parabolic +
		ToolsetConst$types$ghost$thermometer
    ;
    if( tool == ToolsetConst$types$ghost$glowstick ){
		
		str data = getActiveToolStr();
		int on = (int)j(data, 0);
		int brightness = (int)j(data, 1);
	
        // Can't interact yet
        if( (int)on && brightness > 25 )
			return;
        
		if( on )
			outData = "re";
			
		BFL = BFL|BFL_USING;
		float to = 1.5;
		if( on )
			to = 3;
        setTimeout("USE", to);
		// Set to on and 100%
		data = "[1,100]";
        setActiveToolVal(data);
        onDataUpdate();
        Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + data ); // Set it to 100%. Going down to 0%
		drawActiveTool();
		
    }
	
	if( tool == ToolsetConst$types$ghost$flashlight ){
		
		list d = llJson2List(getActiveToolStr());
		integer v = !l2i(d, 0);
		str out = mkarr(llListReplaceList(d, (list)v, 0,0));
        setActiveToolVal(out);
        onDataUpdate();
        llTriggerSound("691cc796-7ed6-3cab-d6a6-7534aa4f15a9", .5);
        // Tell level
        Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + out );
		
    }
    
    if( ~llListFindList(toggled, (list)tool) ){
    
        integer v = !getActiveToolInt();
        setActiveToolVal(v);
        onDataUpdate();
        llTriggerSound("691cc796-7ed6-3cab-d6a6-7534aa4f15a9", .5);
        // Tell level
        Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + v );

        
    }
	
	if( tool == ToolsetConst$types$ghost$vape ){
        
        BFL = BFL|BFL_USING;
        setTimeout("USE", 3);
		setTimeout("DESTROY", 2.5);
		Level$raiseEvent(LevelCustomType$TOOLSET, LevelCustomEvt$TOOLSET$vape, []);
				
    }
	
	if( tool == ToolsetConst$types$ghost$pills ){
        
        BFL = BFL|BFL_USING;
        setTimeout("USE", 3.5);
		Level$raiseEvent( LevelCustomType$TOOLSET, LevelCustomEvt$TOOLSET$pills, []);
		setTimeout("DESTROY", 3);
				
    }
	/*
	if( tool == ToolsetConst$types$ghost$camera ){
		
		int pics = getActiveToolInt();
		if( pics >= GhostHelper$CAM_MAX_PICS )
			return;
	
		++pics;
		setActiveToolVal(pics);
        onDataUpdate();
		
		Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + pics );
		Level$raiseEvent(LevelCustomType$TOOLSET, LevelCustomEvt$TOOLSET$camera, llGetCameraPos() + llGetCameraRot());
		
		BFL = BFL|BFL_USING;
		setTimeout("USE", 1);
	
	}
	*/
	if( tool == ToolsetConst$types$ghost$salt ){
			
		int ch = getActiveToolInt();
		if( ch >= GhostHelper$SALT_MAX_CHARGES )
			return;
			
		list rc = getRcPlacement(FALSE);
		if( rc == [] )
			return;
		
		vector norm = l2v(rc, 1);
		rotation r = llRotBetween(<0,0,1>, norm);

		++ch;
		setActiveToolVal(ch);
        onDataUpdate();
		Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + ch );
		Level$raiseEvent(LevelCustomType$TOOLSET, LevelCustomEvt$TOOLSET$salt, l2v(rc, 0) + r);
		
		BFL = BFL|BFL_USING;
		setTimeout("USE", 1);
		if( ch >= GhostHelper$SALT_MAX_CHARGES )
			setTimeout("DESTROY", 0.2);
			
		
	}
	
	if( 
		tool == ToolsetConst$types$ghost$hots || 
		tool == ToolsetConst$types$ghost$ecchisketch || 
		tool == ToolsetConst$types$ghost$videoCamera || 
		tool == ToolsetConst$types$ghost$hornybat 
	){
		
		if( tool == ToolsetConst$types$ghost$hots ){
			Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + 1 );
		}
		dropTool();
		
	}
	
	if( tool == ToolsetConst$types$ghost$motionDetector ){
		
		list rc = getRcPlacement(TRUE);
		if( rc == [] )
			return;
			
		vector norm = l2v(rc, 1);
		rotation r = llEuler2Rot(<PI_BY_TWO, 0, 0>)*llEuler2Rot(<0,0,PI_BY_TWO>)*llRotBetween(<1,0,0>, norm);
		
		Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, getActiveToolWorldId() + 1 );
		BFL = BFL|BFL_USING;
		setTimeout("USE", 1);
		
		Level$raiseEvent( 
			LevelCustomType$TOOLSET, 
			LevelCustomEvt$TOOLSET$drop, 
			getActiveToolWorldId() + l2v(rc, 0) + r
		);
	
	}
	
	raiseEvent(ToolSetEvt$visual, tool + outData);

end

onRunTimePermissions( perm )

    if( perm & PERMISSION_TRIGGER_ANIMATION )
        drawActiveTool();
		
	if( perm & PERMISSION_ATTACH && DT )
		llDetachFromAvatar();
    
end

// Hotkeys
onListen( ch, msg )

	if( ch == 1432 && llGetOwnerKey(SENDER_KEY) == llGetOwner() && msg == "TOOL_ONLINE" ){
			
		if( llGetAttached() ){
			DT = TRUE;
			llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
		}
		else
			llDie();
		
	}
	
	if( ch != 3 )
		return;
	
	// Cycle asset
	if( msg == "sheathe" && ~BFL&BFL_USING ){
		
		ACTIVE_TOOL = (ACTIVE_TOOL+1) % ToolSetConst$MAX_ACTIVE;
		
		drawActiveTool();
		
	}
	
	else if( msg == "Q" ){
		
		key id = getActiveToolWorldId();
		int type = activeType();
		if( type == ToolsetConst$types$ghost$hots )
			Level$raiseEvent( LevelCustomType$GTOOL, LevelCustomEvt$GTOOL$data, id + 0 );	
			
		dropTool();
	
	}

end

handleMethod( ToolSetMethod$hotTemps )
	
	vector vr = llRot2Euler(llGetRot());
	vector as = llGetAgentSize(llGetOwner());
	llRezAtRoot(
		"HotTemps", 
		llGetPos()+<0,0,as.z*.4>+llRot2Fwd(llEuler2Rot(<0,0,vr.z>))*.1, 
		ZERO_VECTOR, 
		llEuler2Rot(<0,0,vr.z>), 
		1
	);

end

handleMethod( ToolSetMethod$addTool )
	
	addTool(argInt(0), llList2List(METHOD_ARGS, 1, 1), argKey(2));
	
end

handleMethod( ToolSetMethod$reset )
	
	resetTools();
	
end

handleMethod( ToolSetMethod$remTool )
	
	removeToolById(argKey(0));
	
end

handleTimer( "USE" )

    BFL = BFL&~BFL_USING;

end

handleTimer( "DESTROY" )

	Level$raiseEvent( 
		LevelCustomType$TOOLSET, 
		LevelCustomEvt$TOOLSET$destroy, 
		getActiveToolWorldId()
	);

end

// External interactions on our handheld items
handleMethod( ToolSetMethod$trigger )
	
	if( BFL&BFL_USING )
        return;
		
	int tool = argInt(0);
	METHOD_ARGS = llDeleteSubList(METHOD_ARGS, 0, 0);

	
    if( tool == ToolsetConst$types$ghost$parabolic ){
        
        SOUND_SPOT = argVec(0);
        SOUND_TIME = llGetTime();
		int triggerSound = argInt(1);
		
		if( triggerSound ){
		
			// Check angle between us and that
			prPosAngX(SOUND_SPOT, ang)
			
			// We can hear the sound if it's in front of us
			if( llFabs(ang) < PI_BY_TWO && activeType() == ToolsetConst$types$ghost$parabolic ){
				
				float dist = 1.0-llVecDist(llGetPos(), SOUND_SPOT)/5;
				if( dist < 0 )
					dist = 0;
				
				float vol = (1.0-llFabs(ang)/PI_BY_TWO)*.5 + dist;
				GhostInteractions$playSoundOnMe(SENDER_KEY, vol);
				
			}
				
        }
		
    }
	// Negative ouija meant it was used
	else if( tool == -ToolsetConst$types$ghost$weegieboard )
		raiseEvent(ToolSetEvt$visual, tool + METHOD_ARGS);
	
    
end

handleMethod( ToolSetMethod$temp )

	float t = argFloat(0);
	t -= llFloor(llFrand(4));
	
	if( getActiveToolInt() )
		t = (t * 9.0/5.0) + 32;
		
	str nr = (str)floor(t);
	while( llStringLength(nr) < 3 )
		nr = "0"+nr;
		
		
	list set;
	integer i;
	for(; i < 3; ++i ){
		
		set += (list)
			PRIM_TEXTURE +
			(3+i) +
			"2aaf7eb6-4ebb-52da-b32a-7e2d4d45c73d" +
			<1.0/16, 1, 0> + 
			<-0.46875+.0625*(int)llGetSubString(nr, i, i), 0, 0> + 
			0
		;
		
	}
	// The display doesn't use PBR
	llSetLinkPrimitiveParamsFast(P_THERMO, set);
	
end

handleTimer( "HUNT" )
	
	integer tool = activeType();
	if( tool == ToolsetConst$types$ghost$flashlight ){
	
		int on = floor(llFrand(2));
		int bright = (int)llFrand(50)+50;
		PP(
			P_FLASHLIGHTBEAM, 
			GhostHelper$getFlashlightLightSettings( on, bright )
		);
		PP(
			P_FLASHLIGHT,
			GhostHelper$getFlashlightFrontSettings( P_FLASHLIGHT, bright )
		);
		
	}
	
end

onGhostToolGhost( ghost, affixes, evidence, difficulty, type )
	AFFIXES = affixes;
	onDataUpdate();
end

onGhostToolHunt( hunting, ghost )
	
	if( hunting )
		setInterval("HUNT", 0.1);
	else{
		unsetTimer("HUNT");
		drawActiveTool();
	}
end


#include "ObstacleScript/end.lsl"





