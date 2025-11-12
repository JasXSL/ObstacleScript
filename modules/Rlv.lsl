
#define USE_STATE_ENTRY
#define USE_TIMER
#define USE_LISTEN
#define USE_RUN_TIME_PERMISSIONS
#include "ObstacleScript/index.lsl"
#include "../shared/sound_registry.lsh"

#define TIMER_TICK "A" // Tick windlight
#define TIMER_SPRINT_CHECK "a"
#define TIMER_SPRINT_QUICK "b"
#define TIMER_SPRINT_START_REGEN "c"
#define TIMER_SPRINT_FADE "d"
#define TIMER_PULL_STOP "e"


integer BFL;
#define BFL_NO_UNSIT 0x1
#define BFL_SPRINTING 0x2
#define BFL_RUN_LOCKED 0x4
#define BFL_SPRINT_STARTED 0x8
#define BFL_UNLOCK_CAM_ON_E 0x10
#define BFL_IN_CAMERA 0x20
#define BFL_GRAIN 0x40

float OlFade = 1.0;

int SEX;	// Flags received from JasX HUD

// Public flags. See header file. There are two ints being combined:
int FLAGS;					// Used by obstacles
int FLAGS_IMPORTANT;		// Used by the game

float Immobile;			// If greater than script time, we auto add FLAG_IMMOBILE
int Rc;					// Redirecting chat to this

#define SPRINT_SIZE <0.22981, 0.06894, 0.02039>
#define SPRINT_POS <0, 0, .23>

string cFL; // Cache floor windlight
string cWL; // Cache windlight
key cPrim;  // Cache prim

string W_OR;    // Windlight override

list SLOTS = RlvConst$SLOTS;
list STATE = RlvConst$STATE;
// Outputs the windlight if it has changed
setWindlight( string preset ){
    
    if( cWL == preset )
        return;
    cWL = preset;
	/*
	if( BFL&BFL_GRAIN )	// cWL is force refreshed when grain effect ends
		return;
	*/
	if( preset == "" )
		llOwnerSay("@setenv_daytime:-1=force");
	else
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
        list data = getDescTask( desc, Desc$TASK_WL_PRESET );
        desc = l2s(data, 1);
        if( desc )
            cFL = desc;
        
    }
    
    setWindlight(cFL);
        
    
}


integer cSTATE = 682;	// cache clothing state (corresponds to SLOTS, 2-bit array where 0 is off, 1 underwear, 2 dressed) 682 = 0b1010101010 (fully dressed)
setDesc(){
	
	// Desc: (int)sex(jasx_flags), ...
	llSetObjectDesc((str)SEX+"$"+(str)cSTATE);

}


// FLAGS
onFlagsChanged(){
	
	int out = (FLAGS|FLAGS_IMPORTANT);
	if( llGetTime() < Immobile )
		out = out | RlvFlags$IMMOBILE;
	raiseEvent(RlvEvt$flags, out);

}






// Sprint
#define SPRINT_GRACE 3
float MAX_SPRINT = 4;
float sprint = MAX_SPRINT;
integer sprintPrim;
float sprintFadeModifier = 1;
float sprintRegenModifier = 1;
float camMaxDist = -1;
float lastCamMaxDist = -1;

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

	llLinkStopSound(hsr$rlv);
	llLinkStopSound(hsr$rlvLoop);
	
    setInterval(TIMER_TICK, 0.5);
    llListen(SupportCubeCfg$INIT_CHAN, "SupportCube", "", "");
	llListen(2, "", "", "");
	
	llOwnerSay("@clear");
	
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
	llRegionSayTo(llGetOwner(), 1, "jasx.settings");
    setDesc();
	
	if( llGetAttached() )
		llRequestPermissions(llGetOwner(), PERMISSION_CONTROL_CAMERA);
	
end

onRunTimePermissions( perm )
	if( perm & PERMISSION_CONTROL_CAMERA )
		llClearCameraParams();
end

onListen( chan, message )

	if( !(isEventByOwnerInline()) )
		return;
    
    if( chan == SupportCubeCfg$INIT_CHAN ){
            
        supportcube = SENDER_KEY;
        raiseEvent(RlvEvt$supportCubeSpawn, supportcube);
        cubeTask([]);
    
    }
	
	else if( chan == 2 ){
		
		if( llGetSubString(message, 0, 8) != "settings:" )
			return;
			
		message = llGetSubString(message, 9, -1);
		if( !(int)j(message, "id") )
			return;
			
		SEX = (int)j(message, "sex");
		setDesc();
		
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
    

handleTimer( TIMER_PULL_STOP )
	llStopMoveToTarget();
end





onControlsKeyPress( pressed, released )

	if( pressed&~released & CONTROL_UP  && BFL & BFL_UNLOCK_CAM_ON_E ){
		
		BFL = BFL&~BFL_UNLOCK_CAM_ON_E;
		runMethod(LINK_THIS, llGetScriptName(), RlvMethod$setCamera, []);
	
	
	}
	
end

handleMethod( RlvMethod$toggleNametags )
	string on = "y";
	if( !argInt(0) )
		on = "n";
	llOwnerSay("@shownametags="+(str)on);
end


handleMethod( RlvMethod$setCamera )
	
	if( ~llGetPermissions() & PERMISSION_CONTROL_CAMERA )
		return;
	
	
	vector pos = argVec(0);
	rotation rot = argRot(1);
	
	if( pos == ZERO_VECTOR ){
	
		if( BFL&BFL_UNLOCK_CAM_ON_E )
			Level$raiseEvent(LevelCustomType$RLV, LevelCustomEvt$RLV$cameraCleared, []);
	
		BFL = BFL&~BFL_UNLOCK_CAM_ON_E;
		BFL = BFL&~BFL_IN_CAMERA;
		if( BFL&BFL_GRAIN ){
			
			BFL = BFL&~BFL_GRAIN;
			Gui$setOverlay( LINK_THIS, GuiConst$OL_NONE );
			/*
			str wl = cWL;
			cWL = "";
			setWindlight(wl);
			*/
		}
		llClearCameraParams();
		runMethod(LINK_THIS, llGetScriptName(), RlvMethod$setCamMaxDist, lastCamMaxDist);
		
	}
	else{
				
		if( argInt(2) ){
		
			BFL = BFL|BFL_UNLOCK_CAM_ON_E;
			if( argInt(3) ){
				
				BFL = BFL | BFL_GRAIN;
				Gui$setOverlay( LINK_THIS, GuiConst$OL_NOISE );
				//llOwnerSay("@setenv_preset:7660a5c9-e1b7-4271-4ba3-ab509d1cb11e=force");
				
			}
				
		}
		
		lastCamMaxDist = camMaxDist;
		BFL = BFL|BFL_IN_CAMERA;
		llSetCameraParams((list)
			CAMERA_ACTIVE + TRUE +
			CAMERA_POSITION_LOCKED + TRUE +
			CAMERA_FOCUS_LOCKED + TRUE +
			CAMERA_POSITION + pos +
			CAMERA_FOCUS + (pos+llRot2Fwd(rot))
		);
		runMethod(LINK_THIS, llGetScriptName(), RlvMethod$setCamMaxDist, -1);
		runMethod(LINK_THIS, llGetScriptName(), RlvMethod$exitMouselook, false);
		
		
	}
	
	raiseEvent(RlvEvt$camera, pos + rot);
	
end

// Methods
handleMethod( RlvMethod$setClothes )
    
    integer n = argInt(0);
	cSTATE = n;
    integer i;
    for(; i < 5; ++i ){
        
        integer st = (n >> (i*2))&3;
        if( st ){
		
            --st;
			cSTATE = cSTATE &~ (3<<(i*2));
			cSTATE = cSTATE | (st << (i*2));
            llRegionSayTo(
                llGetOwner(), 
                1, 
                "jasx.setclothes "+l2s(STATE, st)+"/"+l2s(SLOTS, i)
            );
            
        }
        
    }
	
	setDesc();

end

handleMethod( RlvMethod$setOverlay )
	
	str texture = argStr(0);
	float alpha = argFloat(1);
	float dur = argFloat(2);
	OlFade = argFloat(3);
	if( alpha <= 0 )
		alpha = 1;
	unsetTimer("OL");
	if( texture == "" ){
		llOwnerSay("@setoverlay=y");
		return;
	}
	llOwnerSay("@setoverlay=n,setoverlay_texture:"+(str)texture+"=force,setoverlay_alpha:"+(str)alpha+"=force");
	if( dur > 0 )
		setTimeout("OL", dur);

end
handleTimer( "OL" )
	
	if( OlFade > 0 ){
		llOwnerSay("@setoverlay_tween:0;;"+(str)OlFade+"=force");
		return;
	}
	llOwnerSay("@setoverlay=y");
	
end

handleMethod( RlvMethod$toggleFreeCam )
	
	bool allow = argInt(0);
	str yn = "yn";
	llOwnerSay("@camunlock="+llGetSubString(yn, !allow, !allow));
	
end

handleMethod( RlvMethod$toggleFlying )

	bool allow = argInt(0);
	str yn = "yn";
	llOwnerSay("@fly="+llGetSubString(yn, !allow, !allow));
	
end

handleMethod( RlvMethod$setCamMaxDist )
	
	llOwnerSay("@camdistmax:"+(str)camMaxDist+"=y");
	camMaxDist = argFloat(0);
	if( camMaxDist >= 0 ){
		
		if( ~BFL&BFL_IN_CAMERA )
			llOwnerSay("@camdistmax:"+(str)camMaxDist+"=n");
		
	}
	
end

handleMethod( RlvMethod$setImmobile )

	unsetTimer("IM");

	float dur = argFloat(0);
	bool add = argInt(1);
	if( llGetTime() > Immobile )
		add = false;
	if( add )
		Immobile += dur;
	else if( dur > 0 )
		Immobile = dur + llGetTime();
	else
		Immobile = 0;
	onFlagsChanged();
	if( llGetTime() < Immobile )
		setTimeout("IM", Immobile-llGetTime());
	
end

handleTimer( "IM" )
	onFlagsChanged();
end

handleMethod( RlvMethod$disableChatLevels )
	
	#define bw2int(cn) !(levels&cn), !(levels&cn)
	int levels = argInt(0);
	str yn = "ny";
	list remadd = ["add","rem"];
	str text = 
		"@chatwhisper="+llGetSubString(yn, bw2int(RlvConst$dcl$whisper))+","+
		"chatnormal="+llGetSubString(yn, bw2int(RlvConst$dcl$normal))+","+
		"chatshout="+llGetSubString(yn, bw2int(RlvConst$dcl$shout))+","+
		"sendchat="+llGetSubString(yn, bw2int(RlvConst$dcl$all))+","+
		"recvchat="+llGetSubString(yn, bw2int(RlvConst$dcl$recAll))+","+
		"sendgesture="+llGetSubString(yn, bw2int(RlvConst$dcl$gesture))+","+
		"rediremote:10="+l2s(remadd,!(levels&RlvConst$dcl$emote))
	;
	llOwnerSay(text);

end

handleMethod( RlvMethod$redirectChat )
	
	int chan = argInt(0);
	bool enable = argInt(1);
	float dur = argFloat(2);
	
	
	unsetTimer("RC");
	
	str cmd = "@redirchat:"+(string)Rc+"=rem,redirchat:"+(str)chan+"=";
	if( enable )
		cmd += "add";
	else
		cmd += "rem";
	llOwnerSay(cmd);
	
	Rc = chan;
	if( dur > 0 )
		setTimeout("RC", dur);

end

handleTimer( "RC" )
	llOwnerSay("@redirchat:"+(str)Rc+"=rem");
end

handleMethod( RlvMethod$cubeTask )
    
    cubeTask(METHOD_ARGS);
    
end

handleMethod( RlvMethod$exitMouselook )
    
	bool inverse = argInt(0);
	bool always = argInt(1);
	
	llOwnerSay("@camdistmin:0=y");
	llOwnerSay("@camdistmax:0.1=y");
	if( inverse )
		llOwnerSay("@camdistmax:0=n,camdistmin:0=n");
	else
		llOwnerSay("@camdistmin:0.1=n");
		
	if( !always ){
		llSleep(.1);
		llOwnerSay("@camdistmax:0=y");
		llOwnerSay("@camdistmin:0.1=y");
    }
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
    llOwnerSay("@unsit=y,unsit=force");

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

handleMethod( RlvMethod$setFlags )
	
	if( argInt(1) )
		FLAGS_IMPORTANT = FLAGS_IMPORTANT|argInt(0);
	else
		FLAGS = FLAGS|argInt(0);
	
	onFlagsChanged();
	
end

handleMethod( RlvMethod$unsetFlags )
	
	if( argInt(1) )
		FLAGS_IMPORTANT = FLAGS_IMPORTANT&~argInt(0);
	else
		FLAGS = FLAGS&~argInt(0);
	
	onFlagsChanged();
	
end

handleMethod( RlvMethod$target )

	vector pos = argVec(0);
	float speed = argFloat(1);
	float dur = argFloat(2);
	if( dur <= 0 )
		dur = .1;
	
	if( pos == ZERO_VECTOR )
		pos = llGetRootPosition();
	
	llMoveToTarget(pos, speed);
	setTimeout(TIMER_PULL_STOP, dur);

end

handleMethod( RlvMethod$triggerSound )
	
	key sound = argKey(0);
	float vol = argFloat(1);
	key player = argKey(2);
	if( argStr(2) == "1" ){
	
		llLinkStopSound(hsr$rlv);
		llLinkPlaySound(hsr$rlv, sound, vol, SOUND_PLAY);
		
	}
	// Play sound on you that only another player can hear
	else if( player ){
		
		vector pos = prPos(player);
		vector p1 = <.1,.1,.1>;
		llTriggerSoundLimited(sound, vol, pos+p1, pos-p1);
		
	}
	else
		llTriggerSound(sound, vol);
	
end

handleMethod( RlvMethod$loopSound )
	
	key sound = argKey(0);
	float vol = argFloat(1);
	llLinkStopSound(hsr$rlvLoop);
	
	if( sound )
		llLinkPlaySound(hsr$rlvLoop, sound, vol, SOUND_LOOP);

end


#include "ObstacleScript/end.lsl"

