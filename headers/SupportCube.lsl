#ifndef __SupportCube
#define __SupportCube


/*
	
	The SupportCube is a rezzed out prim that will let you force sit, position or rotate a player.
	It works together with st RLV
	See st RLV for setup instructions
	
	st RLV handles all commands to the SupportCube, so there's no need to do so manually
	with one exception:
	
	Some times you might want to set the cube's pos and rotation very frequently (like in st Climb)
	For this you can use the listenOverride feature
	You can do this by calling llRegionSayTo(SupportCube, llList2CSV([SupportCubeCfg$listenOverride, (vec)pos, (rot)rotation]));
	
*/

#define SupportCubeCfg$INIT_CHAN 17733			// Chat channel that initializes

#define SupportCubeMethod$execute 1			// (arr)task_objs_in_order
// Obj: {"t":(int)type, "p":[params]}
#define SupportCubeMethod$killall 2			// NULL - kills support cubes


#ifndef SupportCube$confWaitForSit		// Wait for an avatar to sit or unsit before performing next action
	#define SupportCube$confWaitForSit 1	
#endif




// Tasks that support callbacks callback with : METHOD = SupportCubeMethod$execute, cb_data : [task, arg1, arg2...], and supplied callback string
#define SupportCube$tSetPos 1			// [(vec)pos]
#define SupportCube$tSetRot 2			// [(rot)rotation]
#define SupportCube$tForceSit 3			// [(bool)prevent_unsit, (bool)wait_for_sit]
#define SupportCube$tForceUnsit 4		// []
#define SupportCube$tDelay 5			// [(float)delay]
#define SupportCube$tRunMethod 6		// [(key)targ, (str)script, (int)method, (arr)data]
// DEPRECATED
//#define SupportCube$tTranslateTo 7		// [(vec)pos, (rot)rot, (float)time, (int)mode] - Mode defaults to FWD
//#define SupportCube$tTranslateStop 8	// 
#define SupportCube$tKFM 9				// (arr)coordinates, (arr)command - Same data as llSetKeyframedMotion
#define SupportCube$tKFMEnd 10			// void - Calls KFM_CMD_STOP and clears the buffer, making sure global position updates will be instant
#define SupportCube$tPathToCoordinates 11	// [(vec)start_pos, (rot)start_rot, (vec)end_pos, (str)anim, (str)callback, (float)speed=1, (int)flags, (key)callback_to, (str)callback_script] - Runs asynchronously. Use <0,0,0> to turn off. Tries to walk the player towards a location. Only X/Y are used. callback_to etc can override the default callback targets
	#define SupportCube$PTCFlag$STOP_ON_UNSIT 0x1		// Stops the walk if the player unsits
	#define SupportCube$PTCFlag$UNSIT_AT_END 0x2		// Unsits the player when the end has been reached
	#define SupportCube$PTCFlag$WARP_ON_FAIL 0x4		// Warps if it failed and the player is still seated. This will cause it to always callback true

#define SupportCubeOverride$tKFMEnd 5			// Tunneled through override - (arr)data, (arr)conf
#define SupportCubeOverride$tKFM 5				// Tunneled through override - (vec)localOffset, (rot)localOffset, (float)time
#define SupportCubeOverride$tSetPosAndRot 6		// Tunneled through override - (vec)pos, (rot)rotation


#define SupportCubeBuildTask(task, params) llList2Json(JSON_OBJECT, (list)"t" + task + "p" + mkarr(params))

#define SupportCubeBuildTeleport(pos) \
	SupportCubeBuildTask(SupportCube$tSetPos, llGetRootPosition()) + \
	SupportCubeBuildTask(SupportCube$tDelay, .1) + \
	SupportCubeBuildTask(SupportCube$tForceSit, FALSE + TRUE) + \
	SupportCubeBuildTask(SupportCube$tSetPos, pos) + \
	SupportCubeBuildTask(SupportCube$tForceUnsit, [])
	
#define SupportCubeBuildTeleportNoUnsit(pos, rot) \
	SupportCubeBuildTask(SupportCube$tSetPos, llGetRootPosition()) + \
	SupportCubeBuildTask(SupportCube$tDelay, .1) +  \
	SupportCubeBuildTask(SupportCube$tForceSit, TRUE + TRUE) +  \
	SupportCubeBuildTask(SupportCube$tSetPos, pos) +  \
	SupportCubeBuildTask(SupportCube$tSetRot, rot)

// Listen override lets you send CSVs of TASK, DATA, DATA... to speed up calls
#ifndef SupportCubeCfg$listenOverride
	#define SupportCubeCfg$listenOverride 32986
#endif













#endif
