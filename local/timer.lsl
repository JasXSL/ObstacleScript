#ifndef __Timer
#define __Timer

// #define USE_TIMER to include
#ifdef USE_TIMER

	// Usage

	// Checks for a specific timer
	#define handleTimer( id ) \
		if( _ty == evt$TIMER && NOT_METHOD && _sc == "" && argStr(0) == id ){
			
	// Handles all timers, use argStr(0) for the id
	#define onTimer( id ) \
		if( _ty == evt$TIMER && NOT_METHOD && _sc == "" ){ \
			str id = argStr(0);
			
	

	// Sets a timer to run once
	#define setTimer(id, timeout) \
		_mt((list)((str)(id)) + timeout + 0)
	// Pseudonym of above
	#define setTimeout(id, timeout) \
		setTimer(id, timeout)
	// Sets a timer to loop	
	#define setInterval(id, timeout) \
		_mt((list)((str)(id)) + timeout + 1)
	// Removes a timer. These can be used both on interval and timer
	#define unsetTimer(id) \
		_mt((list)((str)(id)))
	#define unsetInterval(id) \
		unsetTimer(id)
	#define unsetTimersThatStartWith(id) \
		_mtS((str)(id))
	
		
		
	// Code

	list _T;	// (float)timeout, id, looptime, repeating
	_mt( list da ){
		
		integer i;
		// If there's an add or remove, remove existing regardless
		if( da ){
		
			// Find if this timer is set
			integer pos = llListFindList(
				llList2ListStrided(
					llDeleteSubList(_T,0,0), 0, -1, 4), 
					llList2List(da,0,0)
				);
			
			// Delete if it exists
			if( ~pos )
				_T = llDeleteSubList(_T, pos*4, pos*4+3);	// Remove existing
			
			// Entries are 3, add
			if( count(da) == 3 )
				_T = _T + (list)(llGetTime() + llList2Float(da,1)) + da;

		}
		
		float next = -3.402823466E+38;	// min value
		
		int trigs;
		
		// Iterate over active events
		for( ; i<count(_T); i = i+4 ){
		
			
			int del;
			float offs = llGetTime()-llList2Float(_T,i);	// When next to trigger

			// less than 0 means this shouldn't trigger yet, above 0 is lag
			if( offs >= 0 && !count(da) ){	// Triggering on add/remove can cause recursion issues, best do it asynchronously
				
				list id = llList2List(_T, -~i, -~i);
				// looping
				if( llList2Integer(_T,i+3) ){
				
					offs = llList2Float(_T,i+2)-offs;	// -offs Adjusts for lag
					_T = llListReplaceList(_T, (list)(llGetTime()+offs), i, i);
					offs = -offs;	// Updates so we know how far in the future it should trigger
					
				}
				// Not looping, remove
				else{
				
					_T= llDeleteSubList(_T, i, i+3);
					del = TRUE;
					i -= 4;	// Go back since we removed it
					
				}
				
				// Trigger the timer event
				onEvent( evt$TIMER, "", "", id );
				++trigs;

			}
			
			// The more negative offs is, the further in the future it is.
			if( offs > next && !del )
				next = offs;

		}
		
		
		
		
		if( _T == [] ){
			llSetTimerEvent(0); 
			return;
		}

		if( next > -0.01 )
			next = -0.01;

		llSetTimerEvent(llFabs(next));
		
	}

	// Stops timers that start with
	_mtS( str start ){
	
		int len = llStringLength(start);
		int i = 0;
		for( ; i < count(_T) && count(_T); i = i+4 ){
			
			str id = l2s(_T, i+1);
			
			if( llGetSubString(id, 0, len-1) == start ){
			
				_T = llDeleteSubList(_T, i, i+3);
				i = i-4;
			
			}
			
		}
		
	}

#else
	#define onTimer( id ) #error To use a timer, please add #define USE_TIMER at the top of your script
	#define setTimer(id, timeout) #error To use a timer, please add #define USE_TIMER at the top of your script
	#define setInterval(id, timeout) #error To use a timer, please add #define USE_TIMER at the top of your script
	#define unsetTimer(id) #error To use a timer, please add #define USE_TIMER at the top of your script
	#define unsetInterval(id) #error To use a timer, please add #define USE_TIMER at the top of your script
	#define unsetTimersThatStartWith(id) #error To use a timer, please add #define USE_TIMER at the top of your script
#endif


#endif
