#ifndef __PortalCustomEvent
#define __PortalCustomEvent
/*
	
	This file contains a list of obstacle events tied to an avatar instead of an obstacle, such as ladders, quicktime events, and projectile.
	These events are raised on Portal through the Portal$customEvent method, then raised through PortalEvt$custom
	You can obviously create your own custom ones, but follow these naming conventions:
	1. For obstacle type, start with lowercase o. Labeling it with an "o" first makes sure it doesn't collide with script names such as Trigger events. For player type start with "pl"
		Syntax is ObstacleType$<TYPE>
	2. For events, syntax is ObstacleEvt$<TYPE>$<evt>
	
	"o" type events should be defined in their obstacle header file.
	This file is for av type event.
	
	Note that Portal adds 3 args at the start of the event: (key)hud, (str)customType, (int)customTypeEventType(defined below)
	As such the first argument is arg<type>(3)
*/

#define PortalCustomType$INTERACT "avInt"
	#define PortalCustomEvt$INTERACT$start 1		// (vec)pos - Key pressed
	#define PortalCustomEvt$INTERACT$end 2			// void - Key released
#define PortalCustomType$LCLICK "avLclick"			// Only raised on owner attachments
	#define PortalCustomEvt$LCLICK$start 1			// void - Lclick pressed
	#define PortalCustomEvt$LCLICK$end 2			// void - Lclick released


#define onPortalInteractStarted( hud, pos ) \
	if( isEventPortalCustom() AND argStr(1) == PortalCustomType$INTERACT AND argInt(2) == PortalCustomEvt$INTERACT$start ){ \
		key hud = argKey(0); \
		vector pos = argVec(3);
#define onPortalInteractEnded( hud ) \
	if( isEventPortalCustom() AND argStr(1) == PortalCustomType$INTERACT AND argInt(2) == PortalCustomEvt$INTERACT$end ){ \
		key hud = argKey(0);
		
#define onPortalLclickStarted( hud ) \
	if( isEventPortalCustom() AND argStr(1) == PortalCustomType$LCLICK AND argInt(2) == PortalCustomEvt$LCLICK$start ){ \
		key hud = argKey(0);
#define onPortalLclickEnded( hud ) \
	if( isEventPortalCustom() AND argStr(1) == PortalCustomType$LCLICK AND argInt(2) == PortalCustomEvt$LCLICK$end ){ \
		key hud = argKey(0);
		
	

#endif
