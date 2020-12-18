/*
	Folder structure:
	- headers : Contains headers and event definitions for modules
				The script name in SL should be the same as the script name in the directory
				The script name should have a capital first letter
	- local : Contains headers for LSL events, such as timers etc. 
				Event definitions for these are stored in this file since they all use "" as sender
				Local doesn't use capital letters at the start of the script name
	- modules : Contains fully built modules
	- resources : Tools, asset libraries, and macros


	Naming:
	- USE : Enables new functionality in the code. Syntax: USE_<SCRIPTNAME>
	- event & method handlers : on/handle<scriptName><evtName> - Ex: onInteractiveInteract. local evts don't have a scriptname so they use onStateEntry or onTimer etc
		- on is used when defining the argument as a variable. Such as onTimer(id) - Creates str id with the ID of the timer that was triggered
		- handle is used when the argument is used as a filter. Such as handleTimer(id) - Only triggers when the id of the timer is the same as the argument
	
	- event idents: ScriptEvt$<evtName> - Ex: ComEvt$receive. Local evts are defined in this script with only evt. These event identifiers are usually abstracted away into the handler above
	- event conditions : <scriptName>Cond$<conditionName> - Ex: ComCond$listenIsOwner(). Local events don't use the script name. Ex Cond$listenIsOwner
	- methods : <scriptName>Method$<methodName> - Ex ComMethod$send
	- method macros : <scriptName>$<methodName> - Ex Com$send()
	- config defines: <scriptName>Cfg$confName - Ex ComCfg$something 
	- script constants: <scriptName>$CONST_NAME Ex Rlv$BITS
	- helpers: <scriptName>Helper$methodName - Ex PortalHelper$getConf()
	
	Link message definition:
	nr : (int)event
	str : (key)sender + JSON data passed to event
	id : target_script or "" for ALL
	
	Macros with lists can usually accept multiple arguments concatenated as list entries with +
	Use a space before and after the + to indicate this, such as mkarr(a + b) = [a,b]
	
	
*/

#ifndef __INDEX
#define __INDEX

// Local events
#define evt$STATE_ENTRY 0
#define evt$TIMER 1
#define evt$LISTEN 2
#define evt$SENSOR 3
#define evt$NO_SENSOR 4
#define evt$OBJECT_REZ 5
#define evt$RUN_TIME_PERMISSIONS 6
#define evt$CONTROL 7
#define evt$CHANGED 8
#define evt$ATTACH 9
#define evt$ON_REZ 10
#define evt$COLLISION 11
#define evt$COLLISION_START 12
#define evt$COLLISION_END 13
#define evt$TOUCH 14
#define evt$TOUCH_START 15
#define evt$TOUCH_END 16


// Macros
#include "./resources/macros.lsl"



// Global actions
// These are constant nrs sent in a linkmessage that will affect ALL scripts
// These can't be sent in a message between links as methods are hard-limited to 8 bytes
#define globalAction$RESET_ALL 0x7FFFFFFE		// Resets all scripts. Should include the sender script 
#define globalAction$resetAll() \
	llMessageLinked(LINK_SET, globalAction$RESET_ALL, "", llGetScriptName())

#define globalAction$SET_PLAYERS 0x7FFFFFFD		// Contains a JSON array of players
#define globalAction$setPlayers() \
	llMessageLinked(LINK_SET, globalAction$SET_PLAYERS, mkarr(_P), "")

#define globalEvent$players 1				// Raised when players have changed and you are using USE_PLAYERS
#define onPlayersUpdated() \
	if( _ty == globalEvent$players && _sc == ":" ){


// Channel to communicate on by default
#define PUB_CHAN 0xB00B










/*
	Syntax:
	- nr : 
		8 rightmost bits = evt/method number
		9&10 = message type
	- str: (json)[(key)sender, (var)data]
	- id : (str)target_script
*/
#define os$LM_ALL ""
#define os$lmtype$method 0
#define os$lmtype$event 1

#define sendLinkMessage( ln, script, type, nr, data, sender ) \
	llMessageLinked(ln, (((type&0x3)<<8)|(nr&0xFF)), mkarr(sender + mkarr(data)), (str)(script))

#define raiseEvent( evt, data ) \
	sendLinkMessage( LINK_SET, llGetScriptName(), os$lmtype$event, evt, data, "" )
	
#define runLocalMethod( ln, script, method, data ) \
	sendLinkMessage( ln, script, os$lmtype$method, method, data, "" )

// Syntax:
// [(str)target_script, (int)method, (var)data]
#define sendMessage( to, script, method, data ) \
	llRegionSayTo(to, PUB_CHAN, llList2Json(JSON_ARRAY, (list)(script)+(method)+mkarr(data)))

#define sendPublicMessage( script, method, data ) \
	llRegionSay(PUB_CHAN, llList2Json(JSON_ARRAY, (list)(script)+(method)+mkarr(data)))

_me( str ta, str sc, int me, list da ){
	// SAY
	if( (key)ta ){
		
		sendMessage(ta, sc, me, da);
		return;
		
	}
	
	// LM
	runLocalMethod((int)ta, sc, me, da);

}




// Constants for the event manager vars
#define METHOD_ARGS \
	_dta

#define SENDER_SCRIPT \
	_sc
	
#define EVENT_TYPE \
	_ty
	
#define SENDER_KEY \
	_se

#define METHOD_TYPE EVENT_TYPE

#define runOmniMethod( script, method, data )\
	sendPublicMessage( script, method, data )

#define runMethod( target, script, method, data ) \
	_me((str)(target), (str)(script), (int)method, (list)data)

#define NOT_METHOD \
	SENDER_SCRIPT != "!"
#define IS_METHOD \
	SENDER_SCRIPT == "!"
	

	
	

// Maps a method to the method arg
#define onMethod( method ) \
	if( IS_METHOD ){ \
		int method = EVENT_TYPE;

#define isMethodInternal() \
	if( _of == 1 ){

#define isMethodInternalInline() \
	_of == 1
	
#define isMethodByOwner() \
	if( _of ){
	
#define isMethodByOwnerInline()\
	_of

#define isEventByOwner() \
	isMethodByOwner()

#define isEventByOwnerInline() \
	isMethodByOwnerInline()

#define isEventNotByOwner() \
	if( !_of ){


// Handles specific methods
#define handleMethod( method ) \
	if( IS_METHOD && METHOD_TYPE == method ){

#define handleInternalMethod( method ) \
	if( IS_METHOD && METHOD_TYPE == method && _of == 1 ){
	
#define handleOwnerMethod( method ) \
	if( IS_METHOD && METHOD_TYPE == method && _of ){
	


#define argStr( nr ) l2s(METHOD_ARGS, nr)
#define argInt( nr ) l2i(METHOD_ARGS, nr)
#define argKey( nr ) l2k(METHOD_ARGS, nr)
#define argFloat( nr ) l2f(METHOD_ARGS, nr)
#define argRot(nr) l2rs(METHOD_ARGS, nr)
#define argVec(nr) l2vs(METHOD_ARGS, nr)


#include "./local/events.lsl"
	

#define end }



// Player list
list _P;	// Use #define USE_PLAYERS to include these. In levels they're handled by Level, in HUDs by Com, and assets Portal
#define PLAYERS _P
#define isPlayer( targ ) \
	(~llListFindList(PLAYERS, (list)((str)targ)))


#define forPlayer( index, player ) \
int index; \
for(; index < count(_P); ++index ){ \
	key player = l2k(_P, index); 





#include "./resources/functions.lsl"

#include "./local/timer.lsl"
#include "./local/listen.lsl"
#include "./local/players.lsl"

#include "./resources/ObstacleEvents.lsl"

#include "./headers/SharedDescriptions.lsl"
#include "./headers/Controls.lsl"

#include "./headers/Gui.lsl"
#include "./headers/Interact.lsl"
#include "./headers/SupportCube.lsl"
#include "./headers/Climb.lsl"
#include "./headers/Rlv.lsl"
#include "./headers/Footsteps.lsl"
#include "./headers/AnimHandler.lsl"

#include "./headers/Com.lsl"
#include "./headers/SoundspaceAux.lsl"
#include "./headers/Soundspace.lsl"
#include "./headers/Level.lsl"
#include "./headers/Repo.lsl"
#include "./headers/Spawner.lsl"
#include "./headers/Screpo.lsl"
#include "./headers/Portal.lsl"
#include "./headers/Rezzer.lsl"

#include "./headers/CrusherWall.lsl"
#include "./headers/Trigger.lsl"

#include "./headers/PrimSwimParticles.lsl"
#include "./headers/PrimSwimAux.lsl"
#include "./headers/PrimSwim.lsl"




#endif
