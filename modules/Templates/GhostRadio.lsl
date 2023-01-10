#define USE_STATE_ENTRY
#define USE_PLAYERS
#define USE_LISTEN
#define USE_ON_REZ
#include "ObstacleScript/resources/SubHelpers/GhostHelper.lsl"
#include "ObstacleScript/index.lsl"

str ID;
int AFFIXES;

integer BFL;
#define BFL_GARBLE 0x1

#include "ObstacleScript/begin.lsl"

onRez( total )
    llResetScript();
end
/*
onPlayersUpdated()
    qd("Players updated" + PLAYERS);
end
*/
onStateEntry()
    
    llListen(0, "", llGetOwner(), "");
    llListen(GhostRadioConst$CHAN, "", "", "");
    llListen(GhostRadioConst$REDIR_CHAN, "", llGetOwner(), "");
    
    Com$updatePortal();    
	
end

onGhostToolGhost( ghost, affixes, evidence, difficulty )
    AFFIXES = affixes;
end

onListen( ch, msg )

    if( hasWeakAffix(AFFIXES, ToolSetConst$affix$noRadios) )
        return;
    
    if( ch == 0 || ch == GhostRadioConst$REDIR_CHAN ){
        GhostRadio$message( "*", msg, ch == GhostRadioConst$REDIR_CHAN );
        return;
    }
    
    str oKey = llGetOwnerKey(SENDER_KEY);
    if( !isPlayer(oKey) )
        return;

    list data = llJson2List(msg);
    if( l2s(data, 0) != "*" && l2s(data, 0) != ID )
        return;
    
    integer task = l2i(data, 1);
    data = llDeleteSubList(data, 0, 1);
    
    float garbleChance = 0.025;
    
    if( task == GhostRadioTask$message ){
        
        str sender = llGetDisplayName(oKey);
        str message = l2s(data, 0);
        int targDead = l2i(data, 1);
        
        float dist = llVecDist(llGetPos(), prPos(SENDER_KEY));
        if( dist < 10 && !targDead )
            return;
            
        
        list sounds = (list)
            "4df45586-ddac-ff90-4abc-d4554782b4a6" +
            "a800dff4-fd26-a8b5-ff44-e44aa56d649e" +
            "f6bbd34a-eaee-dce4-ac77-f0b2792804a1" +
            "8f868a8c-0cf1-c416-de5b-481b2534f309"
        ;
        
        if( BFL & BFL_GARBLE ){
            
            sounds = (list)
                "48be50bc-a972-7640-9caa-d9bc39f6a8ca" +
                "f4336b26-d2e1-6dd3-1e4d-3b9ea56c316a" +
                "46ba4c48-d746-d96f-233a-b4e41b893c86" +
                "a7f99ca0-c800-e74b-ff87-ac5f94d9d432"
            ;
            sender = "???";
            garbleChance = 0.5;
            
        }
        
        if( targDead )
            garbleChance = 0.2;
        
        // Add static on the line
        int i;
        int len = llStringLength(message);
        string charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-----------------------";
        int csl = llStringLength(charset);
        
        for(; i < len; ++i ){
            
            if( llFrand(1.0) < garbleChance && llGetSubString(message, i, i) != " " ){
                
                message = llDeleteSubString(message, i, i);
                integer ch = floor(llFrand(csl));
                message = llInsertString(message, i, llGetSubString(charset, ch, ch));
                
            }
            
        }
        
        llRegionSayTo(llGetOwner(), 0, "["+sender+"] "+message);
        
        vector rp = llGetRootPosition();
        vector v = <.1,.1,.1>;
        llTriggerSoundLimited(randElem(sounds), 0.25, rp+v, rp-v);
        
    }
    else if( task == GhostRadioTask$garble ){
        
        BFL = BFL&~BFL_GARBLE;
        if( l2i(data, 0) )
            BFL = BFL|BFL_GARBLE;
    
    }
    
        
        

    
end


#include "ObstacleScript/end.lsl"



