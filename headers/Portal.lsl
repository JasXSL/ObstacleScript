#ifndef __Portal
#define __Portal

// Scritps that should be automatically remoteloaded
#define PortalConst$TRACKED_SCRIPTS (list) \
	"Trigger"

// prim text contains some information about the portal
#define PortalConst$CF_REZ_PARAM 0					// (int)on_rez_param - Contains the supplied int from on_rez
#define PortalConst$CF_GROUP 1						// (str)spawn_group - Contains the spawn group

// Portal on_rez params are stored as follows (from the right)
// 0000(0) - Screpo flags
// 0(4)	- Live status
// 00000000 00000000(5) - 2 Bytes with the spawn ID in the spawner script.
#define PortalConst$SP_LIVE 0x10

#define PortalHelper$getConf() \
	llJson2List(l2s(llGetPrimitiveParams((list)PRIM_TEXT), 0))
#define PortalHelper$getSpawnId() \
	((l2i(PortalHelper$getConf(), PortalConst$CF_REZ_PARAM)>>5)&0xFFFF)
#define PortalHelper$isLive() \
	(l2i(PortalHelper$getConf(), PortalConst$CF_REZ_PARAM)&PortalConst$SP_LIVE)


#define PortalEvt$loadComplete 1		// void - All scripts have finished loading


#define PortalMethod$reset 0		// Resets all scripts
#define PortalMethod$fetch 1		// Fetches all scripts from DB
#define PortalMethod$kill 2			// (int)type, (var)filter1, filter2... - Deletes portal assets, refer to below
	#define PortalConst$KILL_ALL 0		// Kills all portals
	#define PortalConst$KILL_NAME 1		// Kills all portals with the object name set in filter
	#define PortalConst$KILL_ID 2		// Kills portals where the spawn ID is in filter
#define PortalMethod$setLive 3			// Sets the portal to l ive. Use PortalMethod$reset to clear live

#define PortalMethod$scriptOnline 3		// (str)script - Sent from a script when it's initialized
#define PortalMethod$save 4				// Sends a message to spawner telling it to save this object
#define PortalMethod$init 5				// (vec)pos, (str)desc, (str)group - Passed from Rezzer, sets the object initialization data. Can only be sent once per object.


#define Portal$killAll() \
	runOmniMethod( "Portal", PortalMethod$kill, PortalConst$KILL_ALL )
#define Portal$kill(uuid) \
	runMethod( uuid, "Portal", PortalMethod$kill, PortalConst$KILL_ALL )
#define Portal$killByName( names ) \
	runOmniMethod( "Portal", PortalMethod$kill, PortalConst$KILL_NAME + names )
#define Portal$killID( ids ) \
	runOmniMethod( "Portal", PortalMethod$kill, PortalConst$KILL_ID + ids )
#define Portal$save() \
	runOmniMethod( "Portal", PortalMethod$save, [] )

#define Portal$scriptOnline() \
	runMethod( LINK_THIS, "Portal", PortalMethod$scriptOnline, llGetScriptName() )

#define Portal$init( target, pos, desc, group ) \
	runMethod( target, "Portal", PortalMethod$init, pos + desc + group )

#endif
