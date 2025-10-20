
}

default{
	
	#ifdef USE_STATE_ENTRY
	state_entry(){
		#ifdef SE_OVERRIDE // Use SE_OVERRIDE if you need to initialize something big like an IDB table on state entry
		SE_OVERRIDE
		#else
		onEvent(evt$STATE_ENTRY, "", "", []);
		#endif
	} 
	#endif
	
	#ifdef USE_TIMER
	timer(){_mt([]);}
	#endif
	
	#ifdef USE_LISTEN
	listen( int ch, string n, key id, str m ){
		onEvent(evt$LISTEN, "", id, (list)ch + m); 
	}
	#endif
	
	
	
	link_message( integer link, integer nr, string s, key id ){
	
		#ifdef LM_PRE
		LM_PRE
		#endif

		// Ignore
		if( nr < 0 )
			return;
		#ifndef IGNORE_RESET
		if( nr == globalAction$RESET_ALL && (str)id != llGetScriptName() )
			llResetScript();
		#endif

		int type = (nr>>8)&3;
		str ids = (string)id;
		
		// Filter methods
		if( type == os$lmtype$method && ids != llGetScriptName() )
			return;
		
		if( type == os$lmtype$method )
			ids = "!";

		list dta = llJson2List(s);
		
		onEvent(nr&0xFF, ids, l2k(dta, 0), llJson2List(l2s(dta, 1)));
	
	}
	
	#ifdef USE_SENSOR
	sensor( int tot ){ onEvent(evt$SENSOR, "", "", (list)tot); }
	#endif
	
	
	#ifdef USE_NO_SENSOR
	no_sensor(){ onEvent(evt$NO_SENSOR, "", "", []); }
	#endif
	
	#ifdef USE_ATTACH
	attach( key id ){ onEvent(evt$ATTACH, "", "", (list)id); }
	#endif
	
	#ifdef USE_OBJECT_REZ
	object_rez( key id ){ onEvent(evt$OBJECT_REZ, "", "", (list)id); }
	#endif
	
	
	#ifdef USE_CHANGED
	changed( int change ){ onEvent(evt$CHANGED, "", "", (list)change); }
	#endif
	
	#ifdef USE_RUN_TIME_PERMISSIONS
	run_time_permissions( int perm ){ onEvent(evt$RUN_TIME_PERMISSIONS, "", "", (list)perm); }
	#endif
	
	#ifdef USE_CONTROL
	control( key id, int level, int edge ){ onEvent(evt$CONTROL, "", "", (list)level + edge); }
	#endif
	
	#ifdef USE_ON_REZ
	on_rez( int n ){ onEvent(evt$ON_REZ, "", "", (list)n); }
	#endif
	
	#ifdef USE_COLLISION
	collision( int n ){ onEvent(evt$COLLISION, "", "", (list)n); }
	#endif
	#ifdef USE_COLLISION_START
	collision_start( int n ){ onEvent(evt$COLLISION_START, "", "", (list)n); }
	#endif
	#ifdef USE_COLLISION_END
	collision_end( int n ){ onEvent(evt$COLLISION_END, "", "", (list)n); }
	#endif
	
	#ifdef USE_TOUCH
	touch( int n ){ onEvent(evt$TOUCH, "", "", (list)n); }
	#endif
	#ifdef USE_TOUCH_START
	touch_start( int n ){ onEvent(evt$TOUCH_START, "", "", (list)n); }
	#endif
	#ifdef USE_TOUCH_END
	touch_end( int n ){ onEvent(evt$TOUCH_END, "", "", (list)n); }
	#endif
	
	#ifdef USE_HTTP_RESPONSE
	http_response( key id, integer status, list meta, string body ){ onEvent(evt$HTTP_RESPONSE, "", "", (list)id + status + body); }
	#endif
	
	
	
	
}

