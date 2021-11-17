#ifndef __LISTEN
#define __LISTEN


// #define USE_TIMER to include
#ifdef USE_LISTEN
	
	#ifndef COM_ADDITIONAL	// Lets you add additional keys that should be allowed to call methods
		#define COM_ADDITIONAL []
	#endif
	
	// Automatic globals
	int _CHDBG;	// Debug channel
	
	

	// Event
	#define onListen( channel, message ) \
		if( SENDER_SCRIPT IS "" AND EVENT_TYPE IS evt$LISTEN ){ \
			int channel = argInt(0); \
			str message = argStr(1);
			

	#define addListen( channel ) \
		llListen(channel, "", "", "")
		
	
	// Snippet of code that can auto handle the primary listen tunnel
	// Put this directly under begin.lsl
	#define handleListenTunnel() \
		onListen( ch, msg ) \
			 \
			if( ch == PUB_CHAN ){ \
				 \
				str o = llGetOwnerKey(SENDER_KEY); \
				if( ~llListFindList(PLAYERS+COM_ADDITIONAL, (list)o) || o == llGetOwner() ){ \
					\
					list parse = llJson2List(msg); \
					sendLinkMessage( LINK_SET, l2s(parse, 0), os$lmtype$method, l2i(parse, 1)&0xFF, llJson2List(l2s(parse, 2)), SENDER_KEY ); \
					\
				} \
			} \
			 \
		end
		
	// Put in your onStateEntry()
	#define setupListenTunnel() \
		addListen(PUB_CHAN)
		
	
	
	// Snippet of code that can auto handle the primary listen tunnel
	// Put this directly under begin.lsl
	#define handleDebug() \
		onListen( ch, msg ) \
			 \
			if( ch == _CHDBG && llGetSubString(msg, 0, 5) == "debug " ){ \
				 \
				list parse = llCSV2List(llGetSubString(msg, 6, -1)); \
				sendLinkMessage( LINK_SET, l2s(parse, 0), os$lmtype$method, l2i(parse, 1), llDeleteSubList(parse, 0, 1), "" ); \
				 \
			} \
			 \
		end
		
	// Put this in onStateEntry()
	// Suggested debug channel is 0
	#define setupDebug( chan ) \
		_CHDBG = chan; \
		llListen(_CHDBG, "", llGetOwner(), "")
		
	
		
#else
	#define onListen( chan, msg ) #error To use a listener, please add #define USE_LISTEN at the top of your script
	#define addListen( id ) #error To use a listener, please add #define USE_LISTEN at the top of your script
	#define handleListenTunnel() #error To use a listener, please add #define USE_LISTEN at the top of your script
	#define setupListenTunnel() #error To use a listener, please add #define USE_LISTEN at the top of your script
#endif


#endif
