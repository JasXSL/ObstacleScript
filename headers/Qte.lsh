#ifndef __Qte
#define __Qte


#define QteMethod$start 1		// (int)type, (str)callback - Starts a quicktime event
#define QteMethod$end 2			// (bool)success


#define QteEvt$start 1			// (int)type, (str)callback
#define QteEvt$end 2			// (int)success

#define QteConst$QTE_GAUGE 1		// Hit left/right to keep the meter in the middle


#define onQteStart( type ) \
	if( SENDER_SCRIPT IS "Qte" AND EVENT_TYPE IS QteEvt$start ){ \
		int type = argInt(0);

#define onQteEnd( success ) \
	if( SENDER_SCRIPT IS "Qte" AND EVENT_TYPE IS QteEvt$end ){ \
		int success = argInt(0);



#define Qte$start( targ, type, callback ) \
	runMethod(targ, "Qte", QteMethod$start, type + callback )

#define Qte$end( targ, success ) \
	runMethod(targ, "Qte", QteMethod$end, success )




#endif
