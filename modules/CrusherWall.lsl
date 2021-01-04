#define USE_STATE_ENTRY
#define USE_LISTEN
#include "ObstacleScript/index.lsl"

str ID = "0";
vector TRANS = <0,.8,0>;
float SPEED = 2.0;
integer FWD = TRUE;			// Gone to the back position

int BFL;
#define BFL_LOADED 0x1

vector startPos;

translate( integer fwd, integer pingPong ){
	
	llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
	vector scale = llGetScale();
	vector endPos = startPos+<
		scale.x*TRANS.x,
		scale.y*TRANS.y,
		scale.z*TRANS.z
	>*llGetRot();
	
	vector targPos = endPos;	// Endpos is retacted
	if( fwd )					// StartPos is extended
		targPos = startPos;
	
	float dist = llVecDist(startPos, endPos);
	float curDist = llVecDist(llGetPos(), targPos);
	float speed = curDist/dist*SPEED;
	
	vector goto = targPos-llGetPos();
	if( speed < 0.12 )
		speed = 0.12;

	if( curDist < 0.1 )
		return;
		
	integer mode = KFM_FORWARD;
	if( pingPong )
		mode = KFM_PING_PONG;
	
	llSetKeyframedMotion([goto, speed], [KFM_DATA, KFM_TRANSLATION, KFM_MODE, mode]);
	FWD = fwd;
	

}



#include "ObstacleScript/begin.lsl"

onStateEntry()

	Portal$scriptOnline();  // required for portal to function
	llListen(CrusherWallConst$CHAN, "", "", "");
    startPos = llGetPos();
	llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
	
end

onPortalLoadComplete( desc )

	list data = llJson2List(argStr(0));
	vector scale = (vector)l2s(data, 0);
	ID = l2s(data, 1);
	TRANS = (vector)l2s(data, 2);
	SPEED = l2f(data, 3);
	startPos = llGetPos();
	llSetScale(scale);
	
	BFL = BFL|BFL_LOADED;

end


onListen( chan, msg )
	
	if( llGetOwnerKey(SENDER_KEY) != llGetOwner() || ~BFL&BFL_LOADED )
		return;
		
	list data = llJson2List(msg);
	integer dir = l2i(data, 0);
	data = llDeleteSubList(data, 0, 0);

	if( llListFindList(data, (list)((str)ID)) == -1 )
		return;
		
	if( dir == CrusherWallConst$DIR_PING_PONG )
		translate(!FWD, TRUE);
	else if( dir == CrusherWallConst$DIR_FWD )
		translate(TRUE, FALSE);
	else if( dir == CrusherWallConst$DIR_BACK )
		translate(FALSE, FALSE);
	
end


#include "ObstacleScript/end.lsl"


