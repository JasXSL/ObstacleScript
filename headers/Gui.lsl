#ifndef __Gui
#define __Gui

#define Gui$BAR_BORDER 0
#define Gui$BAR_BAR_BG 3
#define Gui$BAR_BAR_MAIN 2
#define Gui$BAR_BAR_OVERLAY 1
#define Gui$BAR_ICON_FWD 4
#define Gui$BAR_ICON_BACK 5
#define Gui$BAR_BG_FWD 6
#define Gui$BAR_BG_BACK 7

#define Gui$BAR_COLOR_BG <0,0,0>
#define Gui$BAR_ALPHA_BG 0.5

#define Gui$BAR_TEXTURE_MAIN "c0f942a2-46c3-2489-33ef-f072a6cb4e0d"

#define Gui$ICON_BORDER 0
#define Gui$ICON_BUTTON_BG 3
#define Gui$ICON_BUTTON_MAIN 2
#define Gui$ICON_BUTTON_OVERLAY 1
#define Gui$ICON_BG_FWD 4
#define Gui$ICON_ICON_BACK 5



#define GuiMethod$createBar 1 			// (str)label, (vec)color, (vec)border - Creates a new default bar
#define GuiMethod$removeBars 2			// (spread)label1, label2... - Use send an empty list of labels to remove ALL
#define GuiMethod$setBarPerc 3			// (str)label, (float)perc - Sets the bar to a percentage
#define GuiMethod$setBarTexture 4		// (str)label, (int)face, (key)texture - Sets a texture on the bar. Use the constants above. Setting "" as a texture hides the face

#define GuiMethod$createButton 5		// (str)label, (key)texture
#define GuiMethod$removeButtons 6		// (spread)label1, label2...
#define GuiMethod$setButtonCooldown 7	// (str)label, (float)cooldown

#define GuiMethod$startCountdown 8		// 





// Todo
#define Gui$createBar( target, label, color, border ) \
	runMethod( target, "Gui", GuiMethod$createBar, label + color + border )

#define Gui$removeBars( target, bars ) \
	runMethod( target, "Gui", GuiMethod$removeBars, bars )

#define Gui$setBarPerc( target, bar, perc ) \
	runMethod( target, "Gui", GuiMethod$setBarPerc, bar + perc )


#define Gui$setBarTexture( target, bar, face, texture ) \
	runMethod( target, "Gui", GuiMethod$setBarTexture, bar + face + texture )

#define Gui$createButton( target, label, texture ) \
	runMethod( target, "Gui", GuiMethod$createButton, label + texture )

#define Gui$setButtonCooldown( target, label, cooldown ) \
	runMethod( target, "Gui", GuiMethod$setButtonCooldown, label + cooldown )

#define Gui$startCountdown( target ) \
	runMethod( target, "Gui", GuiMethod$startCountdown, [] )




#endif
