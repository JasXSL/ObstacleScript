#ifndef __GhostHelper_Dialog
#define __GhostHelper_Dialog
#include "./GhostHelper.lsl"

#define GhostHelper$dialog$MENU_DIFFICULTY 100

int GUESS_WRONG;

// Globals 
int DIFFICULTY;
updateGconf(){
	GCONF = (list)DIFFICULTY;
}


// Put into onDialogOpen. Handles difficulty select
#define GhostHelper$dialog$handleDialogOpen() \
	if( dialog == GhostHelper$dialog$MENU_DIFFICULTY ){ \
         \
        text = "Select a difficulty"; \
        buttons = ghostHelper_DIFFICULTIES + "<<"; \
         \
    } \
    if( dialog == MENU_MAIN ){ \
         \
        text = "\nDifficulty: "+l2s(ghostHelper_DIFFICULTIES, DIFFICULTY); \
        text += "\n"+l2s(ghostHelper$DIFFICULTY_DESCS, DIFFICULTY); \
         \
        if( ~GSETTINGS & DialogHelper$GS_GAME_STARTED ) \
            buttons = (list)"Difficulty"; \
		\
    }

// Put into onDialogButton
#define GhostHelper$dialog$handleDialogButton() \
	if( menu == MENU_MAIN ){ \
         \
        if( button == "Difficulty" ) \
            openDialog(GhostHelper$dialog$MENU_DIFFICULTY); \
         \
    } \
    else if( menu == GhostHelper$dialog$MENU_DIFFICULTY ){ \
         \
        if( button != "<<" ) \
            DIFFICULTY = llListFindList(ghostHelper_DIFFICULTIES, (list)button); \
             \
        openDialog(MENU_MAIN); \
         \
    }
	
// Put into onTextUpdate
#define GhostHelper$dialog$handleTextUpdate() \
	if( GSETTINGS & DialogHelper$GS_RECENT_GAME_END ){ \
         \
        int success = l2i(GSCORE, 0); \
        int ghost = l2i(GSCORE, 1); \
        int levelStart = l2i(GSCORE, 2); \
        int ghostEvents = l2i(GSCORE, 3); \
        int objInteractions = l2i(GSCORE, 4); \
        int plInteractions = l2i(GSCORE, 5); \
        int hunts = l2i(GSCORE, 6); \
         \
        str ghostName = l2s(GhostConst$type$names, ghost); \
         \
        str text = "Success!"; \
        if( !success ) \
            text = "Fail!"; \
         \
        text += "\nThe ghost was: "+ghostName; \
         \
         \
        int delta = llGetUnixTime()-levelStart; \
        text += "\n"+(str)(delta/60)+"m"+(str)(delta%60)+"s"; \
        text += "\n"+(str)ghostEvents+" ghost events"; \
        text += "\n"+(str)objInteractions+" object interacts"; \
        text += "\n"+(str)plInteractions+" player interacts"; \
        text += "\n"+(str)hunts+" hunts"; \
        return text; \
         \
    } \
    else if( GSETTINGS & DialogHelper$GS_GAME_STARTED && GSETTINGS & DialogHelper$GS_GAME_LOADED ){ \
		if( GUESS_WRONG ) \
			return "Incorrect ghost!\nTry again after the next hunt!"; \
        return "Use the keypad after\nfinding the ghost type!"; \
    }
	
// Put into the script event handler
#define GhostHelper$dialog$eventHandler() \
	handleEvent( "#Game", 0 ) \
	 \
		str evt = argStr(0); \
		if( evt == "END_GAME" ) \
			GSETTINGS = GSETTINGS & ~DialogHelper$GS_GAME_LOADED; \
		else if( evt == "GUESS_WRONG" ){ \
			GUESS_WRONG = argInt(1); \
			_dtxt(); \
		} \
		 \
	end
		



	




#endif
