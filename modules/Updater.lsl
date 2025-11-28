/*

#define Updater$adminKey "<your secret key>"
	
*/
#define USE_STATE_ENTRY
#define USE_HTTP_RESPONSE
#define USE_ON_REZ

#include "ObstacleScript/index.lsl"

key versionFetch;       // Req version
key updateFetch;        // Req updated HUD

// returns true if no error was found
integer handleError( integer status, string body ){
    
    if( status != 200 ){
        llOwnerSay("Updater response code error: ("+(string)status+")"+body);
        return FALSE;
    }
    
    if( j(body, "success") != JSON_TRUE ){
        llOwnerSay("Updater error: "+j(body, "data"));
        return FALSE;
    }
    
    return TRUE;
    
}

key makeReq( string task, list args ){
    
    return llHTTPRequest(BrowserConst$API, [
        HTTP_METHOD, "POST", 
        HTTP_MIMETYPE, "application/json",
        HTTP_VERIFY_CERT, FALSE // Todo: Enable this when SL gets its shit together
    ], llList2Json(JSON_OBJECT, [
        "task", task,
        "args", mkarr(args)
    ]));


}

#include "ObstacleScript/begin.lsl"
    onRez( num )
        llResetScript();
    end
    
    onStateEntry()
        versionFetch = makeReq("InitHud", []);
    end
    
    onHttpResponse( id, status, body )
        
        if( id == versionFetch ){
            
            if( !handleError(status, body) )
                return;
            body = j(body, "data");
            
            int serverVersion = (int)j(body, "version");
            list desc = split(llGetObjectName(), " ");
            int version;
            int i;
            for( ; i < count(desc); ++i ){
                version = l2i(desc, i);
                if( version )
                    desc = [];
            }
            
            if( serverVersion > version ){
                llOwnerSay("New version available ("+(string)serverVersion+")! Sending an update!");          
                versionFetch = makeReq("DeliverHud", [Updater$adminKey, llGetOwner()]);
                
            }
            
        }
        
        if( id == updateFetch ){
            if( !handleError(status, body) )
                return;
            
        }
    
    end
    
#include "ObstacleScript/end.lsl"


