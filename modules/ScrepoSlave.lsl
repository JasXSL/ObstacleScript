#include "ObstacleScript/index.lsl"
default{
    state_entry(){
        memLim(1.5);
    }

    link_message( integer link, integer nr, string s, key id ){
        
        if( id == llGetScriptName() && link == llGetLinkNumber() ){
            
            list spl = llJson2List(s);
            integer pin = l2i(spl, 0);
            string script = l2s(spl, 1);
            key targ = l2s(spl, 2);
            integer startParam = l2i(spl, 3);
            llRemoteLoadScriptPin(targ, script, pin, TRUE, startParam);
            llMessageLinked(LINK_THIS, 0, "LD", mkarr(targ + script));
			
        }
        
    }
}


