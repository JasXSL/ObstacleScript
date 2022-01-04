#ifndef __EVENTS
#define __EVENTS
// Note: Listen is handled in listen.lsl
// Built in event handlers

/*
#ifdef USE_!
	#define on!() \
		if( _ty == evt$! && _sc == "" ){
#else
	#define on!() #error Add #define USE_! to the top of your script
#endif


Note: Checking if something is an event is enough to check _sc == something other than !

*/

// Things that are commonly linked
// Control will automatically use run_time_permissions
#ifdef USE_CONTROL
	#ifndef USE_RUN_TIME_PERMISSIONS
		#define USE_RUN_TIME_PERMISSIONS
	#endif
#endif



// state_entry
#ifdef USE_STATE_ENTRY
	#define onStateEntry() \
		if( _ty == evt$STATE_ENTRY && _sc == "" ){
#else
	#define onStateEntry() #error Add #define USE_STATE_ENTRY to the top of your script
#endif


// state_entry
#ifdef USE_HTTP_RESPONSE
	#define onHttpResponse( id, status, body ) \
		if( _ty == evt$HTTP_RESPONSE && _sc == "" ){ \
			key id = argKey(0); \
			int status = argInt(1); \
			str body = argStr(2);
#else
	#define onHttpResponse() #error Add #define USE_HTTP_RESPONSE to the top of your script
#endif


// sensor
#ifdef USE_SENSOR
	#define onSensor( total ) \
		if( _ty == evt$SENSOR && _sc == "" ){ \
			int total = l2i(_dta, 0);
#else
	#define onSensor( total ) #error Add #define USE_SENSOR to the top of your script
#endif
	
	
// no_sensor
#ifdef USE_NO_SENSOR
	#define onNoSensor() \
		if( _ty == evt$NO_SENSOR && _sc == "" ){	
#else
	#define onNoSensor() #error Add #define USE_NO_SENSOR to the top of your script
#endif


// object_rez
#ifdef USE_OBJECT_REZ
	#define onObjectRez( object ) \
		if( _ty == evt$OBJECT_REZ && _sc == "" ){ \
			key object = argKey(0);
#else
	#define onObjectRez( object ) #error Add #define USE_OBJECT_REZ to the top of your script
#endif

// changed
#ifdef USE_CHANGED
	#define onChanged( change ) \
		if( _ty == evt$CHANGED && _sc == "" ){ \
			int change = argInt(0);
#else
	#define onChanged( change ) #error Add #define USE_CHANGED to the top of your script
#endif


// run_time_permissions
#ifdef USE_RUN_TIME_PERMISSIONS
	#define onRunTimePermissions( perm ) \
		if( _ty == evt$RUN_TIME_PERMISSIONS && _sc == "" ){ \
			int perm = argInt(0);
#else
	#define onRunTimePermissions( perm ) #error Add #define USE_RUN_TIME_PERMISSIONS to the top of your script
#endif


// control
#ifdef USE_CONTROL
	#define onControl( level, edge ) \
		if( _ty == evt$CONTROL && _sc == "" ){ \
			int level = argInt(0); \
			int edge = argInt(1); \
			
#else
	#define onControl( level, edge ) #error Add #define USE_CONTROL to the top of your script
#endif



// attahc
#ifdef USE_ATTACH
	#define onAttach( id ) \
		if( _ty == evt$ATTACH && _sc == "" ){ \
			key id = argKey(0); 
			
#else
	#define onAttach( id ) #error Add #define USE_ATTACH to the top of your script
#endif


// on_rez
#ifdef USE_ON_REZ
	#define onRez( nr ) \
		if( _ty == evt$ON_REZ && _sc == "" ){ \
			int nr = argInt(0); 
			
#else
	#define onRez( nr ) #error Add #define USE_ON_REZ to the top of your script
#endif



#ifdef USE_COLLISION_START
	#define onCollisionStart( total ) \
		if( _ty == evt$COLLISION_START && _sc == "" ){ \
			int total = argInt(0); 
#else
	#define onCollisionStart( total ) #error Add #define USE_COLLISION_START to the top of your script
#endif



#ifdef USE_COLLISION_END
	#define onCollisionEnd( total ) \
		if( _ty == evt$COLLISION_END && _sc == "" ){ \
			int total = argInt(0); 
#else
	#define onCollisionEnd( total ) #error Add #define USE_COLLISION_END to the top of your script
#endif



#ifdef USE_TOUCH
	#define onTouch( total ) \
		if( _ty == evt$TOUCH && _sc == "" ){ \
			int total = argInt(0); 
#else
	#define onTouch( total ) #error Add #define USE_TOUCH to the top of your script
#endif


#ifdef USE_TOUCH_START
	#define onTouchStart( total ) \
		if( _ty == evt$TOUCH_START && _sc == "" ){ \
			int total = argInt(0); 
#else
	#define onTouchStart( total ) #error Add #define USE_TOUCH_START to the top of your script
#endif


#ifdef USE_TOUCH_END
	#define onTouchEnd( total ) \
		if( _ty == evt$TOUCH_END && _sc == "" ){ \
			int total = argInt(0); 
#else
	#define onTouchEnd( total ) #error Add #define USE_TOUCH_END to the top of your script
#endif











#endif
