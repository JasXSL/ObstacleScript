#define USE_STATE_ENTRY
#define USE_TIMER
#include "ObstacleScript/index.lsl"

// Left right falling gage
int P_GAUGE_MAIN;
int P_GAUGE_COG;
int P_GAUGE_BG;

#define GAUGE_SCALE <0.07255, 0.25704, 0.01000>
#define GAUGE_ROT <0.500000, -0.500000, -0.500000, 0.500000>
#define GAUGE_COG_SCALE <0.04331, 0.04331, 0.01264>
#define GAUGE_BG_SCALE <0.48364, 0.24182, 0.05972>
#define GAUGE_POS <-0.040878, 0.000870, 0.690880>
#define GAUGE_BG_OFFS <0.034790, 0.000000, 0.087647>

integer ACTIVE_QTE; // Active type of QTE
#define QTE_OFF 0
#define QTE_GAUGE QteConst$QTE_GAUGE

str CALLBACK;

// QTE Specific:
float GAGE_POS; // When it hits 1 or 0 you fail


integer KEYS_PRESSED;

// Multipurpose timers
#define TIMER_TICK "a"
                        // Gauge = move gauge left/right

setQTE( integer qte ){
    
    if( qte == ACTIVE_QTE && qte )
        return;
        
    // Hide QTEs
    llSetLinkPrimitiveParamsFast(0, (list)
        PRIM_LINK_TARGET + P_GAUGE_MAIN +
        PRIM_POSITION + ZERO_VECTOR + PRIM_SIZE + ZERO_VECTOR +
        PRIM_LINK_TARGET + P_GAUGE_COG +
        PRIM_POSITION + ZERO_VECTOR + PRIM_SIZE + ZERO_VECTOR +
        PRIM_LINK_TARGET + P_GAUGE_BG +
        PRIM_POSITION + ZERO_VECTOR + PRIM_SIZE + ZERO_VECTOR
    );
    
    unsetTimer(TIMER_TICK);
    
    ACTIVE_QTE = qte;
    
    if( qte == QTE_GAUGE ){
        
        llSetLinkPrimitiveParamsFast(0, (list)
            PRIM_LINK_TARGET + P_GAUGE_MAIN +
            PRIM_POSITION + GAUGE_POS + PRIM_SIZE + GAUGE_SCALE +
            PRIM_ROT_LOCAL + <0.500000, -0.500000, -0.500000, 0.500000> +
            PRIM_LINK_TARGET + P_GAUGE_COG +
            PRIM_POSITION + GAUGE_POS + PRIM_SIZE + GAUGE_COG_SCALE +
            PRIM_LINK_TARGET + P_GAUGE_BG +
            PRIM_POSITION + (GAUGE_POS+GAUGE_BG_OFFS) + PRIM_SIZE + GAUGE_BG_SCALE
        );
        
        setInterval(TIMER_TICK, .25);
        GAGE_POS = 0.5;
        
    }    
    
    if( qte ){
        
        Level$raiseEvent( 
            LevelCustomType$QTE, 
            LevelCustomEvt$QTE$start, 
            qte + CALLBACK
        );
        raiseEvent(QteEvt$start, qte);
        
    }
    
}

failQTE(){
    
    setQTE(0);
    raiseEvent(QteEvt$end, 0);
    Level$raiseEvent( LevelCustomType$QTE, LevelCustomEvt$QTE$end, FALSE + CALLBACK);
    
}

completeQTE(){
    
    setQTE(0);
    raiseEvent(QteEvt$end, 0);
    Level$raiseEvent( LevelCustomType$QTE, LevelCustomEvt$QTE$end, TRUE + CALLBACK);
    
}




#include "ObstacleScript/begin.lsl"

onStateEntry()

    links_each(nr, name,
        
        list spl = split(name, ":");
        if( l2s(spl, 0) == "QTE" && l2s(spl, 1) == "GAUGE" ){
            
            if( l2s(spl, 2) == "COG" )
                P_GAUGE_COG = nr;
            else if( l2s(spl, 2) == "MAIN" )
                P_GAUGE_MAIN = nr;
            else if( l2s(spl, 2) == "BG" )
                P_GAUGE_BG = nr;
            
        }
        
    ) 

    setQTE(0);

end


handleTimer( TIMER_TICK )

    if( ACTIVE_QTE == QTE_GAUGE ){
    
        integer dir = 1;
        if( GAGE_POS < 0.5 )
            dir = -1;
            
        GAGE_POS += (llFrand(.025)+0.025)*dir;
        
        integer left = (KEYS_PRESSED & (CONTROL_LEFT|CONTROL_ROT_LEFT)) > 0;
        integer right = (KEYS_PRESSED & (CONTROL_RIGHT|CONTROL_ROT_RIGHT)) > 0;
        
        if( left+right == 1 ){
                        
            float dist = GAGE_POS;
            float offs = 0.05;
            if( left ){
                offs = -offs;
                dist = -(1.0-GAGE_POS);
            }
                        
            
            GAGE_POS += dist*0.1+offs;
            
        }
        
        if( GAGE_POS > 1 || GAGE_POS < 0 ){
            
            failQTE();
            return;
            
        }
        
        float perc = 1.0-GAGE_POS*2;
        if( GAGE_POS > 0.5 )
            perc = -(GAGE_POS*2.0-1.0);
        
        float ANG = 60;
        llSetLinkPrimitiveParamsFast(P_GAUGE_MAIN, (list)
            PRIM_ROT_LOCAL + (llEuler2Rot(<0,0,perc*ANG*DEG_TO_RAD>)*GAUGE_ROT)
        );
        
        
    }

end


onControlsKeyPress( pressed, released )
    KEYS_PRESSED = KEYS_PRESSED|pressed;
    KEYS_PRESSED = KEYS_PRESSED &~released;
end












handleMethod( QteMethod$start )
    
    CALLBACK = argStr(1);
    setQTE(argInt(0));

end

handleMethod( QteMethod$end )
    if( argInt(0) )
        completeQTE();
    else
        failQTE(); 
end


#include "ObstacleScript/end.lsl"

