/*
	Event constants:
	- METHOD_ARGS : All arguments passed to the event
	- SENDER_SCRIPT : Script that raised the event (event only)
	- EVENT_TYPE : Type of event raised
	- SENDER_KEY : Key of sender, or "" if internal
	

	Folder structure:
	- headers [.lsh] : Contains headers and event definitions for modules
				The script name in SL should be the same as the script name in the directory
				The script name should have a capital first letter
		- Obstacles : Standard calls to specific obstacle types. Obstacles are usually hardcoded for speed reasons. Shared obstacles go in the root folder. Otherwise make a subfolder for each game type
			Note: You can use headers from multiple subfolders just fine if you want to make a mixed game. The folder is mostly for sorting.
			- <Gametype a>...
			- <Gametype b>...
	- components [.lsc] : Used for defining what built in and xmod components (such as bulit in events) that you want to use via #define USE_* etc
				Event definitions for these are stored in this file since they all use "" as sender
				Local doesn't use capital letters at the start of the script name
	- modules [.lsl] : Contains complete modules with little to no user editing. Should be used for scripts that are stored in the HUD, either remote-loaded or running.
	- templates [.template] : Similar to modules. Contains mostly full scripts, but usually have required user edits and a large degree of freedom for modding. 
	- shared [.lsh] : Tools, asset libraries, macros, and code shared across multiple game types.
	- helpers [.lsb] : Game mode helpers. Boilerplate code that helps you setup the basics for each game type.
		- <Gametype a>...
		- <Gametype b>...
		
	Root folder scripts:
	- begin.lsl 		: #include this to start the ObstacleScript event loop. Put all ObstacleScript event handler below this include, and all globals above.
	- end.lsl			: #include this at the end of your script
	- index.lsl			: This file. Includes the framework core functionality, and includes all shared files. This needs to be included towards the top of each script.

	Naming:
	- USE : Enables new functionality in the code. Syntax: USE_<SCRIPTNAME>
	- event & method handlers : on/handle<scriptName><evtName> - Ex: onInteractiveInteract. local evts don't have a scriptname so they use onStateEntry or onTimer etc. Custom local events should consider using "$NAME" as the sender script
		- on is used when defining the argument as a variable. Such as onTimer(id) - Creates str id with the ID of the timer that was triggered
		- handle is used when the argument is used as a filter. Such as handleTimer(id) - Only triggers when the id of the timer is the same as the argument
	
	- event idents : ScriptEvt$<evtName> - Ex: ComEvt$receive. Local evts are defined in this script with only evt. These event identifiers are usually abstracted away into the handler above
	- event conditions : <scriptName>Cond$<conditionName> - Ex: ComCond$listenIsOwner(). Local events don't use the script name. Ex Cond$listenIsOwner
	- methods : <scriptName>Method$<methodName> - Ex ComMethod$send
	- method macros : <scriptName>$<methodName> - Ex Com$send()
	- config defines : <scriptName>Cfg$confName - Ex ComCfg$something 
	- script constants : <scriptName>$CONST_NAME Ex Rlv$BITS
	- helpers : <scriptName>Helper$methodName - Ex PortalHelper$getConf()
	
	Link message definition:
	nr : (int)event
	str : (key)sender + JSON data passed to event
	id : target_script or "" for ALL
	
	Macros with lists can usually accept multiple arguments concatenated as list entries with +
	Use a space before and after the + to indicate this, such as mkarr(a + b) = [a,b]
	
	Some obstacles will listen to their own channels instead of using xMod comms, this is used when:
	- The obstacle needs to send/receive frequent or large amounts of data. Using its own channel makes it faster.
	- The obstacle only needs to communicate with the owner
	- The obstacle needs the ability to trigger by a label
	
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
#define evt$HTTP_RESPONSE 17


#define XMOD_MAX_PLAYERS 32	// max nr of players xmod can handle. used in table reservation for playerdata


// Macros
#include "./shared/macros.lsh"
#include "./shared/table_registry.lsh"




// Global actions
// These are constant nrs sent in a linkmessage that will affect ALL scripts
// These can't be sent in a message between links as methods are hard-limited to 8 bytes
#define globalAction$RESET_ALL 0x7FFFFFFE		// Resets all scripts. Should include the sender script 
#define globalAction$resetAll() \
	llMessageLinked(LINK_SET, globalAction$RESET_ALL, "", llGetScriptName())

// Channel to communicate on by default
#define PUB_CHAN 0xB00B
#define OBSTACLE_CHAN 0xC34		// 3124 - Channel to talk to obstacles on



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
	
#define handleEvent( script, evt ) \
	if( SENDER_SCRIPT IS script AND EVENT_TYPE IS evt ){


#define argStr( nr ) l2s(METHOD_ARGS, nr)
#define argInt( nr ) l2i(METHOD_ARGS, nr)
#define argKey( nr ) l2k(METHOD_ARGS, nr)
#define argFloat( nr ) l2f(METHOD_ARGS, nr)
#define argRot(nr) l2rs(METHOD_ARGS, nr)
#define argVec(nr) l2vs(METHOD_ARGS, nr)


#include "./components/events.lsc"
	

#define end }





#include "./shared/functions.lsh"

/* PLAYER / PLAYER DATA MANAGEMENT */

// Relies on functions
// Player data: Tables start from idbTable$PDATA_START and go to but not including idbTable$PDATA_START+PDATA_START
// The first value is always a uuid. The rest are set by the game.
// Player data functions for any script in the level linkset
#define getPdataTableChar(entry) llChar(idbTable$PDATA_START+entry)
#define setPdata(entry, idx, val) idbSetByIndex(getPdataTableChar(entry), idx, val)
#define getPdata(entry, idx) idbGetByIndex(getPdataTableChar(entry), idx)
#define findPdata(player) _pdI(player)


// plIndex is the absolute table index, not the index of the player (which is based on players found, not total rows)
#define setPlayerData( plIndex, field, val ) setPdata(plIndex, field, val)
#define getPlayerDataInt( plIndex, field ) (int)getPdata(plIndex, field)
#define getPlayerDataStr( plIndex, field ) getPdata(plIndex, field)
#define getPlayerDataVec( plIndex, field ) (vector)getPdata(plIndex, field)
#define getPlayerDataRot( plIndex, field ) (rotation)getPdata(plIndex, field)
#define getPlayerDataFloat( plIndex, field ) (float)getPdata(plIndex, field)
#define getPlayerDataKey( plIndex, field ) (key)getPdata(plIndex, field)

// Note: Use this with forPlayerDataEnd
// i is the table used in getPlayerData..., idx is the player number, since there might be empty playerdata rows
#define forPlayerData( i, idx, uuid ) int i; int idx = -1; for(; i < XMOD_MAX_PLAYERS; ++i ){ \
	key uuid = getPlayerDataStr(i, 0); \
	if( uuid ){ \
		++idx; \

#define forPlayerDataEnd }}


// Finds player data index of a uuid, or -1 if not found
int _pdI( key id ){
	int i;
	for(; i < XMOD_MAX_PLAYERS; ++i ){
		if( id == getPdata(i, 0) )
			return i;
	}
	return -1;
}


#define numPlayers() idbGetIndex(idbTable$PLAYERS)
#define numHuds() idbGetIndex(idbTable$HUDS)


#define forPlayer( tot, index, player ) \
	int index; int tot = numPlayers(); \
	for(; index < tot; ++index ){ \
		key player = idbGetByIndex(idbTable$PLAYERS, index); 


#define forHuds( tot, index, hud ) \
	int index; int tot = numHuds(); \
	for(; index < tot; ++index ){ \
		key hud = idbGetByIndex(idbTable$HUDS, index); 
		
#define forInvType( type, index, name ) \
	int index; \
	for(; index < llGetInventoryNumber(type); ++index ){ \
		str name = llGetInventoryName(type, index);
		


#define getPlayers() idbValues(idbTable$PLAYERS, true)
#define getHuds() idbValues(idbTable$HUDS, true)

// note: ID 
#define isPlayer( stringID ) \
	( stringID == llGetOwner() || ~llListFindList(getPlayers(), (list)stringID) )
	





// gconf
#define getGconf(idx) idbGetByIndex(idbTable$GCONF, idx)





#include "./components/timer.lsc"
#include "./components/listen.lsc"

#include "./shared/LevelCustomEvents.lsh"
#include "./shared/PortalCustomEvents.lsh"
#include "./shared/Descriptions.lsh"

#include "./headers/Controls.lsh"

#include "./headers/Gui.lsh"
#include "./headers/Interact.lsh"
#include "./headers/SupportCube.lsh"
#include "./headers/Climb.lsh"
#include "./headers/Rlv.lsh"
#include "./headers/Footsteps.lsh"
#include "./headers/AnimHandler.lsh"
#include "./headers/Qte.lsh"


#include "./headers/Com.lsh"
#include "./headers/Soundspace.lsh"
#include "./headers/Level.lsh"
#include "./headers/Repo.lsh"
#include "./headers/Spawner.lsh"
#include "./headers/Screpo.lsh"
#include "./headers/Portal.lsh"
#include "./headers/Rezzer.lsh"
#include "./headers/LevelRepo.lsh"
#include "./headers/Nodes.lsh"
#include "./headers/DB.lsh"
#include "./headers/Attachment.lsh"

#include "./headers/PrimSwimParticles.lsh"
#include "./headers/PrimSwimAux.lsh"
#include "./headers/PrimSwim.lsh"

#include "./headers/Obstacles/Trap.lsh"
#include "./headers/Obstacles/Trigger.lsh"
#include "./headers/Obstacles/Wipeout/CrusherWall.lsh"
#include "./headers/Obstacles/Wipeout/Button.lsh"
#include "./headers/Obstacles/Wipeout/ShimmyWall.lsh"
#include "./headers/Obstacles/Wipeout/SlideBeam.lsh"
#include "./headers/Obstacles/Wipeout/Trapdoor.lsh"
#include "./headers/Obstacles/Ghost/Door.lsh"
#include "./headers/Obstacles/Ghost/RoomMarker.lsh"
#include "./headers/Obstacles/Ghost/Lamp.lsh"
#include "./headers/Obstacles/Ghost/Ghost.lsh"
#include "./headers/Obstacles/Ghost/GhostInteractions.lsh"
#include "./headers/Obstacles/Ghost/GhostInteractive.lsh"
#include "./headers/Obstacles/Ghost/Owometer.lsh"
#include "./headers/Obstacles/Ghost/Spiritbox.lsh"
#include "./headers/Obstacles/Ghost/GhostTool.lsh"
#include "./headers/Obstacles/Ghost/ToolSet.lsh"
#include "./headers/Obstacles/Ghost/GhostStatusBoard.lsh"
#include "./headers/Obstacles/Ghost/MotionDetector.lsh"
#include "./headers/Obstacles/Ghost/BondageDevice.lsh"
#include "./headers/Obstacles/Ghost/GhostBoard.lsh"
#include "./headers/Obstacles/Ghost/GhostRadio.lsh"
#include "./headers/Obstacles/Ghost/GhostAux.lsh"
#include "./headers/Obstacles/Ghost/GhostEvents.lsh"
#include "./headers/Obstacles/Ghost/GhostLevelHelper.lsh"


#define USE_PLAYERS #error use_players definition detected. Use "forPlayer" instead



#endif
