#ifndef __DialogHelper
#define __DialogHelper
	
	
	#ifndef MAX_PLAYERS
		#define MAX_PLAYERS XMOD_MAX_PLAYERS
	#else
		#if MAX_PLAYERS > XMOD_MAX_PLAYERS
			#undef MAX_PLAYERS
			#define MAX_PLAYERS XMOD_MAX_PLAYERS
		#endif
	#endif
	
	// To use, include DialogHelper in your script #include "ObstacleScript/resources/DialogHelper.lsl"
	// call dialogHelperSetup() in onStateEntry
	// call dialogHelperHandler() anywhere in the event handler
	// Then create the following functions:
	// list onDialogOpen( int menu ) - Should return a list where the first entry is the text, and any additional entries are the buttons
	// onDialogButton( int menu, string button )
	// string onTextUpdate() - Lets you override the hover text over the game starter. Just return "" if you want to automate it
	// To open a new dialog, use openDialog( menu )
	// Custom menus need to use a positive integer
	// you can use #define MAX_PLAYERS to limit nr of players
	
	// The DialogHelper helps you track game start state
	int GSETTINGS;
	#define DialogHelper$GS_GAME_STARTED 0x1
	#define DialogHelper$GS_RECENT_GAME_END 0x2
	#define DialogHelper$GS_GAME_LOADED 0x4
	
	list GSCORE;
	
	int _dMENU;		// Tracks the menu
	int _MP;		// Menu page
	
	#define MENU_MAIN 0
	#define MENU_MAINTENANCE 1
	#define MENU_INVITE_PLAYER 2
	#define MENU_REMOVE_PLAYER 3
	
	#define openDialog( menu ) \
		_dMENU = menu; \
		_dopen(_dMENU);
		
	list onDialogOpen(){return [];}
	
	// Updates gsettings
	#define gcSet( index, val ) \
		idbSetByIndex(idbTable$GCONF, index, val)
		
	_dopen( integer menu ){

		string text;
		list buttons;
		

		list data = onDialogOpen(menu);
		text = l2s(data, 0);
		buttons = llDeleteSubList(data, 0, 0);

		
		if( menu == MENU_MAIN ){
				
			if( ~GSETTINGS & DialogHelper$GS_GAME_STARTED ){

				if( text == "" )
					text = "Main Menu";
				text += "\nJoined players: ";
				list names;
				forPlayer(t, i, pl)
					names += "secondlife:///app/agent/"+(str)pl+"/about";
				end
				text += llList2CSV(names);
				
				if( MAX_PLAYERS && MAX_PLAYERS < 100 ){
					text += "\nMax players: "+(str)MAX_PLAYERS;
				}
				
				
				buttons += (list)
					"INV. ALL" + 
					"INV. Player" +
					"Rst Players" +
					"Maintenance" +
					"Clean Up"
				;
				
				if( numPlayers() )
					buttons += (list)"REM. Player" + "START GAME";
				
			}
			else{
				
				if( text == "" )
					text = "Game in Progress";
				
				buttons += (list)"End Game";
				
			}
			
		}
		
		else if( menu == MENU_INVITE_PLAYER && text == "" )
			text = "Select player to invite";
		
		else if( menu == MENU_MAINTENANCE ){
		
			if( text == "" ){
				
				text = "Maintenance:\n";
				text += "  Assets: Re-fetches built-in assets from your HUD.\n";
				text += "  Scripts: Re-fetches scripts AND asssets from your HUD. (This will remove all players)\n";
				text += "  Players: Updates custom assets in your players huds.";
			
			}
			
			buttons += (list)
				"Assets" +
				"Scripts" + 
				"Players" +
				"Back"
			;
		
		}
		
		else if( menu == MENU_REMOVE_PLAYER ){
			
			int np = numPlayers();
			integer i = _MP*11;
			if( i >= np )
				i = _MP = 0;
				
			list players = getPlayers();
			
			for(; i < np && i < _MP*11+11; ++i ){
				
				text += "["+(str)i+"] "+llGetSubString(llGetDisplayName(l2k(players, i)), 0, 12)+"\n";
				buttons += (str)i;
			
			}
			
			if( np > 11 )
				buttons += ">>";
		
		}
		
		if( buttons == [] )
			llTextBox(llGetOwner(), text, 123123);
		else
			llDialog(llGetOwner(), text, buttons, 123123);
		
	}


	_dmsg( integer ch, string msg ){
	
		if( _dMENU == MENU_MAIN ){
			 
			if( msg == "INV. ALL" )
				Level$inviteNearby(MAX_PLAYERS);
			else if( msg == "INV. Player"){
				
				openDialog(MENU_INVITE_PLAYER);
				
			}
			else if( msg == "REM. Player"){
				
				_MP = 0;
				openDialog(MENU_REMOVE_PLAYER);
				
			}
			else if( msg == "Rst Players" )
				Level$resetPlayers();
			else if( msg == "Maintenance" ){
				openDialog(MENU_MAINTENANCE);
			}
			else if( msg == "Clean Up" ){
				Portal$killAll();
				GSETTINGS = GSETTINGS & ~DialogHelper$GS_GAME_LOADED;
			}
			else if( msg == "End Game" ){
				GSETTINGS = GSETTINGS & ~DialogHelper$GS_GAME_STARTED;
				raiseEvent(0, "END_GAME");
			}
			else if( msg == "START GAME" ){
			 
				GSETTINGS = GSETTINGS|DialogHelper$GS_GAME_STARTED;
				raiseEvent(0, "START_GAME" );
				
				if( ~GSETTINGS & DialogHelper$GS_GAME_LOADED )
					Spawner$spawnGame();
				else
					raiseEvent(0, "START_ROUND");
					
			}
		}
		else if( _dMENU == MENU_INVITE_PLAYER ){
			Level$invite(msg, MAX_PLAYERS);
		}
		else if( _dMENU == MENU_REMOVE_PLAYER ){
		
			if( msg == ">>" ){
				
				++_MP;
				openDialog(_dMENU);
				return;
				
			}
			
			integer n = (int)msg;
			Level$removePlayer( idbGetByIndex(idbTable$PLAYERS, n) );
		
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

	_dtxt(){
		
		integer i;
		string txt = onTextUpdate();
		
		if( txt == "" ){
		
			// You probably want to override this
			if( GSETTINGS & DialogHelper$GS_RECENT_GAME_END )
				txt = "Winner: "+llGetDisplayName(l2s(GSCORE, 0));
				
			else if( GSETTINGS & DialogHelper$GS_GAME_STARTED ){

				if( ~GSETTINGS & DialogHelper$GS_GAME_LOADED )
					txt += "Loading level...";
				else{
					// You probably want to override this too
					txt += "First to the finish line wins!";
				}
			}
			else{
				
				txt = "-- PLAYERS --\n";
				int np = numPlayers();
				if( np > 4 )
					txt += (str)np+" Joined\n";
				else{
					forPlayer( t, index, player )
						str name = llGetDisplayName(player);
						if( name == "" )
							name = "???";
						txt += name+"\n";
					end
				}
				
			}
			
		}
		llSetText(txt, <1,1,1>, 1);
	
	}
	
	#define dialogHelperHandler() \
		onRez( nr ) \
			llResetScript(); \
		end \
		onLevelMainMenu() \
			openDialog(MENU_MAIN); \
		end \
		onListen( ch, msg ) \
			if( ch == 123123 ){ \
				_dmsg(ch, msg); \
			} \
		end \
		onLevelPlayersChanged() \
			_dtxt(); \
		end \
		handleEvent( "#Game", 0 ) \
			string type = argStr(0); \
			if( type == "END_GAME" ){ \
				 \
				GSCORE = llDeleteSubList(METHOD_ARGS, 0, 0); \
				GSETTINGS = GSETTINGS&~DialogHelper$GS_GAME_STARTED; \
				GSETTINGS = GSETTINGS|DialogHelper$GS_RECENT_GAME_END; \
				setTimeout("RECENT", 30); \
				 \
			} \
			else if( type == "START_GAME" ){ \
				 \
				unsetTimer("RECENT"); \
				GSETTINGS = GSETTINGS|DialogHelper$GS_GAME_STARTED; \
				 \
				GSETTINGS = GSETTINGS&~DialogHelper$GS_RECENT_GAME_END; \
				 \
			} \
			_dtxt(); \
			\
		end \
		onRezzerGameLoaded() \
			 \
			GSETTINGS = GSETTINGS|DialogHelper$GS_GAME_LOADED; \
			_dtxt(); \
			raiseEvent(0, "START_ROUND"); \
			 \
		end \
		handleTimer( "RECENT" ) \
		 \
			GSETTINGS = GSETTINGS & ~DialogHelper$GS_RECENT_GAME_END; \
			_dtxt(); \
			 \
		end \

		
	
	#define dialogHelperSetup() \
		llListen(123123, "", llGetOwner(), ""); \
		_dtxt();
		
		
	

#endif
