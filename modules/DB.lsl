// Use #define REST_TOKEN as a very long password
// Use #define REST_URL for your REST API endpoint

#define USE_STATE_ENTRY
#define USE_TIMER
#define USE_HTTP_RESPONSE
#define USE_LISTEN
#include "ObstacleScript/index.lsl"

// Objects that have permissions to alter your dbs
list PERMS;     // (key)object, (arr)dbs
integer nREQS = 20;

key req( str task, list data ){
    
    return llHTTPRequest(REST_URL, [
        HTTP_METHOD, "POST",
        HTTP_MIMETYPE, "application/x-www-form-urlencoded"
    ], 
        "task="+llEscapeURL(task)+
        "&args="+llEscapeURL(llList2Json(JSON_ARRAY, data))+
        "&uuid="+llEscapeURL(llGetOwner())+
        "&token="+llEscapeURL(REST_TOKEN)
    );

}
#define setData(game, data, merge) \
    req("SetData", (list)(game) + (data) + (merge))
#define getData(game) \
    req("GetData", (list)(game))

#define REQSTRIDE 5
list REQS;  // req_id, sender_id, sender_script, cbMethod, game

integer isRequesting( key uuid ){
    
    integer i;
    for(; i < count(REQS); i += REQSTRIDE ){
        
        if( llGetOwnerKey(l2k(REQS, i+1)) == uuid )
            return TRUE;
                                
    } 
    
    return FALSE;
    
}

respond( integer reqIndex, list cbData ){
    
    key id = l2k(REQS, reqIndex+1);
    str script = l2s(REQS, reqIndex+2);
    int method = l2i(REQS, reqIndex+3);
    str game = l2s(REQS, reqIndex+4);
    runMethod(id, script, method, game + cbData);
    REQS = llDeleteSubList(REQS, reqIndex, reqIndex-1+REQSTRIDE);
    
}

// Checks if sender is out of requests, and responds if they are, returning false.
integer checkNumReqs( key sender, str script, integer method, str cb ){
    
    if( isRequesting(llGetOwnerKey(sender)) || !nREQS ){
        
        runMethod(sender, script, method, 
            cb + JSON_NULL + "_TOO_MANY_REQUESTS_"
        );
        return FALSE;

    }
    return TRUE;
}


// Checks if sender is out of requests, and responds if they are, returning false.
integer checkDbPerms( key sender, str script, integer method, str table ){
    
    integer pos = llListFindList(PERMS, (list)sender);
    integer success;
        
    if( ~pos ){
        list tables = llJson2List(l2s(PERMS, pos+1));
        success = ~llListFindList(tables, (list)table);        
    }
        
    if( !success )
        runMethod(sender, script, method, 
            table + JSON_NULL + "_PERMS_"
        );
    return success;
    
}

list INC_PERMS; // uuid, scriptName, cbMethod, (arr)dbs


#include "ObstacleScript/begin.lsl"

onStateEntry()

    setInterval("REQ", 25);
    llListen(1313, "", llGetOwner(), "");

end

handleTimer( "REQ" )
    nREQS = 20;
end

handleOwnerMethod( DBMethod$setData )
    
    str cbScript = argStr(0);
    int cbMethod = argInt(1);
    str game = argStr(2);
    str data = argStr(3);
    int merge = argInt(4);
    
    if( !checkNumReqs(SENDER_KEY, cbScript, cbMethod, game) )
        return;
    
    if( !checkDbPerms(SENDER_KEY, cbScript, cbMethod, game) )
        return;
        
    
    
    --nREQS;
    REQS += (list)
        setData(game, data, merge) +
        SENDER_KEY +
        cbScript +
        cbMethod
    ;

end

onListen( chan, message )
    
    if( (message == "Agree" || message == "Decline") && count(INC_PERMS) ){
        
        if( message == "Agree" ){
            
            // Remove old perms
            key id = l2k(INC_PERMS, 0);
            int pos = llListFindList(PERMS, (list)id);
            if( ~pos )
                PERMS = llDeleteSubList(PERMS, pos, pos+1);

            // overwrite
            PERMS += (list)id + l2s(INC_PERMS, 3);
            runMethod(id, l2s(INC_PERMS, 1), l2i(INC_PERMS, 2), []);
            
        }
            
        INC_PERMS = [];
        
    }

end

handleOwnerMethod( DBMethod$reqPermissions )
    
    str cbScript = argStr(0);
    int cbMethod = argInt(1);
    str dbs = argStr(2);
    
    integer pos = llListFindList(PERMS, (list)SENDER_KEY);
    if( ~pos ){
        
        // perms already granted
        if( dbs == l2s(PERMS, pos+1) ){
            
            runMethod(SENDER_KEY, cbScript, cbMethod, []);
            return;
        }
        
    }
    
    string diag = "secondlife:///app/objectim/"+(str)SENDER_KEY+"?name="+llKey2Name(SENDER_KEY)+"&owner="+(str)llGetOwnerKey(SENDER_KEY) + " has requested write permissions to the following xMod DBs: "+llList2CSV(llJson2List(dbs));
    
    llDialog(llGetOwner(), diag, ["Agree", "Decline"], 1313);
    INC_PERMS = (list)SENDER_KEY + cbScript + cbMethod + dbs;

end

handleMethod( DBMethod$getData )
    
    str cbScript = argStr(0);
    int cbMethod = argInt(1);
    str game = argStr(2);
    
    if( !checkNumReqs(SENDER_KEY, cbScript, cbMethod, game) )
        return;
    
    --nREQS;
    
    REQS += (list)
        getData(game) +
        SENDER_KEY +
        cbScript +
        cbMethod
    ;
    

end

onHttpResponse( id, status, body )

    integer call = llListFindList(REQS, (list)id);
    if( call == -1 )
        return;
    
    if( status != 200 ){
        respond(call, [JSON_NULL, "_INTERNAL_ERROR_"]);
        return;
    }
    
    if( j(body, "success") != JSON_TRUE ){
        
        respond(call, [JSON_NULL, "_INTERNAL_ERROR_"]);
        
        if( llJsonValueType(body, (list)"error") == JSON_ARRAY )
            llOwnerSay("API errors: "+mkarr(j(body, "error")));
        
        return;
    }
    
    respond(call, [j(body, "data")]);
    
end


#include "ObstacleScript/end.lsl"



