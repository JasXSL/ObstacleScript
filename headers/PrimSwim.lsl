#ifndef __PrimSwim
#define __PrimSwim

/*

	
	
	Usage:
	Create a box (PrimSwim only works with boxes)
	Name the box exactly: WATER
	Make the box phantom.
	You should now be able to swim when entering it.
	
	Helper functions:
	checkForceStop() Lets you return FALSE if something is else in the HUD is preventing the user from moving under water
	
*/



#define PrimSwimMethod$airpockets 1				// each argument is a uuid of an air pocket
#define PrimSwimMethod$swimSpeedMultiplier 2		// (float)speed - Allows you to swim faster or slower. 1 is default, higher is faster.
#define PrimSwimMethod$particleHelper 3			// (key)helper - Sets the key of the particle helper

// Use jas Interact instead of buttons to climb out. Makes it play nicer with jas Interact
#define PrimSwimCfg$useJasInteract

// Includes
#ifndef PrimSwimCfg$USE_WINDLIGHT
	#define PrimSwimCfg$USE_WINDLIGHT 1		// Use RLV windlight (requires jas RLV)
#endif

// Timer tick speed
#ifndef PrimSwimCfg$maxSpeed
	// While you are close to water
	#define PrimSwimCfg$maxSpeed .1
#endif
#ifndef PrimSwimCfg$minSpeed
	// While you are not close to water
	#define PrimSwimCfg$minSpeed 5
#endif

// Sound defaults
#ifndef PrimSwimCfg$splashBig
	#define PrimSwimCfg$splashBig "cb50db39-8fb7-acd2-21e7-ef37cc2e0030"
#endif 
#ifndef PrimSwimCfg$splashMed
	#define PrimSwimCfg$splashMed "58bab621-cbec-175a-2b55-fc2810e96d7c"
#endif
#ifndef PrimSwimCfg$splashSmall
	#define PrimSwimCfg$splashSmall "0eccd45f-8a31-1263-c4c2-cbe80a27696b"
#endif

#ifndef PrimSwimCfg$soundExit
	#define PrimSwimCfg$soundExit "2ade5961-3b75-f8cf-ca78-7f64cd804572"
#endif
#ifndef PrimSwimCfg$soundStroke
	#define PrimSwimCfg$soundStroke "975f7f5d-320c-94a7-e31f-1cc5547081e8"
#endif
#ifndef PrimSwimCfg$soundSubmerge
	#define PrimSwimCfg$soundSubmerge "c72c63dc-7ca2-fde7-41d8-6f63b3360820"
#endif

#ifndef PrimSwimCfg$soundFootstepsShallow
	#define PrimSwimCfg$soundFootstepsShallow ["d2a62376-8569-274d-3378-b33028915845", "88179970-4fb8-9fe8-c1c0-c6c8a112ede8", "200548aa-c2c7-c32c-77fc-6ad9acef65a9"]
#endif
#ifndef PrimSwimCfg$soundFootstepsMed
	#define PrimSwimCfg$soundFootstepsMed ["6ff37e21-b76e-45c5-bb17-0f40af500b50", "d7e3be48-bdeb-6e7e-644e-6cfaee33effc", "d69f45ec-346b-bd5c-2b62-0de4fc60a5c0", "53bbd8c6-4e49-88e0-006c-7ce6987db83c"]
#endif
#ifndef PrimSwimCfg$soundFootstepsDeep
	#define PrimSwimCfg$soundFootstepsDeep ["21f9d648-dab6-e8aa-fc96-20f516061852", "0c21ae4c-f542-4e44-baa5-7f3d9b9600e3", "3b8f13f2-727b-e80c-7d25-28c9601bf651", "a5048f46-2b7f-8ba4-db08-e962e6c0f9c8"]
#endif


// Anim defaults
#ifndef PrimSwimCfg$animIdle
	#define PrimSwimCfg$animIdle "swim_idle"
#endif 
#ifndef PrimSwimCfg$animActive
	#define PrimSwimCfg$animActive "swim"
#endif 


#ifndef PrimSwimCfg$pnAirpocket
	#define PrimSwimCfg$pnAirpocket "AIR"
#endif
#ifndef PrimSwimCfg$pnWater
	#define PrimSwimCfg$pnWater "WATER"
#endif


#define PrimSwim$airpockets(airpockets) runMethod((string)LINK_ROOT, "PrimSwim", PrimSwimMethod$airpockets, airpockets)
#define PrimSwim$swimSpeedMultiplier(targ, multiplier) runMethod(targ, "PrimSwim", PrimSwimMethod$swimSpeedMultiplier, multiplier)
#define PrimSwim$particleHelper(helper) runMethod((string)LINK_THIS, "PrimSwim", PrimSwimMethod$particleHelper, helper);

// Event definitions
#define PrimSwimEvt$waterEntered 1		// (int)speed, (vec)position - Speed is a value between 0 (slowly entered water) and 2 (very rapidly)
#define PrimSwimEvt$waterExited 2
#define PrimSwimEvt$feetWet 3			// [(bool)wet] - Feet are now wet or not


// Event macros
#define onPrimSwimWaterEntered( speed, position ) \
	if( SENDER_SCRIPT IS "PrimSwim" AND EVENT_TYPE IS PrimSwimEvt$waterEntered ){ \
		int speed = argInt(0); \
		vector position = (vector)argStr(1); 

#define onPrimSwimWaterExited() \
	if( SENDER_SCRIPT IS "PrimSwim" AND EVENT_TYPE IS PrimSwimEvt$waterExited ){

#define onPrimSwimFeetWet() \
	if( SENDER_SCRIPT IS "PrimSwim" AND EVENT_TYPE IS PrimSwimEvt$feetWet ){





#endif
