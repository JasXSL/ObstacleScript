#define USE_STATE_ENTRY
#define USE_TIMER
#define USE_ON_REZ
#define USE_HTTP_RESPONSE
#include "ObstacleScript/index.lsl"

#ifndef SERVER
	#define SERVER "https://vibhub.io/"
#endif

int reqs = 20;
key lastReq;
key capFetch;

float minCap = 0.5;
string deviceID;
int capBits = 8;
string cVersion;		// Cache version to detect device

// Helper function that converts a float to be in the range of minVal and maxVal
int minMax( float in ){
	if( in <= 0 )
		return 0;
	int maxInt = (1 << capBits) - 1;
	int minInt = llFloor(maxInt * minCap);
	int dif = llFloor(llAbs(maxInt-minInt));
	return llRound(in*dif)+minInt;
}

string updateRandObject( string randObj ){

	if( j(randObj, "abs") != JSON_INVALID )
		return llJsonSetValue(randObj, (list)"abs", JSON_DELETE);
	float v = (float)j(randObj, "min");
	if( v > 0 )
		randObj = llJsonSetValue(randObj, (list)"min", (str)minMax(v));
	v = (float)j(randObj, "max");
	if( v > 0 )
		randObj = llJsonSetValue(randObj, (list)"max", (str)minMax(v));
	return randObj;
}

fetchCapabilities(){

	if( deviceID == "" ){
		llOwnerSay("No device ID, call VibHub$setDevice(deviceID) first!");
		return;
	}
	idbSet(idbTable$VIBHUB, idbTable$VIBHUB$capabilities, "");
	capFetch = llHTTPRequest(SERVER+"api/?id="+llEscapeURL(deviceID)+"&type=whois&data="+llEscapeURL("[]"), [], "");
}

onCapChange(){
	
	string caps = j(VibHubGet$capabilities(), "capabilities");
	if( caps == JSON_INVALID )
		return;
		
	capBits = (int)j(caps, "h");
	if( !capBits )
		capBits = 8;
	
	string version = j(VibHubGet$capabilities(), "hwversion");
	if( version != cVersion ){
	
		cVersion = version;
		string start = "Found " + version +" with "+(str)capBits+"-bit support!";
		if( version == "???" )
			start = "Device seems to be offline.";
		llOwnerSay(start);
		
	}

}


#include "ObstacleScript/begin.lsl"
onRez( nr ) llResetScript(); end

onStateEntry()

	setInterval("RST", 20);
	deviceID = VibHubGet$token();
	if( deviceID ){
		minCap = VibHubGet$minCap();
		onCapChange();
		fetchCapabilities();
	}
	setInterval("PING", 60);
	
end

handleTimer( "RST" )
	reqs = 20;
end

handleTimer( "PING" )
	if( !reqs || deviceID == "" )
		return;
	fetchCapabilities();
end

onHttpResponse( id, status, body )
	
	if( id == capFetch ){
		if( j(body, "success") != JSON_TRUE )
			qd("Cap fetch error: " + body);
		else{
			idbSet(idbTable$VIBHUB, idbTable$VIBHUB$capabilities, j(body, "message"));
			onCapChange();
			raiseEvent(VibHubEvt$capabilities, []);
		}
	}
	else if( id == lastReq ){
		if( j(body, "success") != JSON_TRUE )
			qd("Server error: " + body);
	}
end

handleInternalMethod( VibHubMethod$setMinCap )
	
	minCap = argFloat(0);
	idbSet(idbTable$VIBHUB, idbTable$VIBHUB$minCap, minCap);
	
end

handleInternalMethod( VibHubMethod$setDevice )
	
	deviceID = argStr(0);
	idbSet(idbTable$VIBHUB, idbTable$VIBHUB$token, deviceID);
	fetchCapabilities();
	
end

handleInternalMethod( VibHubMethod$runPrograms )
	
	if( !reqs ){
		llOwnerSay("You are updating programs too much! Slow down!");
		return;
	}
	
	if( deviceID == "" ){
		llOwnerSay("Set a device ID first with VibHub$setDevice(deviceID)!");
		return;
	}
	
	
	list programsArray = llJson2List(argStr(0));
	--reqs;
	
	integer program;
	for( ; program < count(programsArray); ++program ){
		
		string pData = l2s(programsArray, program);
		
		list stages = llJson2List(j(pData, "stages"));
		integer stage;
		for(; stage < count(stages); ++stage ){
			
			string sData = l2s(stages, stage);
			// Intensity
			string val = j(sData, "i");
			if( llJsonValueType(val, []) == JSON_OBJECT )
				val = updateRandObject(val);
			else if( val != JSON_FALSE )
				val = (str)minMax((float)val);
			sData = llJsonSetValue(sData, (list)"i", val);
			
			// Duration
			val = j(sData, "d");
			if( llJsonValueType(val, []) == JSON_OBJECT )
				sData = llJsonSetValue(sData, (list)"d", updateRandObject(val));
				
			// Repeats	
			val = j(sData, "r");
			if( llJsonValueType(val, []) == JSON_OBJECT )
				sData = llJsonSetValue(sData, (list)"r", updateRandObject(val));
				
			stages = llListReplaceList(stages, (list)sData, stage, stage);
			
		}
		pData = llJsonSetValue(pData, (list)"stages", mkarr(stages));
		if( capBits > 8 )
			pData = llJsonSetValue(pData, (list)"highres", JSON_TRUE);
		programsArray = llListReplaceList(programsArray, (list)pData, program, program);
	
	}
	
	//qd(mkarr(programsArray));
	
	
	
	lastReq = llHTTPRequest(SERVER+"api?id="+llEscapeURL(deviceID)+"&type=vib&data="+llEscapeURL(mkarr(programsArray)), [], "");
	

end


#include "ObstacleScript/end.lsl"
