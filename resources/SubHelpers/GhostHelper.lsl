/* Note: When using this in #Game, include GameHelper first */
#ifndef __GHOSTHELPER
#define __GHOSTHELPER

// ToolSet.lsh tool types. Commented is the data, followed by call to either ToolSet$trigger or GhostToolMethod$trigger
#define ToolsetConst$types$ghost$owometer 1			// (bool)on
#define ToolsetConst$types$ghost$flashlight 2		// (bool)on
#define ToolsetConst$types$ghost$hots 3				// 0
#define ToolsetConst$types$ghost$ecchisketch 4		// (int)drawing
#define ToolsetConst$types$ghost$spiritbox 5		// (bool)on
#define ToolsetConst$types$ghost$camera 6			// (int)pics_taken
#define ToolsetConst$types$ghost$salt 7				// (int)charges_used
#define ToolsetConst$types$ghost$candle 8			// NOT USED IN GAME
#define ToolsetConst$types$ghost$parabolic 9		// (bool)on | ToolSet: pos
#define ToolsetConst$types$ghost$motionDetector 10	// 0 - NOTE: Can only be placed on linksets where the root prim has the word LEVEL somewhere in the description
#define ToolsetConst$types$ghost$glowstick 11		// (int)utime_turned_on
#define ToolsetConst$types$ghost$pills 12			// 0
#define ToolsetConst$types$ghost$thermometer 13		// (bool)on
#define ToolsetConst$types$ghost$weegieboard 14		// 0
#define ToolsetConst$types$ghost$vape 15			// 0
#define ToolsetConst$types$ghost$hornybat 16		// 0
#define ToolsetConst$types$ghost$saltpile 17		// (bool)stepped
#define ToolsetConst$types$ghost$videoCamera 18		// void


#define ToolSetConst$affix$weakFlashlights 1
#define ToolSetConst$affix$fewerHidingSpots 2
#define ToolSetConst$affix$noVapes 3
#define ToolSetConst$affix$noHornyBats 4
#define ToolSetConst$affix$noRadios 5
#define ToolSetConst$affix$powerOutage 6
#define ToolSetConst$affix$noPills 7
#define ToolSetConst$affix$noEvidenceUntilSalted 8

#define ToolSetConst$affix$noArousalMonitor 1		// Arousal monitor shows ???
#define ToolSetConst$affix$ghostInvisible 2			// Ghost is permanently invisible
#define ToolSetConst$affix$ghostSpeed 3				// Ghost speed increased by 20%
#define ToolSetConst$affix$noThermometer 4			// Thermometer missing
#define ToolSetConst$affix$ghostRoomChange 5		// Ghost has a 50% chance when roaming to make the new room their home, starting every 420 sec after a room change.
#define ToolSetConst$affix$reqMotionSensor 6		// Ghost won't touch things until motion sensed
#define ToolSetConst$affix$noDuplicates 7			// Bring only one of each item
#define ToolSetConst$affix$vibrator 8



#define getWeakAffix() (AFFIXES&0xF)
#define getStrongAffix() ((AFFIXES>>4)&0xF)
#define hasWeakAffix(affix) (getWeakAffix()==affix)
#define hasStrongAffix(affix) (getStrongAffix()==affix)

#define GhostHelper$CAM_MAX_PICS 5
#define GhostHelper$SALT_MAX_CHARGES 3

#define GhostHelper$flashlightSettings (list)PRIM_POINT_LIGHT + on + <1.000, 0.928, 0.710> + 1 + (4-((AFFIXES&0xF)==ToolSetConst$affix$weakFlashlights)*2) + 1
#define GhostHelper$ecchisketchTexture "9b2f4cf3-2796-4a6a-e5f4-0b93693c86aa"


#define GhostHelper$getGlowstickSettings( utimeLit ) _ghGGS(utimeLit)
list _ghGGS( integer utimeLit ){
	
	float perc = ((300.0-(float)(llGetUnixTime()-utimeLit))/300.0);
	if( perc < 0 )
		perc = 0;
		
	return (list)PRIM_POINT_LIGHT + TRUE + <0.665, 0.181, 1.000> + 1.0 + (2.5+2.5*perc) + 1.0 + PRIM_FULLBRIGHT + ALL_SIDES + TRUE + PRIM_GLOW + ALL_SIDES + (0.1+0.4*perc);

}


// Tools that don't require a remoteloaded script
// Aka all tools that can't be used from both hand and placed
#define LevelCustomType$GHOSTHELPER "oToolset"				// Generic type for traps like the lasher
		#define LevelCustomEvt$GHOSTHELPER$pills 1			// 
	
#define onLevelCustomGhosthelperPills( toolsetuuid, worldID ) \
	if( isEventLevelCustom() AND argStr(1) == LevelCustomType$GHOSTHELPER AND argInt(2) == LevelCustomEvt$GHOSTHELPER$pills ){ \
		key toolsetuuid = argKey(0); \
		key worldID = argKey(3);







#define ghostHelper$dialog$globals \


#define ghostHelper$DIFFICULTY_DESCS [ \
    "- Players break free from bondage devices after 30 seconds\n"+ \
    "- Pills clear 50% arousal" \
    , \
    "- Pills clear 35% arousal\n"+ \
    "- Slightly longer hunts\n"+ \
    "- Less active ghosts\n"+ \
    "- Weak affix" \
    , \
    "- Pills clear 25% arousal\n"+ \
    "- Longer hunts\n"+ \
    "- Doors start open\n"+ \
    "- Much less active ghosts\n"+ \
    "- Weak and strong affix" \
	, \
    "- Only 2 evidence types\n"+ \
    "- Pills clear 20% arousal\n"+ \
    "- Longest hunts\n"+ \
    "- Doors start open\n"+ \
    "- Much less active ghosts\n"+ \
    "- Weak and strong affix" \
]

list ghostHelper_DIFFICULTIES = [
    "Virgin",
    "Amateur",
    "Professional",
	"Hardcore"
];



	

#endif

