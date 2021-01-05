#define InteractCfg$ON_DESC handleDesc
#define InteractCfg$SOUND_ON_FAIL "ea0ab603-63f5-6377-21bb-552aa4ba334f"
#define InteractCfg$SOUND_ON_SUCCESS "31086022-7f9a-65d1-d1a7-05571b8ea0f2"



handleDesc( key id, string desc ){
    
    if( desc )
        desc = "[E] " + desc;
    
    llSetText(desc, <1,1,1>, 1);
    
}

#define USE_STATE_ENTRY
#define USE_TIMER
#define USE_SENSOR
#define USE_NO_SENSOR
#include "ObstacleScript/index.lsl"

#ifndef InteractCfg$ON_DESC
    #define onDesc(id, desc)
#else
    #define onDesc InteractCfg$ON_DESC
#endif

// TWEAKABLE VALUES  
// List of additional (string)keys to allow
list additionalAllow;
integer ALLOW_ALL_AGENTS;                // Makes all agents use a CUSTOM type interact, regardless of additionalAllow

integer BFL;
#define BFL_RECENT_CLICK 1              // Recently interacted
#define BFL_ALLOW_SITTING 0x2            // Allow when sitting

#define TIMER_RECENT_CLICK "c"

integer pInteract;

string targDesc;
key targ;
key real_key;                        // If ROOT is used, then this is the sublink. You can use this global in onInteract
integer held;

list NEARBY;




// Loads targ and targDesc into the global
fetchFromCamera(){

    targ = "";
    targDesc = "";

    if( llGetPermissions() & PERMISSION_TRACK_CAMERA ){
    
        integer ainfo = llGetAgentInfo(llGetOwner());
        if(~ainfo&AGENT_SITTING || BFL&BFL_ALLOW_SITTING){

            vector start;
            vector fwd = llRot2Fwd(llGetCameraRot())*3;
            
            if( ainfo&AGENT_MOUSELOOK )
                start = llGetCameraPos();
                
            else{
            
                vector apos = prPos(llGetOwner());
                rotation arot = prRot(llGetOwner());
                vector cpos = llGetCameraPos();
                rotation crot = llGetCameraRot();
                vector cV = llRot2Euler(crot);
                vector aV = llRot2Euler(arot);
                
                // Prevents picking up items behind you
                if( llFabs(cV.z-aV.z) > PI_BY_TWO )
                    return;
                
                // We can use cpos if camera is in front of avatar
                start = cpos;
                
                // If camera is behind the avatar. Then we must calculate where the avatar is and cast the ray from there
                vector temp = (cpos-apos)/arot; 
                if(llFabs(llAtan2(temp.y,temp.x))>PI_BY_TWO){
                
                    // Owner Position
                    vector C = apos;
                    // Owner Fwd (Z rotation only) ( aV = llRot2Euler( arot ); )
                    vector B = llRot2Fwd(llEuler2Rot(<0,0,aV.z>));
                    // Camera position
                    vector A = cpos;
                    // Camera fwd
                    vector av = llRot2Fwd(crot);
                    
                    // Prevent division by 0
                    if(B == av)
                        return;
                        
                    // Calculation
                    float div = (av*B);
                    if( div == 0 )
                        return;
                    start = (C-A)*B / div * av + A;
                    
                }
                
                //start = llGetRootPosition()+<0,0,ascale.z*.25>;
            }
            
            list ray = llCastRay(start, start+fwd, []);

            if( llList2Integer(ray,-1) > 0 && llVecDist(llGetRootPosition(), l2v(ray, 1)) < 2.5 ){
                
                key k = llList2Key(ray,0);
                
                if( 
                    ~llListFindList(additionalAllow, [(string)k]) || 
                    (llGetAgentSize(k) != ZERO_VECTOR && ALLOW_ALL_AGENTS) 
                ){
                
                    targ = llList2Key(ray,0);
                    targDesc = "CUSTOM";
                    return;
                    
                }
                    
                string td = prDesc(k);
                key real = k;
                #ifdef InteractCfg$USE_ROOT
                k = prRoot(k);
                #else
                if(td == "ROOT"){
                    k = prRoot(k);
                    td = prDesc(k);
                }
                #endif

                if(prRoot(llGetOwner()) != prRoot(k)){

                    list descparse = llParseString2List(td, ["$$"], []);
    
                    list_shift_each(descparse, val, {
                    
                        list parse = llParseString2List(val, ["$"], []);
                        if(llList2String(parse,0) == Desc$TASK_DESC){
                            targDesc = td;
                            targ = k;
                            real_key = real;
                            return;
                        }
                        
                    })
                    
                } 
                
            }

        }

    }
    
}

seek( list sensed ){
    
    

    sensed += additionalAllow;    // Add additionalAllow to sensed
    
    // Try raycast in camera direction first
    fetchFromCamera();
    
    

    // Fail
    if( !count(sensed) && targ == "" ){
        
        #ifdef PrimswimEvt$atLedge
        if( BFL&BFL_PRIMSWIM_LEDGE )
            targ = "_PRIMSWIM_CLIMB_";
        #endif
    
    }
    // No camera available but sensor picked up some
    else if( count(sensed) && targ == "" ){
    
        // ALGORITHMS!
        list scales;
        vector as = llGetAgentSize(llGetOwner());
        vector gp = llGetRootPosition();
        integer i;
        for( ; i<count(sensed); ++i ){
            
            vector pp = prPos(l2k(sensed, i));
            float dist = llVecDist(gp, pp);
            list ray = llCastRay(gp+<0,0,as.z*0.5>, pp, [RC_DATA_FLAGS, RC_GET_ROOT_KEY]);
            prAngX(l2k(sensed,i), ang)
            ang = llFabs(ang);
            if( (!l2i(ray, -1) || l2k(ray, 0) == l2k(sensed,i)) && (ang < PI/4 || dist < 1) && dist < 2 )
                scales += (list)(ang+dist) + l2k(sensed, i);
            
        }
        
        scales = llListSort(scales, 2, TRUE);
        targ = l2k(scales, 1);
        targDesc = prDesc(l2k(scales, 1));
        if( ~llListFindList(additionalAllow, (list)((string)targ)) )
            targDesc = "CUSTOM";
        
    }
    
    
        
    // Send description
    list d = split(targDesc, "$$");
    string dout = targDesc;
    list_shift_each(d, val, 
    
        list spl = split(val, "$");
        if( l2s(spl, 0) == "D" ){
            
            dout = l2s(spl, 1);
            d = [];
            
        }    
        
    )
    
    onDesc(targ, dout);
    
    

}






#include "ObstacleScript/begin.lsl"

onStateEntry()
    
    #ifdef InteractCfg$ALLOW_WHEN_SITTING
        BFL = BFL | BFL_ALLOW_SITTING;
    #endif

    llSetMemoryLimit(llGetUsedMemory()*2);
    if( llGetAttached() )
        llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
    llSensorRepeat("","",ACTIVE|PASSIVE,2.5,PI,0.25);
    //llSensor("","",ACTIVE|PASSIVE,3,PI);
    
end

onSensor( total )
    
    integer i;
    list near = [];
    for( ; i<total; ++i ){
        
        key id = llDetectedKey(i);
        if( 
            llGetSubString(prDesc(id), 0, 1) == "D$" && 
            !l2i(llGetObjectDetails(id, (list)OBJECT_PHANTOM), 0) 
        )near += id;
                        
    }
    
    seek(near);

end

onNoSensor()
    
    seek([]);

end

onControlsKeyPress( pressed, released )

    if(
        released & (CONTROL_UP
        #ifdef InteractCfg$ALLOW_ML_LCLICK
            | CONTROL_ML_LBUTTON
        #endif
        )
    ){
        if( BFL&BFL_RECENT_CLICK )
            return;
            
        BFL = BFL|BFL_RECENT_CLICK;
        float rate = 
        #ifdef InteractCfg$MAX_RATE
            rate = InteractCfg$MAX_RATE
        #else
            1
        #endif
        ;
        setTimeout(TIMER_RECENT_CLICK, rate);

        #ifndef InteractCfg$IGNORE_UNSIT
        integer ainfo = llGetAgentInfo(llGetOwner());
        if( ainfo&AGENT_SITTING ){
            
            Rlv$unSit(LINK_THIS, FALSE);
            return;
            
        }
        #endif
        
        
        list actions = llParseString2List(targDesc, ["$$"], []);
                
        if( !count(actions) ){
            
            #ifdef InteractCfg$SOUND_ON_FAIL
                llPlaySound(InteractCfg$SOUND_ON_FAIL, .25);
            #endif
            return;
            
        }
        
        integer successes;
        while( count(actions) ){
            
            string val = llList2String(actions,0);
            actions = llDeleteSubList(actions,0,0);
            list spl = split(val, "$");
            string task = llList2String(spl, 0); 
            spl = llDeleteSubList(spl, 0, 0);
            integer success = TRUE;
            
            
            if( task == Desc$TASK_TELEPORT ){
                
                vector to = (vector)llList2String(spl,0); 
                to += prPos(targ);
                Rlv$cubeTask(LINK_ROOT, SupportCubeBuildTeleport(to, l2s(spl, 1)));
                
            } 
            else if( 
                task == Desc$TASK_PLAY_SOUND || 
                task == Desc$TASK_TRIGGER_SOUND 
            ){
                
                key sound = llList2String(spl,0);
                float vol = llList2Float(spl,1);
                if( vol <= 0 )
                    vol = 1;
                    
                if( task == Desc$TASK_TRIGGER_SOUND )
                    llTriggerSound(sound, vol);
                else 
                    llPlaySound(sound, vol);
                    
            }
            else if( task == Desc$TASK_SIT_ON )
                Rlv$sit(LINK_THIS, targ, FALSE); 
            
            else if( task == Desc$TASK_CLIMB ){
                 
                Climb$start(targ, 
                    l2s(spl,0), // Rot offset 
                    l2s(spl,1), // Anim passive
                    l2s(spl,2), // Anim active
                    l2s(spl,3), // anim_active_down, 
                    l2s(spl,4), // anim_dismount_top, 
                    l2s(spl,5), // anim_dismount_bottom, 
                    l2s(spl,6), // nodes, 
                    l2s(spl,7), // Climbspeed
                    l2s(spl,8), // onStart
                    l2s(spl,9), // onEnd
					l2i(spl, 10) // Key filter
                );
                
            } 
            #ifdef InteractCfg$CUSTOM_CLICK
            else
                success = InteractCfg$CUSTOM_CLICK(targ, task, spl);
            #endif
            
            if( success ){
                
                raiseEvent(
                    InteractEvt$interact, 
                    real_key + task + spl 
                );
                
            }
            
            successes += success;
            
        }

        #ifdef InteractCfg$SOUND_ON_FAIL
        if( !successes )
            llPlaySound(InteractCfg$SOUND_ON_FAIL, .25);
        #endif
        #ifdef InteractCfg$SOUND_ON_SUCCESS
        if( successes )
            llPlaySound(InteractCfg$SOUND_ON_SUCCESS, .25);
        #endif
        
        
    }
end


handleMethod( InteractMethod$allowWhenSitting )

    if( argInt(0) )
        BFL = BFL|BFL_ALLOW_SITTING;
    else
        BFL = BFL&~BFL_ALLOW_SITTING;

end


handleTimer( TIMER_RECENT_CLICK )
    BFL = BFL&~BFL_RECENT_CLICK;
end

#include "ObstacleScript/end.lsl"




