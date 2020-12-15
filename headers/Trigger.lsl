#ifndef __Trigger
#define __Trigger

// Trigger description: [(vec)size, (str)id, (int)flags]

#define TriggerConst$F_TRIGGER_ONCE 0x1		// Triggers once




#define TriggerEvt$trigger 1		// (key)player - Raised when a player triggers a collision


#define onTrigger( object, player, label ) \
	if( isEventLevelCustom() AND argStr(1) == "Trigger" AND argInt(2) == TriggerEvt$trigger ){ \
		key object = argKey(0); \
		key player = argKey(3); \
		str _d = prDesc(object); \
		if( llGetSubString(_d, 0, 0) == "$" ) \
			_d = llDeleteSubString(_d, 0, 0); \
		str label = j(_d, 1);
		

#endif
