#define USE_STATE_ENTRY
#define USE_HTTP_REQUEST
#define USE_CHANGED
#define USE_TIMER
#define USE_HTTP_RESPONSE
#include "ObstacleScript/index.lsl"

int P_BROWSER;
vector BROWSER_POS = <0.108420, -0.030550, 0.362426>;
vector BROWSER_SIZE = <0.803646, 0.373427, 0.103857>;

key urlReq;
string myUrl;
key pingReq;
key refreshReq;

int BFL;
#define BFL_BROWSER_OPEN 0x1

toggleBrowser(){

	if( BFL&BFL_BROWSER_OPEN )
		BFL = BFL&~BFL_BROWSER_OPEN;
	else
		BFL = BFL|BFL_BROWSER_OPEN;

	list data = (list)PRIM_POSITION + ZERO_VECTOR + PRIM_SIZE + ZERO_VECTOR;
	if( BFL & BFL_BROWSER_OPEN )
		data = (list)PRIM_POSITION + BROWSER_POS + PRIM_SIZE + BROWSER_SIZE;
	llSetLinkPrimitiveParamsFast(P_BROWSER, data);

	
}

initBrowser(){
	string url = BrowserConst$URL+"#"+myUrl;
	llSetLinkMedia(P_BROWSER, 0, (list)
		PRIM_MEDIA_CONTROLS + PRIM_MEDIA_CONTROLS_MINI +
		PRIM_MEDIA_CURRENT_URL + url +
		PRIM_MEDIA_HOME_URL + url +
		PRIM_MEDIA_WIDTH_PIXELS + 1024 +
		PRIM_MEDIA_HEIGHT_PIXELS + 512 +
		PRIM_MEDIA_PERMS_INTERACT + PRIM_MEDIA_PERM_OWNER +
		PRIM_MEDIA_PERMS_CONTROL + PRIM_MEDIA_PERM_OWNER +
		PRIM_MEDIA_FIRST_CLICK_INTERACT + TRUE +
		PRIM_MEDIA_AUTO_SCALE + TRUE
	);
	setInterval("PING", 1);
}

fetchNewUrl(){
	myUrl = "";
	urlReq = llRequestURL();
}

#include "ObstacleScript/begin.lsl"

onStateEntry()

	list set;
	links_each(nr, name,

		if( name == "BROWSER" ){
			P_BROWSER = nr;
			set += (list)PRIM_LINK_TARGET + P_BROWSER + PRIM_POS_LOCAL + ZERO_VECTOR + PRIM_SIZE + ZERO_VECTOR;
		}
		
	)
	llClearLinkMedia(P_BROWSER, 0);
	llSetLinkPrimitiveParamsFast(0, set);
	myUrl = llLinksetDataRead("HUD_URL");
	if( myUrl == "" )
		fetchNewUrl();
	else
		setInterval("PING", 1);
	//toggleBrowser();

end

onChanged( ch )
	if( ch & (CHANGED_OWNER|CHANGED_REGION) ){
		llLinksetDataDelete("HUD_URL");
		llResetScript();
	}
end

/*
	Expects:
	{
		"task" : (str)task,
		"args" : (arr)args
	}
	Returns:
	{
		"success" : (int)success,
		"data" : (arr)data
	}
*/
onHttpRequest( id, method, body )

	if( id == urlReq ){

		if( method == URL_REQUEST_GRANTED ){
			myUrl = body;
			llLinksetDataWrite("HUD_URL", myUrl);
			initBrowser();
		}else{
			llOwnerSay("Unable to fetch a browser URL, try again later or restart the sim!");
		}
		return;

	}

	//qd("Got request" + body);

	string task = j(body, "task");
	list args = llJson2List(j(body, "args"));
	integer success;
	list out;
	if( task == BrowserTask$ping ){
		success = true;
	}
	else if( task == BrowserTask$ini ){
		list levels; list cats;
		idbForeach(idbTable$SCENES, a, row)
			levels += row;
		end
		idbForeach(idbTable$CATEGORIES, b, row)
			cats += row;
		end
		
	
		out += (list)llList2Json(JSON_OBJECT, [
			"lv", mkarr(levels),
			"cat", mkarr(cats)
		]);
		success = true;
	}
	else if( task == BrowserTask$launch ){
		Scene$launch(l2s(args, 0));
		success = TRUE;
	}
	else if( task == BrowserTask$clean ){
		Scene$clean();
		success = TRUE;		
	}


	llSetContentType(id, CONTENT_TYPE_JSON);
	llHTTPResponse(id, 200, llList2Json(JSON_OBJECT, [
		"success", success,
		"data", mkarr(out)
	]));

end

onHttpResponse( id, status, body )
	
	if( id == refreshReq ){
		if( status != 200 ){
			qd("Failed to refresh HUD: "+body);
		}
		else if( j(body, "success") != JSON_TRUE ){
			qd("Failed to refresh HUD: "+j(body, "data"));
		}
		
		return;
	}

	else if( id == pingReq ){
		if( status != 200 ){
			//qd("Ping failed, retrying");
			fetchNewUrl();
		}
	}
end

handleTimer("PING")
	setInterval("PING", 60);
	pingReq = llHTTPRequest(myUrl, [
		HTTP_METHOD, "POST",
		HTTP_MIMETYPE, "application/json"
	], "{\"task\":\"Ping\"}");
end

// Controls
onControlsClick( linkName, nr, face )

	if( linkName == "LOGO" )
		toggleBrowser();
	else if( nr == P_BROWSER && face == 1 && BFL & BFL_BROWSER_OPEN )
		toggleBrowser();

end

handleInternalMethod( BrowserMethod$refresh )

	refreshReq = llHTTPRequest(BrowserConst$API, [
		HTTP_METHOD, "POST",
		HTTP_MIMETYPE, "application/json",
		HTTP_VERIFY_CERT, FALSE		// Todo: This can be enabled later. Looks like SL is lagging behind on validating the cert.
	], llList2Json(JSON_OBJECT, [
		"task", "WSFwd",
		"hud", myUrl,
		"args", mkarr("Refresh")
	]));
	
end


#include "ObstacleScript/end.lsl"


