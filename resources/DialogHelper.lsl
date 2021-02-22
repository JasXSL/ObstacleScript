#ifndef __DialogHelper
#define __DialogHelper

	// To use, include DialogHelper in your script #include "ObstacleScript/resources/DialogHelper.lsl"
	// call dialogHelperSetup() in onStateEntry
	// call dialogHelperHandler() anywhere in the event handler
	// Then create the following functions:
	// list onDialogOpen( menu ) - Should return a list where the first entry is the text, and any additional entries are the buttons
	// onDialogButton( menu, button )
	// To open a new dialog, use openDialog( menu )
	// Custom menus need to use a positive integer
	
	// The DialogHelper helps you track game start state
	int GSETTINGS;
	#define GS_GAME_STARTED 0x1
	#define GS_RECENT_GAME_END 0x2
	#define GS_GAME_LOADED 0x4

	int _dMENU;		// Tracks the menu
	
	#define MENU_MAIN 0
	#define MENU_MAINTENANCE 1
	#define MENU_INVITE_PLAYER 2
	
	#define openDialog( menu ) \
		_dMENU = menu; \
		_dopen(_dMENU);
		
	list onDialogOpen(){return [];}

	_dopen( integer menu ){

		string text;
		list buttons;
		

		list data = onDialogOpen(menu);
		text = l2s(data, 0);
		buttons = llDeleteSubList(data, 0, 0);

		
		if( menu == MENU_MAIN ){
				
			if( ~GSETTINGS & GS_GAME_STARTED ){

				if( text == "" )
					text = "Main Menu";
				
				buttons += (list)
					"INV. ALL" + 
					"INV. Player" + 
					"Rem Players" +
					"Mode" +
					"Maintenance" +
					"Clean Up" +
					"START GAME"
				;
				
			}
			else{
				
				if( text == "" )
					text = "Game in Progress";
				
				buttons += (list)"End Game";
				
			}
			
		}
		
		else if( menu == MENU_MAINTENANCE ){
		
			if( text == "" ){
				
				text = "Maintenance:\n";
				text = "  Assets: Re-fetches built-in assets from your HUD.\n";
				text = "  Scripts: Re-fetches scripts AND asssets from your HUD. (This will remove all players)\n";
				text = "  Players: Updates custom assets in your players huds.";
			
			}
			
			buttons += (list)
				"Assets" +
				"Scripts" + 
				"Players" +
				"Back"
			;
		
		}
		
		if( buttons == [] )
			llTextBox(llGetOwner(), text, 123123);
		else
			llDialog(llGetOwner(), text, buttons, 123123);
		
	}


	_dmsg( integer ch, string msg ){
	
		if( _dMENU == MENU_MAIN ){
			 
			if( msg == "INV. ALL" )
				Level$inviteNearby();
			else if( msg == "INV. Player"){
				openDialog(MENU_INVITE_PLAYER);
			}
			else if( msg == "Rem Players" )
				Level$resetPlayers();
			else if( msg == "Maintenance" ){
				openDialog(MENU_MAINTENANCE);
			}
			else if( msg == "Clean Up" ){
				Portal$killAll();
				GSETTINGS = GSETTINGS & ~GS_GAME_LOADED;
			}
			else if( msg == "End Game" ){
				GSETTINGS = GSETTINGS & ~GS_GAME_STARTED;
				raiseEvent(0, "END_GAME");
			}
			else if( msg == "START GAME" ){
			 
				GSETTINGS = GSETTINGS|GS_GAME_STARTED;
				raiseEvent(0, "START_GAME" ); // Todo: Might wanna send along some ruleset flags when starting the game
				
				if( ~GSETTINGS & GS_GAME_LOADED )
					Spawner$spawnGame();
				else
					raiseEvent(0, "START_ROUND");
					
			}
		}
		else if( _dMENU == MENU_INVITE_PLAYER ){
			Level$invite(msg);
		}
		else if( _dMENU == MENU_MAINTENANCE ){
			
			if( msg == "Back" )
			   _dMENU = MENU_MAIN;
			else if( msg == "Players" )
				Level$updateAllHudAssets( LINK_THIS );
			else if( msg == "Assets" )
				Spawner$fetchFromHud( LINK_THIS );
			else if( msg == "Scripts" ){
				Level$updateThis();
				llSleep(1);
			}
				
			
			openDialog(_dMENU);
			
		}
		
		onDialogButton(_dMENU, msg);
	}

	
	
	#define dialogHelperHandler() \
		onLevelMainMenu() \
			openDialog(MENU_MAIN); \
		end \
		onListen( ch, msg ) \
			if( ch == 123123 ){ \
				_dmsg(ch, msg); \
			} \
		end \
		
	
	#define dialogHelperSetup() \
		llListen(123123, "", llGetOwner(), "")

		
	

#endif
