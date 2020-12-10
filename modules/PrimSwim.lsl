


#define checkForceStop() FALSE

#define USE_STATE_ENTRY
#define USE_SENSOR
#define USE_NO_SENSOR
#define USE_TIMER
#include "ObstacleScript/index.lsl"




string wl_preset;
string wl_set;

key PH;                            // Cache for particle helper
integer PCHAN;

// Timers
float timerSpeed;
float SSM = 1;                    // SwimSpeedMulti PrimSwimMethod$swimSpeedMultiplier

#define SURFACE_DEPTH -.4
#define FOOTSTEP_SPEED .4


#define BFL_IN_WATER 1
#define BFL_SWIMMING 2              // Actively swimming
#define BFL_CAM_UNDER_WATER 4
#define BFL_FULLY_SUBMERGED 8
#define BFL_FEET_SUBMERGED 16
#define BFL_WITHIN_20M_OF_WATER 32
//#define BFL_STOP_ANIMATION 64       // Stop swimming because of effect
#define BFL_HAS_WET_FEET 256
#define BFL_CONTROLS_TAKEN 512
#define BFL_AT_SURFACE 1024
integer BFL;


integer BFA;                        // Anims bitfield
#define BFA_IDLE 1
#define BFA_ACTIVE 2

#define TIMER_SWIM_CHECK "a"
#define TIMER_WETFEET_FADE "b"
#define TIMER_SPEEDCHECK "c"
#define TIMER_SWIMSTROKE "d"
#define TIMER_FOOTSPLASH "e"
#define TIMER_COUT_CHECK "g"

integer BF_COMBAT;
#define BFC_RECENT_ATTACK 1
#define BFC_ATTACK_LINEDUP 2


// Checks if the object the script is in is intersecting id and returns the surface Z coordinate at that location
float waterZ(vector userPos, key id, integer inverse){
        vector vPos = userPos;
        
        list d = llGetObjectDetails(id, [OBJECT_POS, OBJECT_ROT]);
        vector gpos = llList2Vector(d,0);
        if(gpos == ZERO_VECTOR)return -1;
        rotation grot = llList2Rot(d,1);
        list bb = llGetBoundingBox(id);
        
        vector v1 = llList2Vector(bb,0);
        vector v2 = llList2Vector(bb,1);
        
        vPos = vPos-gpos;
        
        float fTemp;
        // Order in size so v2 is always greater
        if (v1.x > v2.x){fTemp = v2.x;v2.x = v1.x;v1.x = fTemp;}
        if (v1.y > v2.y){fTemp = v2.y;v2.y = v1.y;v1.y = fTemp;}
        if (v1.z > v2.z){fTemp = v2.z;v2.z = v1.z;v1.z = fTemp;}
        
        // Adjust the point to object rotation
        vPos/=llList2Rot(d,1);
        if (vPos.x < v1.x || vPos.y < v1.y || vPos.z < v1.z || vPos.x > v2.x || vPos.y > v2.y || vPos.z > v2.z)return 0;
        
        vector scale = <v2.x-v1.x, v2.y-v1.y, v2.z-v1.z>*.5;
        if(inverse)scale.z=-scale.z;
        vector offset = userPos-gpos;
        offset.z = 0;
        offset*=grot;
        offset.z+=scale.z;
        float ret = gpos.z+offset.z;
        return ret;
}


// -1 = is submerged
// 0 = not submerged (linden air)
// anything else = global Z for where bubble begins
float pointSubmerged(vector point){

    integer i; float submerged = 0;
    float s; float vs;
    for(i=0;i<llGetListLength(water);i++){
        if((vs = waterZ(point,llList2Key(water,i), FALSE))>0){
            submerged = -1;
            i = 9000;
        }
    }
    
    for(i=0; i<llGetListLength(airpockets); i++){
    
        if((s=waterZ(point, llList2Key(airpockets, i), TRUE))>0)
            return s;
        
    }
     
    return submerged;
    
}

updateAnimstate(){

    integer bf_start;
    integer bf_stop;
    integer sitting = llGetAgentInfo(llGetOwner())&AGENT_SITTING;
    integer forceStop = checkForceStop();
    integer override;
    #ifdef USE_SCRIPT_RUNNING_CHECK
        override = !scriptRunning();
    #endif
    
    if(BFL&BFL_IN_WATER && !sitting && !forceStop && !override){
        if(~BFA&BFA_IDLE){
            bf_start = bf_start|BFA_IDLE;
            BFA = BFA|BFA_IDLE;
        }
    }else if(BFA&BFA_IDLE){
        bf_stop = bf_stop|BFA_IDLE;
        BFA = BFA&~BFA_IDLE;
    }
        
    if(BFL&BFL_SWIMMING && !sitting && !forceStop && !override){
        if(~BFA&BFA_ACTIVE){
            bf_start = bf_start|BFA_ACTIVE;
            BFA = BFA|BFA_ACTIVE;
        }
    }else if(BFA&BFA_ACTIVE){
        bf_stop = bf_stop|BFA_ACTIVE;
        BFA = BFA&~BFA_ACTIVE;
    }
    
    
    
    if( bf_start != 0 ){

        if( bf_start&BFA_IDLE )
            AnimHandler$start(LINK_SET, PrimSwimCfg$animIdle);
        if( bf_start&BFA_ACTIVE )
            AnimHandler$start(LINK_SET, PrimSwimCfg$animActive);

    }
    if(bf_stop != 0){

        if( bf_stop&BFA_IDLE )
            AnimHandler$stop(LINK_SET, PrimSwimCfg$animIdle);
        if( bf_stop&BFA_ACTIVE )
            AnimHandler$stop(LINK_SET, PrimSwimCfg$animActive);
          
    }
    
}


enterWater(){

    #ifdef USE_SCRIPT_RUNNING_CHECK
        if(!scriptRunning())
            return;
    #endif

    BFL = BFL|BFL_IN_WATER;
    BFL=BFL&~BFL_FEET_SUBMERGED;
    setBuoyancy();
    float vel = llVecMag(llGetVel());
    int weight = 0;
    if( vel>8 ){
        llTriggerSound(PrimSwimCfg$splashBig, 1.);
        weight = 2;
    }
    else if( vel>5 ){
        llTriggerSound(PrimSwimCfg$splashMed, 1.);
        weight = 1;
    }
    else 
        llTriggerSound(PrimSwimCfg$splashSmall, 1);
    
    vector gpos = llGetRootPosition();
    gpos.z = deepest+0.05;
    raiseEvent(PrimSwimEvt$waterEntered, weight + gpos);

    //dif=llGetVel()*.25;
    prePush=llGetVel()*.1;
    pp=.75;
    
    setInterval(TIMER_COUT_CHECK, .5);
    
}

exitWater(){
    
    // Just exited water
    CONTROL = 0;
    unsetTimer(TIMER_SWIMSTROKE);
    llStopMoveToTarget();
    BFL=BFL&~BFL_IN_WATER;
    BFL=BFL&~BFL_AT_SURFACE;
    BFL=BFL&~BFL_SWIMMING;
    BFL=BFL&~BFL_FULLY_SUBMERGED;
    
    raiseEvent(PrimSwimEvt$waterExited, "");
    

    triggerRandomSound([PrimSwimCfg$soundExit], .5, .75);
    setBuoyancy();
    // Diving soundspace
    Soundspace$dive(FALSE);
    
    toggleCam(FALSE);
    wl_set = "";
    
    unsetTimer(TIMER_COUT_CHECK);
    
}

#if PrimSwimCfg$USE_WINDLIGHT==1
toggleCam(integer submerged){

    #ifdef USE_SCRIPT_RUNNING_CHECK
        if(!scriptRunning())
            return;
    #endif
    if(!isset(wl_set))return;
    if(submerged){
    
        BFL = BFL|BFL_CAM_UNDER_WATER;
        
        Rlv$setWindlight(LINK_ROOT, wl_set);
        
    }
    else{
    
        BFL = BFL&~BFL_CAM_UNDER_WATER;
        Rlv$setWindlight(LINK_ROOT, "");
        
    }
    
}
#else
    #define toggleCam(input)
#endif

float buoyancy_default = 0;
setBuoyancy(){

    float b = buoyancy_default;
    if(BFL&BFL_IN_WATER)b = .9;
    llSetBuoyancy(b);
    
}

vector ascale;
integer CONTROL;
list water;
list airpockets;
float deepest;
vector prePush;
float pp;

#define debug( text ) \
    llSetText((str)(text), <1,1,1>, 1);

timerEvent( string id ){
        

    
    // Core frame
    if(id == TIMER_SWIM_CHECK){
    
        integer stopped = checkForceStop();
        integer ainfo = llGetAgentInfo(llGetOwner());
        integer i;
        deepest = 0;
        #ifndef RC_DEFAULT
        list RC_DEFAULT = (list)RC_REJECT_TYPES + (RC_REJECT_AGENTS|RC_REJECT_PHYSICAL);
        #endif
        
        
        for( ; i<llGetListLength(water) && llGetListLength(water); ++i ){
        
            key wID = llList2Key(water,i);
            
            vector gpos = llGetRootPosition();
            
            float is = pointSubmerged(<gpos.x,gpos.y,gpos.z+ascale.z/2>); // Checks if feet are submerged, or if there's an airbubble.

            // Point is not an air bubble
            if( is ==-1 || is == 0 )
                is = waterZ(llGetRootPosition(), wID, FALSE);    // Get the water surface Z position at this location
            
            if( is > deepest )
                deepest = is;
            
            // How far below the water the top of your head is. If negative, it means your head is out of the water.
            float depth = is-(gpos.z+ascale.z/2);
            
            
            
            // Check for bottom
            list ray = llCastRay(gpos-<0,0,ascale.z/2-.1>,gpos-<0,0,ascale.z>, [RC_REJECT_TYPES,RC_REJECT_AGENTS]);
            vector bottom;
            if( llList2Integer(ray,-1) > 0 )
                bottom = llList2Vector(ray,1);
            
            // Handle camera
            vector pos = llGetCameraPos();
            if( pointSubmerged(pos) != 0 && (~BFL&BFL_AT_SURFACE || ~ainfo&AGENT_MOUSELOOK) ){
            
                if( ~BFL&BFL_CAM_UNDER_WATER )
                    toggleCam(TRUE);
                    
            }else if( BFL&BFL_CAM_UNDER_WATER )
                 toggleCam(FALSE);
            
            
            integer water_just_entered = FALSE;
            integer atSurface = TRUE;
            // Head is above the surface
            if( depth > 0 )
                atSurface = FALSE;

            

            // The water has been deleted, object no longer found
            if( is == -1 ){
                
                water = llDeleteSubList(water,i,i);
                i--; 
                
            }
            // We are not fully submerged. But might be standing in water
            else if( depth < SURFACE_DEPTH ){
            
                is = waterZ(gpos-<0,0,ascale.z/2>, wID, FALSE);
                if( is > deepest )
                    deepest=is;
                
            }
            // We are fully submerged
            else if( depth > SURFACE_DEPTH || atSurface ){
                
                if( i > 0 ){ // INDEX THIS WATER
                
                    water = [wID]+llDeleteSubList(water, i, i);
                    i=0;
                    
                }  
                
                vector turb; vector tan;
                
                list dta = llGetObjectDetails(wID, [OBJECT_DESC, OBJECT_ROT, OBJECT_POS]);
                string desc = llList2String(dta,0);
                rotation oRot = llList2Rot(dta,1);
                
                vector stream; 
                float cyclone; 
                float ssm; 
                wl_set = "Nacon's nighty fog";
                
                list split = llParseString2List(desc, ["$$"], []);
                list_shift_each(split, val, 
                
                    list s = llParseString2List(val, ["$"], []);
                    string t = llList2String(s, 0);
                    
                    if( t == Desc$TASK_WATER ){
                        
                        stream = (vector)llList2String(s,1);
                        cyclone = llList2Float(s,2);
                        ssm = llList2Float(s,3);
                        if( llGetListLength(s) > 4 )
                            wl_set = llList2String(s,4);
                            
                    }
                    
                    
                )
                
                
                if( ~ainfo&AGENT_SITTING ){
                
                    if( stream )
                        turb = stream*llList2Rot(dta,1);
                        
                    if( cyclone ){
                        vector oPos = llList2Vector(dta,2);
                        
                        vector dif = (gpos-oPos)/oRot;
                        float dist = llVecDist(<oPos.x,oPos.y,0>,<gpos.x,gpos.y,0>);
                        
                        float atan = llAtan2(dif.y,dif.x);
                        vector pre = <llCos(atan),llSin(atan),0>*oRot*dist;
                        atan+=cyclone*5*DEG_TO_RAD;
                        vector add = <llCos(atan),llSin(atan),0>*oRot*dist;
                        tan = add-pre;
                    }
                    
                }
                
                vector dif; vector vel = llGetVel(); 
                if( ~BFL&BFL_IN_WATER ){ // Just entered water
                
                    enterWater();
                    water_just_entered = TRUE;
                    
                }
                

                // Calculate direction
                if( CONTROL && !stopped && ~ainfo&AGENT_SITTING ){
                
                    vector fwd; vector left; vector up;
                    if( CONTROL&(CONTROL_FWD|CONTROL_BACK) )
                        fwd = llRot2Fwd(llGetCameraRot());
                    if( CONTROL&CONTROL_BACK )
                        fwd=-fwd;
                    if( CONTROL&(CONTROL_LEFT|CONTROL_RIGHT) )
                        left = llRot2Left(llGetCameraRot());
                    if( CONTROL&CONTROL_RIGHT )
                        left=-left;
                        
                    if( CONTROL&CONTROL_UP )
                        up = <0,0,1>;
                    else if( CONTROL&CONTROL_DOWN )
                        up = <0,0,-1>;

                        dif=llVecNorm(fwd+left+up);
                    
                    // At surface
                    if( atSurface && dif.z > -.5 )
                        dif.z = 0;
                    
                    dif = llVecNorm(dif);
                    
                    if( ainfo&AGENT_ALWAYS_RUN )
                        dif*=1.5;
                        
                    // Used for soft slowdown
                    prePush = dif;   
                    pp = 1.;
                    
                }
                // Calculate pre-push. Not sure waht this is
                else if( pp > 0 ){
                
                    pp-=.1;
                    if( pp>0 )
                        dif = prePush*(1-llSin(PI_BY_TWO+pp*PI_BY_TWO))*.5;
                    if( water_just_entered )
                        dif*=4;
                    
                }
                
                
                // Swim sound
                if(
                    ~ainfo&AGENT_SITTING && 
                    !stopped && 
                    (
                        CONTROL&(CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_DOWN) || 
                        (CONTROL&CONTROL_UP&&~BFL&BFL_AT_SURFACE) || 
                        llVecMag(<dif.x,dif.y,0>) > .5
                    )
                ){ 
                
                    if( ~BFL&BFL_SWIMMING ){
                        
                        BFL=BFL|BFL_SWIMMING;
                        triggerRandomSound([PrimSwimCfg$soundStroke], .5, .75);
                        setInterval(TIMER_SWIMSTROKE, 1.);
                        
                    }
                    
                }
                else if( BFL&BFL_SWIMMING ){
                    
                    unsetTimer(TIMER_SWIMSTROKE);
                    BFL=BFL&~BFL_SWIMMING;
                    
                }
                
                if( ssm <= 0 )
                    ssm = 1;
                
                vector SP = gpos;

                float sprint = (( llGetAgentInfo(llGetOwner()) & (AGENT_ALWAYS_RUN|AGENT_WALKING) ) == (AGENT_ALWAYS_RUN|AGENT_WALKING));
                if( sprint == 0 && llGetAgentInfo(llGetOwner()) & AGENT_ALWAYS_RUN )
                    sprint = -0.6;


                float mag = llVecMag(dif); // Calculate the magnitude before messing with it

                // Surface detect
                integer SUB = TRUE;
                // Unless pivoting heavily down, set SP.z to the surface
                if( depth <= 0 && !water_just_entered && dif.z>-.1 && atSurface ){
                
                    // Then set to swim at surface level
                    if( bottom.z+ascale.z > depth+SURFACE_DEPTH ){
                    
                        SP.z = is-SURFACE_DEPTH-.1-ascale.z*.5;
                        dif.z = 0;
                        BFL = BFL|BFL_AT_SURFACE;
                        
                    }
                    else{
                        BFL = BFL&~BFL_AT_SURFACE;
                    }
                    SUB = FALSE;
                    
                }
                else {
                
                    BFL = BFL&~BFL_AT_SURFACE;
                    
                    
                }
                
                integer B;    // We're bottoming out at our current position, so only use XY
                // Check if we're at the bottom, in that case only move on XY
                ray = llCastRay(gpos, gpos-<0,0,ascale.z*.75>, RC_DEFAULT);
                if( l2i(ray, -1) == 1 && dif.z < 0 ){
                    B = true;
                    dif.z = 0;
                }
                
                vector a = dif;
                float b = a.z;
                a.z = 0;
                
                // XY and Z have different speeds
                dif = (llVecNorm(dif)*ssm*SSM*(1+sprint*.5))*.75;
                dif += turb+tan;
                
                
                SP+=dif*mag;
                
                
                // XY checking isn't needed because we're moving relative to our current position
                
                // BOttoming out is calculated from the position we want to go to, not where we're at
                ray = llCastRay(SP, SP-<0,0,ascale.z*.6>, RC_DEFAULT);
                if( l2i(ray, -1) == 1 ){
                
                    // We are at the bottom
                    vector v = l2v(ray, 1);
                    SP.z = v.z+ascale.z*.6;
                    dif.z = 0;
                    
                }
            
                
                //llSetText((str)B+"\n"+(str)SP+"\n"+(str)dif+"\n"+(str)llGetTime(), <1,1,1>, 1);
                
                                
                float t = .5;
                if( water_just_entered )
                    t=2;
                    
                if( !stopped ){
                    llMoveToTarget(SP, t);
                }
                
                // HANDLES DIVING SOUNDS
                if( SUB ){ // Entire body is submerged
                    
                    if( ~BFL&BFL_FULLY_SUBMERGED ){
                        
                        // Dive
                        BFL=BFL|BFL_FULLY_SUBMERGED;
                         Soundspace$dive(TRUE);
                        
                    }
                    
                }
                else if( BFL&BFL_FULLY_SUBMERGED ){
                
                    // Emerge
                    llTriggerSound(PrimSwimCfg$soundSubmerge, .5);
                    
                    Soundspace$dive(FALSE);
                    BFL=BFL&~BFL_FULLY_SUBMERGED;
                    vector pos = gpos;
                    pos.z = deepest;
                    list ray = llCastRay(pos+<0,0,.1>, pos-<0,0,.2>, [
                        RC_REJECT_TYPES, RC_REJECT_AGENTS|RC_REJECT_PHYSICAL, 
                        RC_DATA_FLAGS, RC_GET_NORMAL|RC_GET_ROOT_KEY, 
                        RC_DETECT_PHANTOM,TRUE, 
                        RC_MAX_HITS,3
                    ]);
                    integer ri;
                    rotation rot;
                    for( ;ri<l2i(ray,-1)*3; ri+=3 ){
                        if( l2k(ray, ri) == wID ){
                            vector norm = l2v(ray, ri+2);
                            vector axis = <1,0,0>;
                            rot = norm2rot(norm, axis);
                            pos += <0,0,.05>*rot;
                            ray = [];
                        }
                    }
                    
                    partCom(PrimSwimParticles$emerge, [pos, rot]);
                    
                }
                
                updateAnimstate();
                setTimer(id, timerSpeed);
                // We are submerged, let's return
                return;
                
            }
            
            
            
        }
        
        
            
        if( deepest > 0 || BFL&BFL_IN_WATER ){
            
            if(~BFL&BFL_FEET_SUBMERGED){

                BFL=BFL|BFL_FEET_SUBMERGED;
                BFL=BFL|BFL_HAS_WET_FEET;
                
                setInterval(TIMER_FOOTSPLASH, FOOTSTEP_SPEED);
                if(deepest>0)
                    unsetTimer(TIMER_WETFEET_FADE);
                raiseEvent(PrimSwimEvt$feetWet, 1);
                
            }
            
        }
        else if( BFL&BFL_FEET_SUBMERGED ){
        
            BFL=BFL&~BFL_FEET_SUBMERGED;
            setTimer(TIMER_WETFEET_FADE, 30);
            
        }
        
        // Couldn't find
        if( BFL&BFL_IN_WATER )
            exitWater();
            
        updateAnimstate();
        setTimer(id,timerSpeed);
        
    }
    
    // Removes wet feet
    else if( id == TIMER_WETFEET_FADE ){
    
        BFL = BFL&~BFL_HAS_WET_FEET;
        raiseEvent(PrimSwimEvt$feetWet, 0);
        unsetTimer(TIMER_FOOTSPLASH);
        
    }
    
    else if(id == TIMER_SPEEDCHECK){ // Dynamic timer speed
    
        setInterval(TIMER_SPEEDCHECK, 4);
        
        if(BFL&BFL_IN_WATER){
        
            if(~BFL&BFL_WITHIN_20M_OF_WATER){
            
                BFL=BFL|BFL_WITHIN_20M_OF_WATER;
                timerSpeed = PrimSwimCfg$maxSpeed;
                setTimer(TIMER_SWIM_CHECK,timerSpeed);
                
            }
            return;
            
        }
        else{
        
            vector gpos = llGetRootPosition();
            integer i; 
            for(i=0; i<llGetListLength(water); i++){
                vector pos = llList2Vector(llGetObjectDetails(llList2Key(water,i), [OBJECT_POS]), 0);
                if(llVecDist(pos,gpos)<30){ 
                    if(~BFL&BFL_WITHIN_20M_OF_WATER){
                        timerSpeed = PrimSwimCfg$maxSpeed;
                        setTimer(TIMER_SWIM_CHECK,timerSpeed);
                        BFL=BFL|BFL_WITHIN_20M_OF_WATER;
                    }
                    return;
                }
            }
            
        }
        
        if(BFL&BFL_WITHIN_20M_OF_WATER){
            timerSpeed = PrimSwimCfg$minSpeed;
            setTimer(TIMER_SWIM_CHECK, timerSpeed);
        }
        BFL=BFL&~BFL_WITHIN_20M_OF_WATER;
        
        
    }
 
    else if(id == TIMER_SWIMSTROKE){
        triggerRandomSound([PrimSwimCfg$soundStroke], .5, .75);
    }
    
    else if( id == TIMER_FOOTSPLASH ){
        
        if( ( deepest <=0 && ~BFL&BFL_HAS_WET_FEET ) || BFL&BFL_IN_WATER )
            return;

        // Splash sound
        integer ainfo = llGetAgentInfo(llGetOwner());
        vector gpos = llGetRootPosition();
        float depth = deepest-(gpos.z-ascale.z/2);
        
        
        
        if( ainfo&AGENT_WALKING ){
        
            // Trigger splash
            if( depth<.1 ){

                if( deepest <= 0 )
                    depth = 0;
                vector pos = <gpos.x,gpos.y,gpos.z-ascale.z/2+depth>;

                partCom(PrimSwimParticles$onFeetWetSplash, [0, pos]);
                triggerRandomSound(PrimSwimCfg$soundFootstepsShallow, .75,1);
                return;
                
            }
            else if( depth<.4 )
                triggerRandomSound(PrimSwimCfg$soundFootstepsMed, .75,1);
            else 
                triggerRandomSound(PrimSwimCfg$soundFootstepsDeep, .75,1);

            partCom(PrimSwimParticles$onFeetWetSplash, [1, <gpos.x,gpos.y,deepest>]);
        }
        
        


    }
    
}

partCom( string task, list data ){
    
    if( llKey2Name(PH) == "" )
        PrimSwimAux$spawn();
    else
        llRegionSayTo(PH, PCHAN, mkarr(task + data));
        
}

triggerRandomSound(list sounds, float minVol, float maxVol){
    llTriggerSound(llList2Key(sounds, floor(llFrand(llGetListLength(sounds)))), minVol+llFrand(maxVol-minVol));
}


#include "ObstacleScript/begin.lsl"


onControlsKeyPress( pressed, released )
    
    CONTROL = CONTROL | pressed;
    CONTROL = CONTROL &~ released;


end

onTimer( id )
    timerEvent(id);
end


onStateEntry()
    
    PCHAN = PrimSwimAuxCfg$partChan;
    llSetText("", ZERO_VECTOR, 0);
    ascale = llGetAgentSize(llGetOwner());
    llStopMoveToTarget();
    setBuoyancy();
    llSensor(PrimSwimCfg$pnWater, "", PASSIVE|ACTIVE, 90, PI);
    llSleep(1);
    setInterval(TIMER_SPEEDCHECK, .1);
    
    // Slow timer at start
    timerSpeed = PrimSwimCfg$minSpeed;
    setTimer(TIMER_SWIM_CHECK, timerSpeed);
        
    if( llGetInventoryType("PrimSwimAux") == INVENTORY_SCRIPT )
        llResetOtherScript("PrimSwimAux");
    if( llGetAttached() )
        llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
    memLim(1.5);

end

onSensor( total )

    integer i;
    for( ; i < total; ++i ){
        key id = llDetectedKey(i);
        if( llListFindList(water, [id])==-1 )
            water+=[id];
    }
    llSensorRepeat(PrimSwimCfg$pnWater, "", PASSIVE|ACTIVE, 90, PI, 5);

end

onNoSensor()

    llSensorRepeat(PrimSwimCfg$pnWater, "", PASSIVE|ACTIVE, 90, PI, 5);

end


handleInternalMethod( PrimSwimMethod$airpockets )
    airpockets = METHOD_ARGS;
end


handleInternalMethod( PrimSwimMethod$swimSpeedMultiplier )
    SSM = argFloat(0);
end


handleInternalMethod( PrimSwimMethod$particleHelper )
    PH = argStr(0);
end



#include "ObstacleScript/end.lsl"


