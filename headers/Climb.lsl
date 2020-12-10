#ifndef __Climb
#define __Climb


#define ClimbEvt$start 1		// [(key)ladder, (var)onStartData]
#define ClimbEvt$end 2			// [(key)ladder, (var)onEndData]




#define ClimbMethod$start 1		// [(key)ladder, (rot)rotation_offset, (str)anim_passive, (str)anim_active, (str)anim_active_down, (str)anim_dismount_top, (str)anim_dismount_bottom, (arr)nodes, (float)climbspeed, (str)evtOnStartData, (str)evtOnEndData]
#define ClimbMethod$stop 2		// void - Stops climbing

#define Climb$start(ladder, rot_offset, anim_passive, anim_active, anim_active_down, anim_dismount_top, anim_dismount_bottom, nodes, climbspeed, onStart, onEnd) \
	runMethod((string)LINK_SET, "Climb", ClimbMethod$start, \
		ladder + rot_offset + anim_passive + anim_active + anim_active_down + anim_dismount_top + anim_dismount_bottom + nodes + climbspeed + onStart + onEnd \
	)

#define Climb$stop(targ) \
	runMethod(targ, "Climb", ClimbMethod$stop, [])


#ifndef ClimbCfg$defaultSpeed
	#define ClimbCfg$defaultSpeed .65
#endif


#define onClimbStart( ladder, customLadderData ) \
	if( SENDER_SCRIPT IS "Climb" AND EVENT_TYPE IS ClimbEvt$start ){ \
		key ladder = argKey(0); \
		str customLadderData = argStr(1); 

#define onClimbEnd( ladder, customLadderData ) \
	if( SENDER_SCRIPT IS "Climb" AND EVENT_TYPE IS ClimbEvt$end ){ \
		key ladder = argKey(0); \
		str customLadderData = argStr(1); 



#endif
